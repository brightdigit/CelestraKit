//
//  HTTPClientProtocol.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

public import Foundation

/// Protocol for HTTP client abstraction to support multiple implementations
/// Currently supports URLSession, designed to support async-http-client in the future
public protocol HTTPClientProtocol: Sendable {
  /// Fetches data from the given URL
  /// - Parameter url: The URL to fetch data from
  /// - Returns: The raw data from the response
  /// - Throws: HTTPClientError for network-related failures
  func fetch(url: URL) async throws -> Data
}

/// Errors that can occur during HTTP operations
public enum HTTPClientError: Error, Sendable {
  case invalidURL
  case noData
  case httpError(statusCode: Int)
  case networkError(underlying: Error)
  case timeout

  public var localizedDescription: String {
    switch self {
    case .invalidURL:
      return "Invalid URL provided"
    case .noData:
      return "No data received from server"
    case .httpError(let statusCode):
      return "HTTP error with status code: \(statusCode)"
    case .networkError(let underlying):
      return "Network error: \(underlying.localizedDescription)"
    case .timeout:
      return "Request timed out"
    }
  }
}
