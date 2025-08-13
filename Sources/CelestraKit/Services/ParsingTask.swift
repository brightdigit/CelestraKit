//
//  ParsingTask.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

public import Foundation

/// Priority levels for parsing tasks
public enum ParsingPriority: Int, Sendable, Comparable, Codable {
  case high = 3
  case normal = 2
  case low = 1
  
  public static func < (lhs: ParsingPriority, rhs: ParsingPriority) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

/// State of a parsing task in the queue
public enum ParsingTaskState: Sendable, Codable {
  case pending
  case running
  case completed(ParsingResult)
  case failed(Error, retryCount: Int)
  case cancelled
  case circuitOpen
  
  public var isTerminal: Bool {
    switch self {
    case .completed, .cancelled, .circuitOpen:
      return true
    case .pending, .running, .failed:
      return false
    }
  }
}

/// Configuration for retry behavior
public struct RetryConfig: Sendable, Codable {
  public let maxRetries: Int
  public let baseDelay: TimeInterval
  public let maxDelay: TimeInterval
  public let jitterFactor: Double
  
  public init(
    maxRetries: Int = 5,
    baseDelay: TimeInterval = 1.0,
    maxDelay: TimeInterval = 16.0,
    jitterFactor: Double = 0.1
  ) {
    self.maxRetries = maxRetries
    self.baseDelay = baseDelay
    self.maxDelay = maxDelay
    self.jitterFactor = jitterFactor
  }
  
  /// Calculate delay for retry attempt with exponential backoff and jitter
  public func delay(for attempt: Int) -> TimeInterval {
    let exponentialDelay = min(baseDelay * pow(2.0, Double(attempt)), maxDelay)
    let jitter = exponentialDelay * jitterFactor * Double.random(in: -1...1)
    return max(0, exponentialDelay + jitter)
  }
}

/// Individual parsing task with metadata and retry logic
public final class ParsingTask: @unchecked Sendable, Identifiable {
  public let id: UUID
  public let url: URL
  public let priority: ParsingPriority
  public let retryConfig: RetryConfig
  public let createdAt: Date
  public let userInitiated: Bool
  
  private let _state = OSAllocatedUnfairLock(initialState: ParsingTaskState.pending)
  private let _retryCount = OSAllocatedUnfairLock(initialState: 0)
  private let _lastAttemptAt = OSAllocatedUnfairLock<Date?>(initialState: nil)
  
  public var state: ParsingTaskState {
    _state.withLock { $0 }
  }
  
  public var retryCount: Int {
    _retryCount.withLock { $0 }
  }
  
  public var lastAttemptAt: Date? {
    _lastAttemptAt.withLock { $0 }
  }
  
  public var shouldRetry: Bool {
    guard case .failed(_, let currentRetryCount) = state else { return false }
    return currentRetryCount < retryConfig.maxRetries
  }
  
  public var nextRetryAt: Date? {
    guard case .failed(_, let currentRetryCount) = state,
          let lastAttempt = lastAttemptAt,
          shouldRetry else { return nil }
    
    let delay = retryConfig.delay(for: currentRetryCount)
    return lastAttempt.addingTimeInterval(delay)
  }
  
  public init(
    url: URL,
    priority: ParsingPriority = .normal,
    retryConfig: RetryConfig = RetryConfig(),
    userInitiated: Bool = false
  ) {
    self.id = UUID()
    self.url = url
    self.priority = priority
    self.retryConfig = retryConfig
    self.createdAt = Date()
    self.userInitiated = userInitiated
  }
  
  /// Update task state atomically
  public func updateState(_ newState: ParsingTaskState) {
    _state.withLock { currentState in
      // Prevent invalid state transitions
      guard !currentState.isTerminal else { return }
      currentState = newState
    }
    
    // Update timestamps for tracking
    switch newState {
    case .running, .failed:
      _lastAttemptAt.withLock { $0 = Date() }
    case .failed(_, let count):
      _retryCount.withLock { $0 = count }
    default:
      break
    }
  }
  
  /// Increment retry count and update state
  public func recordFailure(_ error: Error) {
    let newRetryCount = _retryCount.withLock { count in
      count += 1
      return count
    }
    
    updateState(.failed(error, retryCount: newRetryCount))
  }
  
  /// Check if task is ready for retry
  public func isReadyForRetry(at date: Date = Date()) -> Bool {
    guard shouldRetry,
          let nextRetry = nextRetryAt else { return false }
    return date >= nextRetry
  }
}

// MARK: - Hashable & Equatable

extension ParsingTask: Hashable, Equatable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  public static func == (lhs: ParsingTask, rhs: ParsingTask) -> Bool {
    lhs.id == rhs.id
  }
}

// MARK: - Comparable for Priority Queue

extension ParsingTask: Comparable {
  public static func < (lhs: ParsingTask, rhs: ParsingTask) -> Bool {
    // Higher priority first
    if lhs.priority != rhs.priority {
      return lhs.priority > rhs.priority
    }
    
    // User-initiated tasks first
    if lhs.userInitiated != rhs.userInitiated {
      return lhs.userInitiated && !rhs.userInitiated
    }
    
    // Earlier creation time first
    return lhs.createdAt < rhs.createdAt
  }
}

// MARK: - Error Handling

extension ParsingTaskState {
  public var error: Error? {
    guard case .failed(let error, _) = self else { return nil }
    return error
  }
  
  public var result: ParsingResult? {
    guard case .completed(let result) = self else { return nil }
    return result
  }
}