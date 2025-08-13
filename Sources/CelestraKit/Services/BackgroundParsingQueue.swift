//
//  BackgroundParsingQueue.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

public import Foundation

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

/// Background parsing queue with priority scheduling, retry logic, and circuit breaker protection
@MainActor
public final class BackgroundParsingQueue: ObservableObject {
  private let parser: SyndiKitParser
  private let config: BackgroundParsingConfig
  private let circuitBreakerManager: CircuitBreakerManager
  private let memoryMonitor: MemoryPressureMonitor
  private let telemetry: ParsingTelemetry

  // Task management
  private var pendingTasks: [ParsingTask] = []
  private var runningTasks: Set<ParsingTask> = []
  private var completedTasks: [ParsingTask] = []

  // Concurrency management
  private var runningTasksByPriority: [ParsingPriority: Int] = [:]
  private var isProcessing = false
  private var isPaused = false

  // Progress and result streams
  private let progressSubject = AsyncStream<ParsingProgress>.makeStream()
  private let resultSubject = AsyncStream<ParsingResult>.makeStream()
  private let batchResultSubject = AsyncStream<BatchParsingResult>.makeStream()

  public var progressStream: AsyncStream<ParsingProgress> { progressSubject.stream }
  public var resultStream: AsyncStream<ParsingResult> { resultSubject.stream }
  public var batchResultStream: AsyncStream<BatchParsingResult> { batchResultSubject.stream }

  @Published public private(set) var queueStats = QueueStatistics()
  @Published public private(set) var isActive = false

  // Expose telemetry for external access
  public var parsingTelemetry: ParsingTelemetry { telemetry }

  public init(
    parser: SyndiKitParser,
    config: BackgroundParsingConfig = BackgroundParsingConfig()
  ) {
    self.parser = parser
    self.config = config
    self.circuitBreakerManager = CircuitBreakerManager(config: config.circuitBreakerConfig)
    self.memoryMonitor = MemoryPressureMonitor()
    self.telemetry = ParsingTelemetry()

    // Initialize priority counters
    runningTasksByPriority = [
      .high: 0,
      .normal: 0,
      .low: 0,
    ]

    setupAppLifecycleHandling()
    memoryMonitor.startMonitoring()
  }

  // MARK: - Task Management

  /// Add a parsing task to the queue
  public func enqueue(
    url: URL,
    priority: ParsingPriority = .normal,
    userInitiated: Bool = false
  ) {
    let task = ParsingTask(
      url: url,
      priority: priority,
      retryConfig: config.retryConfig,
      userInitiated: userInitiated
    )

    enqueue(task: task)
  }

  /// Add a parsing task object to the queue
  public func enqueue(task: ParsingTask) {
    // Check if URL is circuit-broken
    if circuitBreakerManager.isBlocked(task.url) {
      task.updateState(.circuitOpen)
      updateStatistics()
      return
    }

    // Check for duplicate tasks
    if pendingTasks.contains(where: { $0.url == task.url }) || runningTasks.contains(where: { $0.url == task.url }) {
      return  // Already queued or running
    }

    pendingTasks.append(task)
    pendingTasks.sort()  // Maintain priority order

    emitProgress(for: task, phase: .queued, progress: 0.0)
    telemetry.recordEvent(type: .taskQueued, properties: ["url": task.url.absoluteString])
    updateStatistics()

    // Start processing if not already running
    if !isProcessing {
      Task { await startProcessing() }
    }
  }

  /// Enqueue multiple URLs with optional batching
  public func enqueueBatch(
    urls: [URL],
    priority: ParsingPriority = .normal,
    userInitiated: Bool = false
  ) {
    let tasks = urls.map { url in
      ParsingTask(
        url: url,
        priority: priority,
        retryConfig: config.retryConfig,
        userInitiated: userInitiated
      )
    }

    for task in tasks {
      enqueue(task: task)
    }
  }

  /// Remove task from queue (if not running)
  public func cancel(url: URL) {
    if let index = pendingTasks.firstIndex(where: { $0.url == url }) {
      let task = pendingTasks.remove(at: index)
      task.updateState(.cancelled)
      emitProgress(for: task, phase: .cancelled, progress: 0.0)
      updateStatistics()
    }
  }

  /// Clear all pending tasks
  public func clearQueue() {
    for task in pendingTasks {
      task.updateState(.cancelled)
      emitProgress(for: task, phase: .cancelled, progress: 0.0)
    }
    pendingTasks.removeAll()
    updateStatistics()
  }

  // MARK: - Queue Control

  /// Pause queue processing
  public func pause() {
    isPaused = true
    isActive = false
    telemetry.recordEvent(type: .queuePaused)
  }

  /// Resume queue processing
  public func resume() {
    isPaused = false
    telemetry.recordEvent(type: .queueResumed)
    if !pendingTasks.isEmpty && !isProcessing {
      Task { await startProcessing() }
    }
  }

  // MARK: - App Lifecycle Handling

  private func setupAppLifecycleHandling() {
    #if canImport(UIKit)
      // iOS/tvOS notifications
      NotificationCenter.default.addObserver(
        forName: UIApplication.willResignActiveNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.handleAppWillResignActive()
      }

      NotificationCenter.default.addObserver(
        forName: UIApplication.didBecomeActiveNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.handleAppDidBecomeActive()
      }

      NotificationCenter.default.addObserver(
        forName: UIApplication.didReceiveMemoryWarningNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.handleMemoryWarning()
      }

    #elseif canImport(AppKit)
      // macOS notifications
      NotificationCenter.default.addObserver(
        forName: NSApplication.willResignActiveNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.handleAppWillResignActive()
      }

      NotificationCenter.default.addObserver(
        forName: NSApplication.didBecomeActiveNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.handleAppDidBecomeActive()
      }
    #endif
  }

  private func handleAppWillResignActive() {
    // Pause processing when app goes to background
    pause()
  }

  private func handleAppDidBecomeActive() {
    // Resume processing when app becomes active
    resume()
  }

  private func handleMemoryWarning() {
    // Force memory cleanup and reduce concurrent operations
    memoryMonitor.requestMemoryCleanup()

    // Temporarily reduce queue limits
    if runningTasks.count > 2 {
      // Note: We can't cancel running tasks easily, but we can prevent new ones
      pause()

      // Resume after a brief delay to allow memory cleanup
      Task {
        try? await Task.sleep(for: .seconds(2))
        resume()
      }
    }
  }

  private func updateStatistics() {
    queueStats = QueueStatistics(
      pendingCount: pendingTasks.count,
      runningCount: runningTasks.count,
      completedCount: completedTasks.count,
      failedCount: completedTasks.filter { task in
        if case .failed = task.state { return true }
        return false
      }.count,
      circuitOpenCount: circuitBreakerManager.blockedUrls().count
    )
  }
}
