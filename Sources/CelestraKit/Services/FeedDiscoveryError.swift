//
//  FeedDiscoveryError.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

public import Foundation

/// Errors that can occur during feed discovery
public enum FeedDiscoveryError: Error, Sendable, Equatable {
  case invalidURL
  case noFeedsFound
  case htmlParsingFailed
  case networkError(underlying: any Error)
  case rateLimitExceeded
  case formatDetectionFailed

  public var localizedDescription: String {
    switch self {
    case .invalidURL:
      return "Invalid URL provided"
    case .noFeedsFound:
      return "No feeds discovered at the given URL"
    case .htmlParsingFailed:
      return "Failed to parse HTML content"
    case .networkError(let underlying):
      return "Network error: \(underlying.localizedDescription)"
    case .rateLimitExceeded:
      return "Rate limit exceeded for feed discovery"
    case .formatDetectionFailed:
      return "Could not detect feed format"
    }
  }

  public static func == (lhs: FeedDiscoveryError, rhs: FeedDiscoveryError) -> Bool {
    switch (lhs, rhs) {
    case (.invalidURL, .invalidURL),
      (.noFeedsFound, .noFeedsFound),
      (.htmlParsingFailed, .htmlParsingFailed),
      (.rateLimitExceeded, .rateLimitExceeded),
      (.formatDetectionFailed, .formatDetectionFailed):
      return true
    case (.networkError, .networkError):
      // Compare only the case, not the underlying error
      return true
    default:
      return false
    }
  }
}
