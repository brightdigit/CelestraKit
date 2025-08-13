//
//  FeedDiscoveryServiceTests.swift
//  CelestraKitTests
//
//  Created for Celestra on 2025-08-13.
//

import Foundation
import XCTest

@testable import CelestraKit

final class FeedDiscoveryServiceTests: XCTestCase {
  private var mockHTTPClient: MockHTTPClient!
  private var mockCache: MockFeedCache!
  private var discoveryService: FeedDiscoveryService!

  override func setUp() {
    super.setUp()
    mockHTTPClient = MockHTTPClient()
    mockCache = MockFeedCache()
    let config = FeedDiscoveryConfig(rateLimitDelay: 0.0)  // No delay for tests
    discoveryService = FeedDiscoveryService(httpClient: mockHTTPClient, cache: mockCache, config: config)
  }

  override func tearDown() {
    mockHTTPClient = nil
    mockCache = nil
    discoveryService = nil
    super.tearDown()
  }

  // MARK: - Direct Feed Detection Tests

  func testDiscoverFeeds_withDirectRSSFeed_returnsDiscoveredFeed() async throws {
    // Given
    // swiftlint:disable:next force_unwrapping
    let feedURL = URL(string: "https://example.com/feed.xml")!
    let rssContent = Data(
      """
      <?xml version="1.0"?>
      <rss version="2.0">
        <channel>
          <title>Test RSS Feed</title>
          <description>A test feed</description>
          <item><title>Test Article</title></item>
        </channel>
      </rss>
      """.utf8)

    mockHTTPClient.responses[feedURL] = rssContent

    // When
    let discoveredFeeds = try await discoveryService.discoverFeeds(from: feedURL)

    // Then
    XCTAssertEqual(discoveredFeeds.count, 1)
    XCTAssertEqual(discoveredFeeds[0].url, feedURL)
    XCTAssertEqual(discoveredFeeds[0].title, "Test RSS Feed")
    XCTAssertEqual(discoveredFeeds[0].format, .rss)
  }

  func testDiscoverFeeds_withDirectAtomFeed_returnsDiscoveredFeed() async throws {
    // Given
    // swiftlint:disable:next force_unwrapping
    let feedURL = URL(string: "https://example.com/atom.xml")!
    let atomContent = Data(
      """
      <?xml version="1.0"?>
      <feed xmlns="http://www.w3.org/2005/Atom">
        <title>Test Atom Feed</title>
        <entry><title>Test Entry</title></entry>
      </feed>
      """.utf8)

    mockHTTPClient.responses[feedURL] = atomContent

    // When
    let discoveredFeeds = try await discoveryService.discoverFeeds(from: feedURL)

    // Then
    XCTAssertEqual(discoveredFeeds.count, 1)
    XCTAssertEqual(discoveredFeeds[0].url, feedURL)
    XCTAssertEqual(discoveredFeeds[0].title, "Test Atom Feed")
    XCTAssertEqual(discoveredFeeds[0].format, .atom)
  }

  func testDiscoverFeeds_withJSONFeed_returnsDiscoveredFeed() async throws {
    // Given
    // swiftlint:disable:next force_unwrapping
    let feedURL = URL(string: "https://example.com/feed.json")!
    let jsonContent = Data(
      """
      {
        "version": "https://jsonfeed.org/version/1.1",
        "title": "Test JSON Feed",
        "feed_url": "https://example.com/feed.json",
        "items": []
      }
      """.utf8)

    mockHTTPClient.responses[feedURL] = jsonContent

    // When
    let discoveredFeeds = try await discoveryService.discoverFeeds(from: feedURL)

    // Then
    XCTAssertEqual(discoveredFeeds.count, 1)
    XCTAssertEqual(discoveredFeeds[0].url, feedURL)
    XCTAssertEqual(discoveredFeeds[0].format, .jsonFeed)
  }

  // MARK: - HTML Discovery Tests

  func testDiscoverFeeds_withHTMLContainingFeedLinks_returnsDiscoveredFeeds() async throws {
    // Given
    // swiftlint:disable:next force_unwrapping
    let websiteURL = URL(string: "https://example.com")!
    // swiftlint:disable:next force_unwrapping
    let rssURL = URL(string: "https://example.com/rss.xml")!
    // swiftlint:disable:next force_unwrapping
    let atomURL = URL(string: "https://example.com/atom.xml")!

    let htmlContent = Data(
      """
      <html>
        <head>
          <link rel="alternate" type="application/rss+xml" title="RSS Feed" href="/rss.xml">
          <link rel="alternate" type="application/atom+xml" title="Atom Feed" href="/atom.xml">
        </head>
        <body>Content</body>
      </html>
      """.utf8)

    let rssContent = Data("<?xml version=\"1.0\"?><rss version=\"2.0\"><channel></channel></rss>".utf8)
    let atomContent = Data("<?xml version=\"1.0\"?><feed xmlns=\"http://www.w3.org/2005/Atom\"></feed>".utf8)

    mockHTTPClient.responses[websiteURL] = htmlContent
    mockHTTPClient.responses[rssURL] = rssContent
    mockHTTPClient.responses[atomURL] = atomContent

    // When
    let discoveredFeeds = try await discoveryService.discoverFeeds(from: websiteURL)

    // Then
    XCTAssertEqual(discoveredFeeds.count, 2)

    let rssDiscovered = discoveredFeeds.first { $0.url == rssURL }
    let atomDiscovered = discoveredFeeds.first { $0.url == atomURL }

    XCTAssertNotNil(rssDiscovered)
    XCTAssertEqual(rssDiscovered?.title, "RSS Feed")
    XCTAssertEqual(rssDiscovered?.format, .rss)

    XCTAssertNotNil(atomDiscovered)
    XCTAssertEqual(atomDiscovered?.title, "Atom Feed")
    XCTAssertEqual(atomDiscovered?.format, .atom)
  }

  // MARK: - Common Pattern Tests

  func testDiscoverFeeds_withCommonFeedPatterns_findsFeeds() async throws {
    // Given
    // swiftlint:disable:next force_unwrapping
    let websiteURL = URL(string: "https://example.com")!
    // swiftlint:disable:next force_unwrapping
    let feedURL = URL(string: "https://example.com/feed")!

    let htmlContent = Data("<html><body>No feed links</body></html>".utf8)
    let rssContent = Data("<?xml version=\"1.0\"?><rss version=\"2.0\"><channel></channel></rss>".utf8)

    mockHTTPClient.responses[websiteURL] = htmlContent
    mockHTTPClient.responses[feedURL] = rssContent

    // When
    let discoveredFeeds = try await discoveryService.discoverFeeds(from: websiteURL)

    // Then
    XCTAssertEqual(discoveredFeeds.count, 1)
    XCTAssertEqual(discoveredFeeds[0].url, feedURL)
    XCTAssertEqual(discoveredFeeds[0].format, .rss)
  }

  // MARK: - URL Validation Tests

  func testValidateFeedURL_withValidRSSFeed_returnsTrue() async throws {
    // Given
    // swiftlint:disable:next force_unwrapping
    let feedURL = URL(string: "https://example.com/feed.xml")!
    let rssContent = Data("<?xml version=\"1.0\"?><rss version=\"2.0\"><channel></channel></rss>".utf8)

    mockHTTPClient.responses[feedURL] = rssContent

    // When
    let isValid = try await discoveryService.validateFeedURL(feedURL)

    // Then
    XCTAssertTrue(isValid)
  }

  func testValidateFeedURL_withInvalidContent_returnsFalse() async throws {
    // Given
    // swiftlint:disable:next force_unwrapping
    let feedURL = URL(string: "https://example.com/not-a-feed.html")!
    let htmlContent = Data("<html><body>Regular webpage content</body></html>".utf8)

    mockHTTPClient.responses[feedURL] = htmlContent

    // When
    let isValid = try await discoveryService.validateFeedURL(feedURL)

    // Then
    XCTAssertFalse(isValid)
  }

  // MARK: - Format Detection Tests

  func testDetectFormat_withRSSContent_returnsRSS() async throws {
    // Given
    // swiftlint:disable:next force_unwrapping
    let feedURL = URL(string: "https://example.com/feed.xml")!
    let rssContent = Data(
      """
      <?xml version="1.0"?>
      <rss version="2.0">
        <channel>
          <title>RSS Feed</title>
        </channel>
      </rss>
      """.utf8)

    mockHTTPClient.responses[feedURL] = rssContent

    // When
    let format = try await discoveryService.detectFormat(for: feedURL)

    // Then
    XCTAssertEqual(format, .rss)
  }

  func testDetectFormat_withPodcastContent_returnsPodcast() async throws {
    // Given
    // swiftlint:disable:next force_unwrapping
    let feedURL = URL(string: "https://example.com/podcast.xml")!
    let podcastContent = Data(
      """
      <?xml version="1.0"?>
      <rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
        <channel>
          <title>Podcast Feed</title>
          <itunes:category text="Technology" />
        </channel>
      </rss>
      """.utf8)

    mockHTTPClient.responses[feedURL] = podcastContent

    // When
    let format = try await discoveryService.detectFormat(for: feedURL)

    // Then
    XCTAssertEqual(format, .podcast)
  }

  // MARK: - Error Handling Tests

  func testDiscoverFeeds_withNoFeedsFound_throwsError() async {
    // Given
    // swiftlint:disable:next force_unwrapping
    let websiteURL = URL(string: "https://example.com")!
    let htmlContent = Data("<html><body>No feeds here</body></html>".utf8)

    mockHTTPClient.responses[websiteURL] = htmlContent
    // No common feed patterns will return valid feeds

    // When/Then
    await XCTAssertThrowsError(try await discoveryService.discoverFeeds(from: websiteURL)) { error in
      XCTAssertEqual(error as? FeedDiscoveryError, .noFeedsFound)
    }
  }

  func testDiscoverFeeds_withNetworkError_throwsNetworkError() async {
    // Given
    // swiftlint:disable:next force_unwrapping
    let websiteURL = URL(string: "https://nonexistent.example.com")!
    mockHTTPClient.shouldThrowError = true

    // When/Then
    await XCTAssertThrowsError(try await discoveryService.discoverFeeds(from: websiteURL)) { error in
      if case .networkError = error as? FeedDiscoveryError {
        // Expected
      } else {
        XCTFail("Expected networkError, got \(error)")
      }
    }
  }
}

// MARK: - Mock Classes

private class MockHTTPClient: HTTPClientProtocol {
  var responses: [URL: Data] = [:]
  var shouldThrowError = false

  func fetch(url: URL) async throws -> Data {
    if shouldThrowError {
      throw HTTPClientError.networkError(underlying: URLError(.notConnectedToInternet))
    }

    guard let data = responses[url] else {
      throw HTTPClientError.httpError(statusCode: 404)
    }

    return data
  }
}

private class MockFeedCache: FeedCacheProtocol {
  private var cache: [URL: (feed: ParsedFeed, expiration: Date)] = [:]

  func get(for url: URL) async throws -> ParsedFeed? {
    guard let entry = cache[url] else {
      return nil
    }

    if entry.expiration < Date() {
      cache.removeValue(forKey: url)
      return nil
    }

    return entry.feed
  }

  func set(_ feed: ParsedFeed, for url: URL, expirationDate: Date) async throws {
    cache[url] = (feed: feed, expiration: expirationDate)
  }

  func remove(for url: URL) async throws {
    cache.removeValue(forKey: url)
  }

  func clear() async throws {
    cache.removeAll()
  }

  func cleanExpired() async throws {
    let now = Date()
    cache = cache.filter { $0.value.expiration >= now }
  }
}
