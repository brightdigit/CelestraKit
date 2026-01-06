//
//  RSSFetcherServiceTests+Priority.swift
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
  @Suite(
    "RSSFetcherService parseUpdateInterval() - Priority Tests", .serialized, .tags(.networkMock))
  final class Priority {
    init() async {
      await mockURLProtocolCoordinator.acquire()
    }

    deinit {
      Task {
        await mockURLProtocolCoordinator.release()
      }
    }

    @Test("TTL takes priority over syndication module")
    func ttlTakesPriorityOverSyndication() async throws {
      let feedURL = URL(string: "https://example.com/feed.xml")!
      let mockData = try FixtureLoader.load("RSS/rss-with-ttl-and-syndication.xml")

      MockURLProtocol.requestHandler = { _ in
        let response = HTTPURLResponse(
          url: feedURL, statusCode: 200,
          httpVersion: nil, headerFields: nil
        )!
        return (response, mockData)
      }

      let service = RSSFetcherService(
        urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))
      let result = try await service.fetchFeed(from: feedURL)

      let interval = try #require(result.feedData?.minUpdateInterval)

      // TTL is 30 minutes (1800s), syndication is daily (86400s)
      // TTL should take priority
      #expect(interval == 1_800.0)
    }
  }
}
