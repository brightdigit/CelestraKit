//
//  RSSFetcherServiceTests+Errors.swift
//  CelestraKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

import Foundation
import Testing

@testable import CelestraKit

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension RSSFetcherServiceTests {
  @Suite("RSSFetcherService Error Cases Tests", .serialized, .tags(.networkMock))
  final class Errors {
    init() {
      mockURLProtocolSemaphore.wait()
    }

    deinit {
      MockURLProtocol.requestHandler = nil
      mockURLProtocolSemaphore.signal()
    }

    @Test("Throw error on invalid feed data")
    func throwErrorOnInvalidFeedData() async throws {
      let feedURL = URL(string: "https://example.com/feed.xml")!
      let mockData = try FixtureLoader.load("RSS/invalid-rss.xml")

      MockURLProtocol.requestHandler = { _ in
        let response = HTTPURLResponse(
          url: feedURL, statusCode: 200,
          httpVersion: nil, headerFields: nil
        )!
        return (response, mockData)
      }

      let service = RSSFetcherService(
        urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))

      await #expect(throws: RSSFetcherError.self) {
        try await service.fetchFeed(from: feedURL)
      }
    }

    @Test("Throw error on network failure")
    func throwErrorOnNetworkFailure() async throws {
      let feedURL = URL(string: "https://example.com/feed.xml")!

      MockURLProtocol.requestHandler = { _ in
        throw URLError(.notConnectedToInternet)
      }

      let service = RSSFetcherService(
        urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))

      await #expect(throws: RSSFetcherError.self) {
        try await service.fetchFeed(from: feedURL)
      }
    }

    @Test("Throw error on HTTP error status codes")
    func throwErrorOnHTTPErrorStatus() async throws {
      let feedURL = URL(string: "https://example.com/feed.xml")!

      for statusCode in [400, 404, 500, 503] {
        MockURLProtocol.requestHandler = { _ in
          let response = HTTPURLResponse(
            url: feedURL, statusCode: statusCode,
            httpVersion: nil, headerFields: nil
          )!
          return (response, nil)
        }

        let service = RSSFetcherService(
          urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))

        await #expect(throws: RSSFetcherError.self) {
          try await service.fetchFeed(from: feedURL)
        }
      }
    }
  }
}
