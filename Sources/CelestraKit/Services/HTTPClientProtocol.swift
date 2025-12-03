//
//  HTTPClientProtocol.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

public import Foundation

/// Protocol for HTTP client operations
public protocol HTTPClientProtocol: Sendable {
  /// Fetches data from a URL
  /// - Parameter url: The URL to fetch from
  /// - Returns: The fetched data
  /// - Throws: Network or HTTP errors
  func fetch(url: URL) async throws -> Data
}
