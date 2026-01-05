//
//  RSSFetcherServiceTests+Syndication.swift
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
    "RSSFetcherService parseUpdateInterval() - Syndication Tests", .serialized, .tags(.networkMock))
  final class Syndication {
    init() {
      mockURLProtocolSemaphore.wait()
    }

    deinit {
      MockURLProtocol.requestHandler = nil
      mockURLProtocolSemaphore.signal()
    }

    @Test("Parse syndication hourly period")
    func parseSyndicationHourly() async throws {
      let feedURL = URL(string: "https://example.com/feed.xml")!
      let mockData = try FixtureLoader.load("RSS/rss-with-syndication-hourly.xml")

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

      // hourly (3600s) / frequency (2) = 1800 seconds (30 minutes)
      #expect(interval == 1_800.0)
    }

    @Test("Parse syndication daily period")
    func parseSyndicationDaily() async throws {
      let feedURL = URL(string: "https://example.com/feed.xml")!
      let mockData = try FixtureLoader.load("RSS/rss-with-syndication-daily.xml")

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

      // daily (86400s) / frequency (1) = 86400 seconds
      #expect(interval == 86_400.0)
    }

    @Test("Parse syndication weekly period")
    func parseSyndicationWeekly() async throws {
      let feedURL = URL(string: "https://example.com/feed.xml")!
      let mockData = try FixtureLoader.load("RSS/rss-with-syndication-weekly.xml")

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

      // weekly (604800s) / frequency (1) = 604800 seconds
      #expect(interval == 604_800.0)
    }

    @Test("Parse syndication monthly period")
    func parseSyndicationMonthly() async throws {
      let feedURL = URL(string: "https://example.com/feed.xml")!
      let mockData = try FixtureLoader.load("RSS/rss-with-syndication-monthly.xml")

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

      // monthly (2592000s ≈ 30 days) / frequency (1) = 2592000 seconds
      #expect(interval == 2_592_000.0)
    }

    @Test("Parse syndication yearly period")
    func parseSyndicationYearly() async throws {
      let feedURL = URL(string: "https://example.com/feed.xml")!
      let mockData = try FixtureLoader.load("RSS/rss-with-syndication-yearly.xml")

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

      // yearly (31536000s = 365 days) / frequency (1) = 31536000 seconds
      #expect(interval == 31_536_000.0)
    }
  }
}
