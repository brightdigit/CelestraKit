// FeedManagerError.swift
// CelestraKit
//
// Created for Celestra on 2025-10-27.
//

import Foundation

/// Errors that can occur during feed management operations
public enum FeedManagerError: LocalizedError, Sendable {
  case feedLimitReached(currentCount: Int, limit: Int)
  case feedAlreadyExists(url: URL)
  case feedNotFound(id: UUID)
  case invalidFeedURL(url: URL)
  case batchOperationFailed(successCount: Int, failureCount: Int, errors: [any Error])
  case operationNotAllowed(reason: String)

  public var errorDescription: String? {
    switch self {
    case let .feedLimitReached(currentCount, limit):
      return "Feed limit reached. You have \(currentCount) feeds, and the maximum is \(limit)."
    case let .feedAlreadyExists(url):
      return "This feed already exists: \(url.absoluteString)"
    case let .feedNotFound(id):
      return "Feed not found with ID: \(id.uuidString)"
    case let .invalidFeedURL(url):
      return "Invalid feed URL: \(url.absoluteString)"
    case let .batchOperationFailed(successCount, failureCount, _):
      return "Batch operation completed with \(successCount) successes and \(failureCount) failures."
    case let .operationNotAllowed(reason):
      return "Operation not allowed: \(reason)"
    }
  }

  public var recoverySuggestion: String? {
    switch self {
    case .feedLimitReached:
      return "Please remove some feeds before adding new ones, or upgrade to a higher tier plan (coming soon)."
    case .feedAlreadyExists:
      return "This feed is already in your collection. Try refreshing it instead."
    case .feedNotFound:
      return "The feed may have been deleted. Please refresh your feed list."
    case .invalidFeedURL:
      return "Please check the URL and try again, or use the feed discovery feature to find the correct feed."
    case .batchOperationFailed:
      return "Some operations failed. Please review the errors and try again."
    case .operationNotAllowed:
      return "Please check the operation requirements and try again."
    }
  }

  /// User-facing message for display in UI
  public var userMessage: String {
    errorDescription ?? "An unknown error occurred."
  }
}
