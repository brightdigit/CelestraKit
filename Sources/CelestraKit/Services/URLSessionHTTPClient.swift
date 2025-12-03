//
//  URLSessionHTTPClient.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

public import Foundation

#if canImport(FoundationNetworking)
  public import FoundationNetworking
#endif

/// URLSession-based HTTP client implementation
///
/// - Note: Conditional compilation ensures cross-platform compatibility
///   - Darwin platforms: Use Foundation's URLSession
///   - Linux: Requires FoundationNetworking import
///   - Fallback: Gracefully fails on platforms without networking support
public final class URLSessionHTTPClient: HTTPClientProtocol, @unchecked Sendable {
  private let session: URLSession

  public init(session: URLSession = .shared) {
    self.session = session
  }

  public func fetch(url: URL) async throws -> Data {
    let (data, response) = try await session.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw HTTPClientError.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
      throw HTTPClientError.httpError(statusCode: httpResponse.statusCode)
    }

    return data
  }
}
