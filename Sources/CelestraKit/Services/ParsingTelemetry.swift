//
//  ParsingTelemetry.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

public import Foundation

/// Telemetry event types for parsing operations
public enum TelemetryEventType: String, Sendable, CaseIterable {
  case taskQueued = "task_queued"
  case taskStarted = "task_started"
  case taskCompleted = "task_completed"
  case taskFailed = "task_failed"
  case taskRetried = "task_retried"
  case circuitBreakerOpened = "circuit_breaker_opened"
  case circuitBreakerClosed = "circuit_breaker_closed"
  case memoryPressureWarning = "memory_pressure_warning"
  case memoryPressureCritical = "memory_pressure_critical"
  case batchCompleted = "batch_completed"
  case queuePaused = "queue_paused"
  case queueResumed = "queue_resumed"
}

/// Telemetry data point
public struct TelemetryEvent: Sendable {
  public let type: TelemetryEventType
  public let timestamp: Date
  public let properties: [String: String]
  public let metrics: [String: Double]

  public init(
    type: TelemetryEventType,
    timestamp: Date = Date(),
    properties: [String: String] = [:],
    metrics: [String: Double] = [:]
  ) {
    self.type = type
    self.timestamp = timestamp
    self.properties = properties
    self.metrics = metrics
  }
}

/// Performance metrics aggregator
public struct PerformanceMetrics: Sendable {
  public let totalTasks: Int
  public let successfulTasks: Int
  public let failedTasks: Int
  public let averageParsingTime: TimeInterval
  public let averageBytesPerSecond: Double
  public let cacheHitRate: Double
  public let circuitBreakerTrips: Int
  public let memoryWarnings: Int

  public var successRate: Double {
    guard totalTasks > 0 else { return 0.0 }
    return Double(successfulTasks) / Double(totalTasks)
  }

  public var failureRate: Double {
    guard totalTasks > 0 else { return 0.0 }
    return Double(failedTasks) / Double(totalTasks)
  }

  public init(
    totalTasks: Int = 0,
    successfulTasks: Int = 0,
    failedTasks: Int = 0,
    averageParsingTime: TimeInterval = 0,
    averageBytesPerSecond: Double = 0,
    cacheHitRate: Double = 0,
    circuitBreakerTrips: Int = 0,
    memoryWarnings: Int = 0
  ) {
    self.totalTasks = totalTasks
    self.successfulTasks = successfulTasks
    self.failedTasks = failedTasks
    self.averageParsingTime = averageParsingTime
    self.averageBytesPerSecond = averageBytesPerSecond
    self.cacheHitRate = cacheHitRate
    self.circuitBreakerTrips = circuitBreakerTrips
    self.memoryWarnings = memoryWarnings
  }
}

/// Telemetry collector for parsing operations
@MainActor
public final class ParsingTelemetry: ObservableObject {
  private var events: [TelemetryEvent] = []
  private let maxEvents: Int

  @Published public private(set) var metrics = PerformanceMetrics()

  public init(maxEvents: Int = 1000) {
    self.maxEvents = maxEvents
  }

  /// Record a telemetry event
  public func recordEvent(
    type: TelemetryEventType,
    properties: [String: String] = [:],
    metrics: [String: Double] = [:]
  ) {
    let event = TelemetryEvent(
      type: type,
      properties: properties,
      metrics: metrics
    )

    events.append(event)

    // Keep events list manageable
    if events.count > maxEvents {
      events.removeFirst(maxEvents / 4)  // Remove oldest 25%
    }

    updateAggregatedMetrics()
  }

  /// Record task completion with detailed metrics
  public func recordTaskCompletion(
    url: URL,
    result: ParsingResult,
    retryCount: Int = 0
  ) {
    let properties: [String: String] = [
      "url": url.absoluteString,
      "domain": url.host ?? "unknown",
      "retry_count": String(retryCount),
      "was_cache_hit": String(result.wasCacheHit),
    ]

    var eventMetrics: [String: Double] = [:]

    switch result {
    case let .success(feed, parsingMetrics):
      eventMetrics = [
        "duration": parsingMetrics.duration,
        "bytes_processed": Double(parsingMetrics.bytesProcessed),
        "articles_found": Double(parsingMetrics.articlesFound),
        "network_latency": parsingMetrics.networkLatency ?? 0,
      ]

      recordEvent(
        type: .taskCompleted,
        properties: properties,
        metrics: eventMetrics
      )

    case let .failure(error, parsingMetrics):
      eventMetrics = [
        "duration": parsingMetrics.duration,
        "bytes_processed": Double(parsingMetrics.bytesProcessed),
      ]

      let failureProperties = properties.merging([
        "error_type": String(describing: type(of: error)),
        "error_description": error.localizedDescription,
      ]) { _, new in new }

      recordEvent(
        type: .taskFailed,
        properties: failureProperties,
        metrics: eventMetrics
      )

    case .cancelled:
      recordEvent(
        type: .taskFailed,
        properties: properties.merging(["cancelled": "true"]) { _, new in new }
      )
    }
  }

  /// Record batch completion
  public func recordBatchCompletion(_ batchResult: BatchParsingResult) {
    let properties = [
      "batch_id": batchResult.batchId.uuidString,
      "total_urls": String(batchResult.results.count),
      "success_count": String(batchResult.successCount),
      "failure_count": String(batchResult.failureCount),
    ]

    let metrics = [
      "total_duration": batchResult.totalDuration,
      "average_duration": batchResult.averageDuration ?? 0,
      "total_bytes": Double(batchResult.totalBytesProcessed),
      "cache_hit_rate": batchResult.cacheHitRate,
    ]

    recordEvent(
      type: .batchCompleted,
      properties: properties,
      metrics: metrics
    )
  }

  /// Get events for a specific time range
  public func events(
    from startDate: Date,
    to endDate: Date = Date(),
    type: TelemetryEventType? = nil
  ) -> [TelemetryEvent] {
    events.filter { event in
      event.timestamp >= startDate && event.timestamp <= endDate && (type == nil || event.type == type)
    }
  }

  /// Get events for the last N hours
  public func recentEvents(hours: Int, type: TelemetryEventType? = nil) -> [TelemetryEvent] {
    let startDate = Date().addingTimeInterval(-TimeInterval(hours * 3600))
    return events(from: startDate, type: type)
  }

  /// Clear old events
  public func clearOldEvents(olderThan date: Date) {
    events.removeAll { $0.timestamp < date }
    updateAggregatedMetrics()
  }

  /// Export events as JSON for debugging
  public func exportEventsAsJSON() -> Data? {
    let exportData: [String: Any] = [
      "events": events.map { event in
        [
          "type": event.type.rawValue,
          "timestamp": ISO8601DateFormatter().string(from: event.timestamp),
          "properties": event.properties,
          "metrics": event.metrics,
        ]
      },
      "aggregated_metrics": [
        "total_tasks": metrics.totalTasks,
        "successful_tasks": metrics.successfulTasks,
        "failed_tasks": metrics.failedTasks,
        "success_rate": metrics.successRate,
        "average_parsing_time": metrics.averageParsingTime,
        "cache_hit_rate": metrics.cacheHitRate,
        "circuit_breaker_trips": metrics.circuitBreakerTrips,
        "memory_warnings": metrics.memoryWarnings,
      ],
    ]

    return try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
  }

  // MARK: - Private Methods

  private func updateAggregatedMetrics() {
    let recentEvents = recentEvents(hours: 24)  // Last 24 hours

    let completedTasks = recentEvents.filter { $0.type == .taskCompleted }
    let failedTasks = recentEvents.filter { $0.type == .taskFailed }
    let circuitBreakerEvents = recentEvents.filter { $0.type == .circuitBreakerOpened }
    let memoryWarningEvents = recentEvents.filter {
      $0.type == .memoryPressureWarning || $0.type == .memoryPressureCritical
    }

    let totalTasks = completedTasks.count + failedTasks.count

    let avgParsingTime =
      completedTasks.isEmpty
      ? 0 : completedTasks.compactMap { $0.metrics["duration"] }.reduce(0, +) / Double(completedTasks.count)

    let cacheHits = Double(
      completedTasks.filter {
        $0.properties["was_cache_hit"] == "true"
      }.count)
    let cacheHitRate = totalTasks > 0 ? cacheHits / Double(totalTasks) : 0.0

    let bytesPerSecond: Double
    if completedTasks.isEmpty {
      bytesPerSecond = 0
    } else {
      let totalBytes = completedTasks.compactMap { $0.metrics["bytes_processed"] }.reduce(0, +)
      let totalTime = completedTasks.compactMap { $0.metrics["duration"] }.reduce(0, +)
      bytesPerSecond = totalTime > 0 ? totalBytes / totalTime : 0
    }

    metrics = PerformanceMetrics(
      totalTasks: totalTasks,
      successfulTasks: completedTasks.count,
      failedTasks: failedTasks.count,
      averageParsingTime: avgParsingTime,
      averageBytesPerSecond: bytesPerSecond,
      cacheHitRate: cacheHitRate,
      circuitBreakerTrips: circuitBreakerEvents.count,
      memoryWarnings: memoryWarningEvents.count
    )
  }
}
