//
//  RSSFetcherServiceTests+FetchSuccess.swift
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
  @Suite("RSSFetcherService fetchFeed() Success Cases", .serialized, .tags(.networkMock))
  final class FetchSuccess {
    init() {
      mockURLProtocolSemaphore.wait()
    }

    deinit {
      MockURLProtocol.requestHandler = nil
      mockURLProtocolSemaphore.signal()
    }

    @Test("Fetch basic RSS feed successfully")
    func fetchBasicRSSFeed() async throws {
      let feedURL = URL(string: "https://example.com/feed.xml")!
      let mockData = try FixtureLoader.load("RSS/basic-rss.xml")

      MockURLProtocol.requestHandler = { _ in
        let response = HTTPURLResponse(
          url: feedURL,
          statusCode: 200,
          httpVersion: nil,
          headerFields: [
            "Content-Type": "application/rss+xml",
            "Last-Modified": "Mon, 01 Jan 2024 12:00:00 GMT",
            "ETag": "\"abc123\"",
          ]
        )!
        return (response, mockData)
      }

      let session = createMockURLSession()
      let service = RSSFetcherService(urlSession: session, userAgent: UserAgent.app(build: 1))

      let result = try await service.fetchFeed(from: feedURL)

      #expect(result.wasModified == true)
      #expect(result.lastModified == "Mon, 01 Jan 2024 12:00:00 GMT")
      #expect(result.etag == "\"abc123\"")
      #expect(result.feedData != nil)
      #expect(result.feedData?.title == "Example RSS Feed")
      #expect(result.feedData?.description == "A sample RSS feed for testing")
      #expect(result.feedData?.items.count == 2)
    }

    @Test("Fetch Atom feed successfully")
    func fetchAtomFeed() async throws {
      let feedURL = URL(string: "https://example.com/atom.xml")!
      let mockData = try FixtureLoader.load("Atom/basic-atom.xml")

      MockURLProtocol.requestHandler = { _ in
        let response = HTTPURLResponse(
          url: feedURL,
          statusCode: 200,
          httpVersion: nil,
          headerFields: ["Content-Type": "application/atom+xml"]
        )!
        return (response, mockData)
      }

      let session = createMockURLSession()
      let service = RSSFetcherService(urlSession: session, userAgent: UserAgent.app(build: 1))

      let result = try await service.fetchFeed(from: feedURL)

      #expect(result.wasModified == true)
      #expect(result.feedData != nil)
      #expect(result.feedData?.title == "Example Atom Feed")
      #expect(result.feedData?.items.count == 1)

      let firstItem = try #require(result.feedData?.items.first)
      #expect(firstItem.title == "First Entry")
      #expect(firstItem.author == "Jane Doe")
    }

    @Test("Feed items contain all expected fields")
    func feedItemsContainAllFields() async throws {
      let feedURL = URL(string: "https://example.com/feed.xml")!
      let mockData = try FixtureLoader.load("RSS/basic-rss.xml")

      MockURLProtocol.requestHandler = { _ in
        (
          HTTPURLResponse(
            url: feedURL, statusCode: 200, httpVersion: nil,
            headerFields: nil
          )!, mockData
        )
      }

      let service = RSSFetcherService(
        urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))
      let result = try await service.fetchFeed(from: feedURL)

      let items = try #require(result.feedData?.items)
      #expect(items.count == 2)

      // First item (minimal fields)
      let item1 = items[0]
      #expect(item1.title == "First Post")
      #expect(item1.link == "https://example.com/post/1")
      #expect(item1.description == "This is the first post")
      #expect(item1.guid == "https://example.com/post/1")
      #expect(item1.author == nil)

      // Second item (all fields)
      let item2 = items[1]
      #expect(item2.title == "Second Post")
      #expect(item2.link == "https://example.com/post/2")
      #expect(item2.description == "This is the second post")
      #expect(item2.author == "John Doe")
      #expect(item2.guid == "unique-guid-123")
      #expect(item2.content != nil)
    }
  }
}
