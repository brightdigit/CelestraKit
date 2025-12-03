//
//  HTTPClientError.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

import Foundation

/// Errors that can occur during HTTP client operations
public enum HTTPClientError: Error, Sendable {
  case networkError(underlying: any Error)
  case httpError(statusCode: Int)
  case invalidResponse
  case invalidURL

  public var localizedDescription: String {
    switch self {
    case .networkError(let underlying):
      return "Network error: \(underlying.localizedDescription)"
    case .httpError(let statusCode):
      return "HTTP error with status code: \(statusCode)"
    case .invalidResponse:
      return "Invalid response received from server"
    case .invalidURL:
      return "Invalid URL provided"
    }
  }
}
