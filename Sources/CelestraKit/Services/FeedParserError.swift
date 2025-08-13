//
//  FeedParserError.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

public import Foundation

/// Errors that can occur during feed parsing operations
public enum FeedParserError: Error, Sendable {
  case invalidArticleURL
  case missingRequiredData
  case parsingFailed(underlying: Error)
  case networkError(underlying: Error)
  case cacheError(underlying: Error)

  public var localizedDescription: String {
    switch self {
    case .invalidArticleURL:
      return "Invalid or missing article URL"
    case .missingRequiredData:
      return "Required data is missing from the feed"
    case .parsingFailed(let underlying):
      return "Feed parsing failed: \(underlying.localizedDescription)"
    case .networkError(let underlying):
      return "Network error: \(underlying.localizedDescription)"
    case .cacheError(let underlying):
      return "Cache error: \(underlying.localizedDescription)"
    }
  }
}
