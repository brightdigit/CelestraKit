//
//  FeedDiscoveryServiceTests.swift
//  CelestraKitTests
//
//  Created for Celestra on 2025-08-13.
//
//  NOTE: These tests are temporarily disabled and will be rewritten in Swift Testing

#if false
  import Foundation
  import XCTest

  #if canImport(FoundationNetworking)
    import FoundationNetworking
  #endif

  @testable import CelestraKit

  final class FeedDiscoveryServiceTests: XCTestCase {
    private var mockHTTPClient: MockHTTPClient!
    private var discoveryService: FeedDiscoveryService!

    override func setUp() {
      super.setUp()
      mockHTTPClient = MockHTTPClient()
      let config = FeedDiscoveryConfig(rateLimitDelay: 0.0)  // No delay for tests
      discoveryService = FeedDiscoveryService(httpClient: mockHTTPClient, config: config)
    }

    override func tearDown() {
      mockHTTPClient = nil
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

      await mockHTTPClient.setResponse(rssContent, for: feedURL)

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

      await mockHTTPClient.setResponse(atomContent, for: feedURL)

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

      await mockHTTPClient.setResponse(jsonContent, for: feedURL)

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

      await mockHTTPClient.setResponse(htmlContent, for: websiteURL)
      await mockHTTPClient.setResponse(rssContent, for: rssURL)
      await mockHTTPClient.setResponse(atomContent, for: atomURL)

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

      await mockHTTPClient.setResponse(htmlContent, for: websiteURL)
      await mockHTTPClient.setResponse(rssContent, for: feedURL)

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

      await mockHTTPClient.setResponse(rssContent, for: feedURL)

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

      await mockHTTPClient.setResponse(htmlContent, for: feedURL)

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

      await mockHTTPClient.setResponse(rssContent, for: feedURL)

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

      await mockHTTPClient.setResponse(podcastContent, for: feedURL)

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

      await mockHTTPClient.setResponse(htmlContent, for: websiteURL)
      // No common feed patterns will return valid feeds

      // When/Then
      do {
        _ = try await discoveryService.discoverFeeds(from: websiteURL)
        XCTFail("Expected noFeedsFound error to be thrown")
      } catch let error as FeedDiscoveryError {
        XCTAssertEqual(error, .noFeedsFound)
      } catch {
        XCTFail("Expected FeedDiscoveryError.noFeedsFound, got \(error)")
      }
    }

    func testDiscoverFeeds_withNetworkError_throwsNetworkError() async {
      // Given
      // swiftlint:disable:next force_unwrapping
      let websiteURL = URL(string: "https://nonexistent.example.com")!
      await mockHTTPClient.setShouldThrowError(true)

      // When/Then
      do {
        _ = try await discoveryService.discoverFeeds(from: websiteURL)
        XCTFail("Expected networkError to be thrown")
      } catch let error as FeedDiscoveryError {
        if case .networkError = error {
          // Expected - test passes
        } else {
          XCTFail("Expected networkError, got \(error)")
        }
      } catch {
        XCTFail("Expected FeedDiscoveryError.networkError, got \(error)")
      }
    }
  }

  // MARK: - Mock Classes

  private actor MockHTTPClient: HTTPClientProtocol {
    var responses: [URL: Data] = [:]
    var shouldThrowError = false

    func setResponse(_ data: Data, for url: URL) {
      responses[url] = data
    }

    func setShouldThrowError(_ value: Bool) {
      shouldThrowError = value
    }

    func fetch(url: URL) async throws -> Data {
      if shouldThrowError {
        #if canImport(FoundationNetworking)
          throw HTTPClientError.networkError(underlying: URLError(.notConnectedToInternet))
        #else
          throw HTTPClientError.networkError(
            underlying: NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet))
        #endif
      }

      guard let data = responses[url] else {
        throw HTTPClientError.httpError(statusCode: 404)
      }

      return data
    }
  }
#endif
