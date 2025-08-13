// BackgroundParsingConfig.swift
// Celestra
//
// Created by Claude on 13/8/2025.
//

public import Foundation

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
    batchSize: Int = 10,
    batchTimeout: TimeInterval = 30
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
