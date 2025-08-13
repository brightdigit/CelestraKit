// BackgroundParsingProcessor.swift
// Celestra
//
// Created by Claude on 13/8/2025.
//

public import Foundation

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

/// Core processing logic for background parsing queue
@MainActor
extension BackgroundParsingQueue {
  // MARK: - Processing Logic

  func startProcessing() async {
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
    isActive = !runningTasks.isEmpty
    updateStatistics()
  }

  func processNextBatch() async {
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

  func selectTasksForExecution(limit: Int) -> [ParsingTask] {
    var selected: [ParsingTask] = []
    var remaining = limit

    // Process by priority, respecting per-priority limits
    for priority in [ParsingPriority.high, .normal, .low] {
      let priorityLimit = priorityLimit(for: priority)
      let currentRunning = runningTasksByPriority[priority] ?? 0
      let availableForPriority = min(priorityLimit - currentRunning, remaining)

      guard availableForPriority > 0 else { continue }

      let priorityTasks = pendingTasks.prefix { task in
        task.priority == priority && (shouldAllowRequest(for: task.url) || task.isReadyForRetry())
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

  func executeTask(_ task: ParsingTask) async {
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
        telemetry.recordEvent(
          type: .taskRetried,
          properties: [
            "url": task.url.absoluteString,
            "retry_count": String(task.retryCount),
          ])
        // Re-queue for retry
        await MainActor.run {
          pendingTasks.append(task)
          pendingTasks.sort()
        }
        emitProgress(for: task, phase: .queued, progress: 0.0)
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

  func availableConcurrencySlots() -> Int {
    let baseLimit = config.maxConcurrentOperations
    let memoryAdjustedLimit = memoryMonitor.recommendedTaskLimit(defaultLimit: baseLimit)
    return memoryAdjustedLimit - runningTasks.count
  }

  func priorityLimit(for priority: ParsingPriority) -> Int {
    switch priority {
    case .high: return config.highPriorityLimit
    case .normal: return config.normalPriorityLimit
    case .low: return config.lowPriorityLimit
    }
  }

  func shouldAllowRequest(for url: URL) -> Bool {
    circuitBreakerManager.circuitBreaker(for: url).shouldAllowRequest()
  }

  func emitProgress(
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
      message: message,
      timestamp: Date()
    )
    progressSubject.continuation.yield(progressUpdate)
  }
}
