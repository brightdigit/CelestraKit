//
//  FeedDiscoveryConfig.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

public import Foundation

/// Configuration for feed discovery operations
public struct FeedDiscoveryConfig: Sendable {
  public let maxRedirects: Int
  public let timeout: TimeInterval
  public let userAgent: String
  public let rateLimitDelay: TimeInterval

  public init(
    maxRedirects: Int = 5,
    timeout: TimeInterval = 30,
    userAgent: String = "Celestra/1.0 (+https://celestra.app)",
    rateLimitDelay: TimeInterval = 1.0
  ) {
    self.maxRedirects = maxRedirects
    self.timeout = timeout
    self.userAgent = userAgent
    self.rateLimitDelay = rateLimitDelay
  }
}
