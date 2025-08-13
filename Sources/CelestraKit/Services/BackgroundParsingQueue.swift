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

/// Configuration for background parsing queue behavior
public struct BackgroundParsingConfig: Sendable {
  public let maxConcurrentOperations: Int
  public let highPriorityLimit: Int
  public let normalPriorityLimit: Int
  public let lowPriorityLimit: Int
  public let retryConfig: RetryConfig
  public let circuitBreakerConfig: CircuitBreakerConfig
  public let batchSize: Int
  public let batchTimeout: TimeInterval
  
  public init(
    maxConcurrentOperations: Int = 6,
    highPriorityLimit: Int = 3,
    normalPriorityLimit: Int = 2,
    lowPriorityLimit: Int = 1,
    retryConfig: RetryConfig = RetryConfig(),
    circuitBreakerConfig: CircuitBreakerConfig = CircuitBreakerConfig(),
    batchSize: Int = 5,
    batchTimeout: TimeInterval = 30.0
  ) {
    self.maxConcurrentOperations = maxConcurrentOperations
    self.highPriorityLimit = highPriorityLimit
    self.normalPriorityLimit = normalPriorityLimit
    self.lowPriorityLimit = lowPriorityLimit
    self.retryConfig = retryConfig
    self.circuitBreakerConfig = circuitBreakerConfig
    self.batchSize = batchSize
    self.batchTimeout = batchTimeout
  }
}

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
      .low: 0
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
    if pendingTasks.contains(where: { $0.url == task.url }) ||
       runningTasks.contains(where: { $0.url == task.url }) {
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
  
  // MARK: - Private Processing Logic
  
  private func startProcessing() async {
    guard !isProcessing, !isPaused else { return }
    
    // Check memory pressure before starting
    if memoryMonitor.shouldPauseOperations() {
      return
    }
    
    isProcessing = true
    isActive = true
    
    while !pendingTasks.isEmpty && !isPaused && !memoryMonitor.shouldPauseOperations() {
      await processNextBatch()
      updateStatistics()
      
      // Brief pause to allow UI updates and prevent overwhelming the system
      try? await Task.sleep(for: .milliseconds(100))
    }
    
    isProcessing = false
    isActive = runningTasks.count > 0
    updateStatistics()
  }
  
  private func processNextBatch() async {
    let availableSlots = availableConcurrencySlots()
    guard availableSlots > 0 else {
      // Wait for running tasks to complete
      try? await Task.sleep(for: .milliseconds(500))
      return
    }
    
    let tasksToRun = selectTasksForExecution(limit: availableSlots)
    
    await withTaskGroup(of: Void.self) { group in
      for task in tasksToRun {
        group.addTask {
          await self.executeTask(task)
        }
      }
    }
  }
  
  private func selectTasksForExecution(limit: Int) -> [ParsingTask] {
    var selected: [ParsingTask] = []
    var remaining = limit
    
    // Process by priority, respecting per-priority limits
    for priority in [ParsingPriority.high, .normal, .low] {
      let priorityLimit = priorityLimit(for: priority)
      let currentRunning = runningTasksByPriority[priority] ?? 0
      let availableForPriority = min(priorityLimit - currentRunning, remaining)
      
      guard availableForPriority > 0 else { continue }
      
      let priorityTasks = pendingTasks.prefix { task in
        task.priority == priority &&
        (shouldAllowRequest(for: task.url) || task.isReadyForRetry())
      }
      
      let tasksToAdd = Array(priorityTasks.prefix(availableForPriority))
      selected.append(contentsOf: tasksToAdd)
      remaining -= tasksToAdd.count
      
      // Remove selected tasks from pending
      pendingTasks.removeAll { task in
        tasksToAdd.contains { $0.id == task.id }
      }
      
      if remaining <= 0 { break }
    }
    
    return selected
  }
  
  private func executeTask(_ task: ParsingTask) async {
    runningTasks.insert(task)
    runningTasksByPriority[task.priority, default: 0] += 1
    task.updateState(.running)
    
    telemetry.recordEvent(type: .taskStarted, properties: ["url": task.url.absoluteString])
    emitProgress(for: task, phase: .fetching, progress: 0.1)
    
    let startTime = Date()
    var result: ParsingResult
    
    do {
      let parsedFeed = try await parser.parse(url: task.url)
      let metrics = ParsingMetrics.success(
        startTime: startTime,
        feed: parsedFeed,
        bytesProcessed: 0  // TODO: Track actual bytes
      )
      
      result = .success(parsedFeed, metrics: metrics)
      task.updateState(.completed(result))
      circuitBreakerManager.recordSuccess(for: task.url)
      
      emitProgress(for: task, phase: .completed, progress: 1.0)
      
    } catch {
      let metrics = ParsingMetrics.failure(startTime: startTime)
      result = .failure(error, metrics: metrics)
      
      circuitBreakerManager.recordFailure(for: task.url)
      
      // Handle retry logic
      if task.shouldRetry {
        task.recordFailure(error)
        telemetry.recordEvent(type: .taskRetried, properties: [
          "url": task.url.absoluteString,
          "retry_count": String(task.retryCount)
        ])
        // Re-queue for retry
        await MainActor.run {
          pendingTasks.append(task)
          pendingTasks.sort()
        }
        emitProgress(for: task, phase: .queued, progress: 0.0, message: "Retrying...")
      } else {
        task.updateState(.failed(error, retryCount: task.retryCount))
        emitProgress(for: task, phase: .failed, progress: 0.0)
      }
    }
    
    // Record telemetry for task completion
    telemetry.recordTaskCompletion(url: task.url, result: result, retryCount: task.retryCount)
    
    // Emit result
    resultSubject.continuation.yield(result)
    
    // Clean up
    runningTasks.remove(task)
    runningTasksByPriority[task.priority, default: 0] -= 1
    completedTasks.append(task)
    
    // Keep completed tasks list manageable
    if completedTasks.count > 100 {
      completedTasks.removeFirst(50)
    }
  }
  
  // MARK: - Utility Methods
  
  private func availableConcurrencySlots() -> Int {
    let baseLimit = config.maxConcurrentOperations
    let memoryAdjustedLimit = memoryMonitor.recommendedTaskLimit(defaultLimit: baseLimit)
    return memoryAdjustedLimit - runningTasks.count
  }
  
  private func priorityLimit(for priority: ParsingPriority) -> Int {
    switch priority {
    case .high: return config.highPriorityLimit
    case .normal: return config.normalPriorityLimit
    case .low: return config.lowPriorityLimit
    }
  }
  
  private func shouldAllowRequest(for url: URL) -> Bool {
    circuitBreakerManager.circuitBreaker(for: url).shouldAllowRequest()
  }
  
  private func emitProgress(
    for task: ParsingTask,
    phase: ParsingPhase,
    progress: Double,
    message: String? = nil
  ) {
    let progressUpdate = ParsingProgress(
      taskId: task.id,
      url: task.url,
      phase: phase,
      progress: progress,
      message: message
    )
    progressSubject.continuation.yield(progressUpdate)
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

// MARK: - Queue Statistics

public struct QueueStatistics: Sendable {
  public let pendingCount: Int
  public let runningCount: Int
  public let completedCount: Int
  public let failedCount: Int
  public let circuitOpenCount: Int
  public let timestamp: Date
  
  public init(
    pendingCount: Int = 0,
    runningCount: Int = 0,
    completedCount: Int = 0,
    failedCount: Int = 0,
    circuitOpenCount: Int = 0,
    timestamp: Date = Date()
  ) {
    self.pendingCount = pendingCount
    self.runningCount = runningCount
    self.completedCount = completedCount
    self.failedCount = failedCount
    self.circuitOpenCount = circuitOpenCount
    self.timestamp = timestamp
  }
  
  public var totalProcessed: Int {
    completedCount + failedCount
  }
  
  public var successRate: Double {
    let total = totalProcessed
    guard total > 0 else { return 0.0 }
    return Double(completedCount) / Double(total)
  }
}