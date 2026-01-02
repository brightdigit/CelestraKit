//
//  URLSessionHTTPClient.swift
//  CelestraKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import Foundation

#if canImport(FoundationNetworking)
  public import FoundationNetworking
#endif

/// HTTP client errors
public enum HTTPClientError: Error {
  case invalidResponse
  case httpError(statusCode: Int)
}

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

  /// Factory method for creating an HTTP client with caching enabled
  /// - Returns: URLSessionHTTPClient configured with 20MB memory cache and 100MB disk cache
  public static func withCaching() -> URLSessionHTTPClient {
    let config = URLSessionConfiguration.default
    config.requestCachePolicy = .returnCacheDataElseLoad
    config.urlCache = URLCache(
      memoryCapacity: 20 * 1_024 * 1_024,  // 20 MB memory cache
      diskCapacity: 100 * 1_024 * 1_024,  // 100 MB disk cache
      diskPath: nil
    )
    return URLSessionHTTPClient(session: URLSession(configuration: config))
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
