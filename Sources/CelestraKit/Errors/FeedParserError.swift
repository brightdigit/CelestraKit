//
//  FeedParserError.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

import Foundation

/// Errors that can occur during feed parsing operations
public enum FeedParserError: Error, Sendable {
  case invalidURL
  case invalidArticleURL
  case missingRequiredData
  case parsingFailed(underlying: any Error)
  case networkError(underlying: any Error)
  case cacheError(underlying: any Error)

  public var localizedDescription: String {
    switch self {
    case .invalidURL:
      return "Invalid or missing feed URL"
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
