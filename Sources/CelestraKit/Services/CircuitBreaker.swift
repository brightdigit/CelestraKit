//
//  CircuitBreaker.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

public import Foundation

/// Circuit breaker states
public enum CircuitBreakerState: Sendable, Codable {
  case closed      // Normal operation
  case open        // Failing, requests blocked
  case halfOpen    // Testing if service recovered
}

/// Configuration for circuit breaker behavior
public struct CircuitBreakerConfig: Sendable, Codable {
  public let failureThreshold: Int
  public let recoveryTimeout: TimeInterval
  public let halfOpenMaxCalls: Int
  public let halfOpenSuccessThreshold: Int
  
  public init(
    failureThreshold: Int = 5,
    recoveryTimeout: TimeInterval = 1800,  // 30 minutes
    halfOpenMaxCalls: Int = 3,
    halfOpenSuccessThreshold: Int = 2
  ) {
    self.failureThreshold = failureThreshold
    self.recoveryTimeout = recoveryTimeout
    self.halfOpenMaxCalls = halfOpenMaxCalls
    self.halfOpenSuccessThreshold = halfOpenSuccessThreshold
  }
}

/// Circuit breaker for feed parsing operations to prevent cascading failures
public final class CircuitBreaker: @unchecked Sendable {
  private let config: CircuitBreakerConfig
  private let _state = OSAllocatedUnfairLock(initialState: CircuitBreakerState.closed)
  private let _failureCount = OSAllocatedUnfairLock(initialState: 0)
  private let _lastFailureTime = OSAllocatedUnfairLock<Date?>(initialState: nil)
  private let _halfOpenCallCount = OSAllocatedUnfairLock(initialState: 0)
  private let _halfOpenSuccessCount = OSAllocatedUnfairLock(initialState: 0)
  
  public let url: URL
  
  public var state: CircuitBreakerState {
    _state.withLock { $0 }
  }
  
  public var failureCount: Int {
    _failureCount.withLock { $0 }
  }
  
  public var lastFailureTime: Date? {
    _lastFailureTime.withLock { $0 }
  }
  
  public init(url: URL, config: CircuitBreakerConfig = CircuitBreakerConfig()) {
    self.url = url
    self.config = config
  }
  
  /// Check if requests should be allowed through the circuit breaker
  public func shouldAllowRequest() -> Bool {
    let currentState = updateStateIfNeeded()
    
    switch currentState {
    case .closed:
      return true
    case .open:
      return false
    case .halfOpen:
      return _halfOpenCallCount.withLock { count in
        guard count < config.halfOpenMaxCalls else { return false }
        count += 1
        return true
      }
    }
  }
  
  /// Record a successful operation
  public func recordSuccess() {
    _state.withLock { currentState in
      switch currentState {
      case .closed:
        // Reset failure count on success
        _failureCount.withLock { $0 = 0 }
        
      case .halfOpen:
        let successCount = _halfOpenSuccessCount.withLock { count in
          count += 1
          return count
        }
        
        // If we have enough successes, close the circuit
        if successCount >= config.halfOpenSuccessThreshold {
          currentState = .closed
          _failureCount.withLock { $0 = 0 }
          _halfOpenCallCount.withLock { $0 = 0 }
          _halfOpenSuccessCount.withLock { $0 = 0 }
        }
        
      case .open:
        // Success while open shouldn't happen, but reset if it does
        break
      }
    }
  }
  
  /// Record a failed operation
  public func recordFailure() {
    let now = Date()
    _lastFailureTime.withLock { $0 = now }
    
    let newFailureCount = _failureCount.withLock { count in
      count += 1
      return count
    }
    
    _state.withLock { currentState in
      switch currentState {
      case .closed:
        // Open circuit if failure threshold exceeded
        if newFailureCount >= config.failureThreshold {
          currentState = .open
        }
        
      case .halfOpen:
        // Any failure in half-open state should open the circuit
        currentState = .open
        _halfOpenCallCount.withLock { $0 = 0 }
        _halfOpenSuccessCount.withLock { $0 = 0 }
        
      case .open:
        // Already open, just track the failure
        break
      }
    }
  }
  
  /// Get time until circuit breaker might allow requests again
  public func timeUntilRetry() -> TimeInterval? {
    guard state == .open,
          let lastFailure = lastFailureTime else { return nil }
    
    let timeSinceFailure = Date().timeIntervalSince(lastFailure)
    let remainingTime = config.recoveryTimeout - timeSinceFailure
    
    return remainingTime > 0 ? remainingTime : 0
  }
  
  /// Check if circuit should transition from open to half-open
  private func updateStateIfNeeded() -> CircuitBreakerState {
    _state.withLock { currentState in
      guard currentState == .open,
            let lastFailure = lastFailureTime,
            Date().timeIntervalSince(lastFailure) >= config.recoveryTimeout else {
        return currentState
      }
      
      // Transition to half-open
      currentState = .halfOpen
      _halfOpenCallCount.withLock { $0 = 0 }
      _halfOpenSuccessCount.withLock { $0 = 0 }
      
      return currentState
    }
  }
  
  /// Reset circuit breaker to closed state (for testing or manual intervention)
  public func reset() {
    _state.withLock { $0 = .closed }
    _failureCount.withLock { $0 = 0 }
    _lastFailureTime.withLock { $0 = nil }
    _halfOpenCallCount.withLock { $0 = 0 }
    _halfOpenSuccessCount.withLock { $0 = 0 }
  }
}

// MARK: - Circuit Breaker Manager

/// Manages circuit breakers for multiple URLs
public final class CircuitBreakerManager: @unchecked Sendable {
  private let _circuitBreakers = OSAllocatedUnfairLock([URL: CircuitBreaker]())
  private let config: CircuitBreakerConfig
  
  public init(config: CircuitBreakerConfig = CircuitBreakerConfig()) {
    self.config = config
  }
  
  /// Get or create circuit breaker for URL
  public func circuitBreaker(for url: URL) -> CircuitBreaker {
    _circuitBreakers.withLock { breakers in
      if let existing = breakers[url] {
        return existing
      }
      
      let new = CircuitBreaker(url: url, config: config)
      breakers[url] = new
      return new
    }
  }
  
  /// Check if URL is currently blocked by circuit breaker
  public func isBlocked(_ url: URL) -> Bool {
    let breaker = circuitBreaker(for: url)
    return !breaker.shouldAllowRequest()
  }
  
  /// Record success for URL
  public func recordSuccess(for url: URL) {
    circuitBreaker(for: url).recordSuccess()
  }
  
  /// Record failure for URL
  public func recordFailure(for url: URL) {
    circuitBreaker(for: url).recordFailure()
  }
  
  /// Get all currently blocked URLs
  public func blockedUrls() -> Set<URL> {
    _circuitBreakers.withLock { breakers in
      Set(breakers.compactMap { url, breaker in
        breaker.shouldAllowRequest() ? nil : url
      })
    }
  }
  
  /// Get circuit breaker states for monitoring
  public func states() -> [URL: CircuitBreakerState] {
    _circuitBreakers.withLock { breakers in
      breakers.mapValues(\.state)
    }
  }
  
  /// Reset circuit breaker for specific URL
  public func reset(url: URL) {
    _circuitBreakers.withLock { breakers in
      breakers[url]?.reset()
    }
  }
  
  /// Reset all circuit breakers
  public func resetAll() {
    _circuitBreakers.withLock { breakers in
      breakers.values.forEach { $0.reset() }
    }
  }
}