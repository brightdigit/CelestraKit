//
//  URLSessionHTTPClient.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

public import Foundation

/// URLSession-based implementation of HTTPClientProtocol
public final class URLSessionHTTPClient: HTTPClientProtocol, @unchecked Sendable {
  private let session: URLSession
  private let timeoutInterval: TimeInterval

  /// Creates a new URLSession HTTP client
  /// - Parameters:
  ///   - session: URLSession to use for requests (default: shared)
  ///   - timeoutInterval: Request timeout in seconds (default: 30)
  public init(session: URLSession = .shared, timeoutInterval: TimeInterval = 30) {
    self.session = session
    self.timeoutInterval = timeoutInterval
  }

  public func fetch(url: URL) async throws -> Data {
    var request = URLRequest(url: url)
    request.timeoutInterval = timeoutInterval
    request.setValue("Celestra/1.0 (RSS Reader)", forHTTPHeaderField: "User-Agent")
    request.setValue(
      "application/rss+xml, application/atom+xml, application/json, application/xml, text/xml",
      forHTTPHeaderField: "Accept")

    do {
      let (data, response) = try await session.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse else {
        throw HTTPClientError.networkError(underlying: URLError(.badServerResponse))
      }

      // Check for successful HTTP status codes (200-299)
      guard 200...299 ~= httpResponse.statusCode else {
        throw HTTPClientError.httpError(statusCode: httpResponse.statusCode)
      }

      guard !data.isEmpty else {
        throw HTTPClientError.noData
      }

      return data
    } catch let error as HTTPClientError {
      throw error
    } catch let urlError as URLError {
      switch urlError.code {
      case .timedOut:
        throw HTTPClientError.timeout
      case .badURL, .unsupportedURL:
        throw HTTPClientError.invalidURL
      default:
        throw HTTPClientError.networkError(underlying: urlError)
      }
    } catch {
      throw HTTPClientError.networkError(underlying: error)
    }
  }
}
