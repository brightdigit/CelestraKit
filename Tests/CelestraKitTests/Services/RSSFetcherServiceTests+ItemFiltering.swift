//
//  RSSFetcherServiceTests+ItemFiltering.swift
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
  @Suite("RSSFetcherService Item Filtering Tests", .serialized, .tags(.networkMock))
  final class ItemFiltering {
    init() {
      mockURLProtocolSemaphore.wait()
    }

    deinit {
      MockURLProtocol.requestHandler = nil
      mockURLProtocolSemaphore.signal()
    }

    // TODO: File upstream issue with SyndiKit for RSS feeds with empty <link> elements
    // SyndiKit currently fails to parse valid RSS feeds where some items have empty/missing links
    // The RSS spec allows optional link elements in items, but SyndiKit rejects such feeds
    // Repository: https://github.com/brightdigit/SyndiKit/issues
    @Test(
      "All items have valid links", .disabled("SyndiKit doesn't parse RSS with empty link elements"))
    func filterItemsWithEmptyLinks() async throws {
      let feedURL = URL(string: "https://example.com/feed.xml")!
      let mockData = try FixtureLoader.load("RSS/rss-with-empty-link-items.xml")

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

      let items = try #require(result.feedData?.items)

      // Should only have 1 valid item (the other 2 have empty links)
      #expect(items.count == 1)
      #expect(items[0].title == "Valid Item")
      #expect(items[0].link == "https://example.com/valid")
    }
  }
}
