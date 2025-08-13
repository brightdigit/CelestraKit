// QueueStatistics.swift
// Celestra
//
// Created by Claude on 13/8/2025.
//

public import Foundation

/// Statistics for monitoring queue performance
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
