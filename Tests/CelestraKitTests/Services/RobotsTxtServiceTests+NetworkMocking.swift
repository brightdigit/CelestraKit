import Foundation
import Testing

@testable import CelestraKit

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension RobotsTxtServiceTests {
  @Suite("RobotsTxtService Network Mocking Tests", .serialized, .tags(.networkMock))
  final class NetworkMocking {
    init() {
      mockURLProtocolSemaphore.wait()
    }

    deinit {
      MockURLProtocol.requestHandler = nil
      mockURLProtocolSemaphore.signal()
    }

    @Test("Network request uses injected URLSession")
    func testUsesInjectedURLSession() async throws {
      let robotsURL = URL(string: "https://example.com/robots.txt")!
      let robotsContent = """
        User-agent: *
        Disallow: /api/
        Crawl-delay: 2
        """

      var requestCaptured = false
      MockURLProtocol.requestHandler = { request in
        // Only handle robots.txt requests for this test
        guard request.url?.absoluteString == "https://example.com/robots.txt" else {
          // Return 404 for other URLs (from other test suites)
          let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
          )!
          return (response, nil)
        }

        requestCaptured = true

        let response = HTTPURLResponse(
          url: robotsURL,
          statusCode: 200,
          httpVersion: nil,
          headerFields: ["Content-Type": "text/plain"]
        )!
        return (response, robotsContent.data(using: .utf8))
      }

      let session = createMockURLSession()
      let service = RobotsTxtService(urlSession: session, userAgent: UserAgent.cloud(build: 1))

      let testURL = URL(string: "https://example.com/test/page")!
      let allowed = try await service.isAllowed(testURL)

      #expect(requestCaptured == true)
      #expect(allowed == true)  // /test/page is not in disallowed list
    }

    @Test("Allow everything when robots.txt returns 404")
    func testRobotsTxtNotFound() async throws {
      MockURLProtocol.requestHandler = { request in
        // Handle all URLs - return 404 for robots.txt to simulate not found
        let response = HTTPURLResponse(
          url: request.url!,
          statusCode: 404,
          httpVersion: nil,
          headerFields: nil
        )!
        return (response, nil)
      }

      let session = createMockURLSession()
      let service = RobotsTxtService(urlSession: session, userAgent: UserAgent.cloud(build: 1))

      let testURL = URL(string: "https://example.com/test/page")!
      let allowed = try await service.isAllowed(testURL)

      #expect(allowed == true)  // Should allow when robots.txt not found
    }

    @Test("Allow everything on network error (fail open)")
    func testNetworkErrorFailsOpen() async throws {
      MockURLProtocol.requestHandler = { _ in
        throw URLError(.notConnectedToInternet)
      }

      let session = createMockURLSession()
      let service = RobotsTxtService(urlSession: session, userAgent: UserAgent.cloud(build: 1))

      let testURL = URL(string: "https://example.com/test/page")!
      let allowed = try await service.isAllowed(testURL)

      #expect(allowed == true)  // Should fail open on network error
    }

    @Test("Respect disallow rules from robots.txt")
    func testRespectsDisallowRules() async throws {
      let robotsURL = URL(string: "https://example.com/robots.txt")!
      let robotsContent = """
        User-agent: *
        Disallow: /api/
        Disallow: /private/
        """

      MockURLProtocol.requestHandler = { request in
        // Only handle robots.txt requests for this test
        guard request.url?.absoluteString == "https://example.com/robots.txt" else {
          // Return 404 for other URLs
          let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
          )!
          return (response, nil)
        }

        let response = HTTPURLResponse(
          url: robotsURL,
          statusCode: 200,
          httpVersion: nil,
          headerFields: ["Content-Type": "text/plain"]
        )!
        return (response, robotsContent.data(using: .utf8))
      }

      let session = createMockURLSession()
      let service = RobotsTxtService(urlSession: session, userAgent: UserAgent.cloud(build: 1))

      // Test disallowed paths
      let apiURL = URL(string: "https://example.com/api/users")!
      let apiAllowed = try await service.isAllowed(apiURL)
      #expect(apiAllowed == false)

      let privateURL = URL(string: "https://example.com/private/data")!
      let privateAllowed = try await service.isAllowed(privateURL)
      #expect(privateAllowed == false)

      // Test allowed path
      let publicURL = URL(string: "https://example.com/about")!
      let publicAllowed = try await service.isAllowed(publicURL)
      #expect(publicAllowed == true)
    }

    @Test("Parse and return crawl delay from robots.txt")
    func testParseCrawlDelay() async throws {
      let robotsURL = URL(string: "https://example.com/robots.txt")!
      let robotsContent = """
        User-agent: *
        Disallow: /api/
        Crawl-delay: 5
        """

      MockURLProtocol.requestHandler = { request in
        // Only handle robots.txt requests for this test
        guard request.url?.absoluteString == "https://example.com/robots.txt" else {
          // Return 404 for other URLs
          let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
          )!
          return (response, nil)
        }

        let response = HTTPURLResponse(
          url: robotsURL,
          statusCode: 200,
          httpVersion: nil,
          headerFields: ["Content-Type": "text/plain"]
        )!
        return (response, robotsContent.data(using: .utf8))
      }

      let session = createMockURLSession()
      let service = RobotsTxtService(urlSession: session, userAgent: UserAgent.cloud(build: 1))

      let testURL = URL(string: "https://example.com/test")!
      let delay = try await service.getCrawlDelay(for: testURL)

      #expect(delay == 5.0)
    }

    @Test("Cache robots.txt and avoid duplicate requests")
    func testCachingBehavior() async throws {
      let robotsURL = URL(string: "https://example.com/robots.txt")!
      let robotsContent = """
        User-agent: *
        Disallow: /api/
        """

      var requestCount = 0
      MockURLProtocol.requestHandler = { request in
        // Only handle robots.txt requests for this test
        guard request.url?.absoluteString == "https://example.com/robots.txt" else {
          // Return 404 for other URLs
          let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
          )!
          return (response, nil)
        }

        requestCount += 1
        let response = HTTPURLResponse(
          url: robotsURL,
          statusCode: 200,
          httpVersion: nil,
          headerFields: ["Content-Type": "text/plain"]
        )!
        return (response, robotsContent.data(using: .utf8))
      }

      let session = createMockURLSession()
      let service = RobotsTxtService(urlSession: session, userAgent: UserAgent.cloud(build: 1))

      // First request should fetch robots.txt
      let url1 = URL(string: "https://example.com/page1")!
      _ = try await service.isAllowed(url1)
      #expect(requestCount == 1)

      // Second request to same domain should use cache
      let url2 = URL(string: "https://example.com/page2")!
      _ = try await service.isAllowed(url2)
      #expect(requestCount == 1)  // Still 1, cached

      // Clear cache and verify new request is made
      await service.clearCache()
      let url3 = URL(string: "https://example.com/page3")!
      _ = try await service.isAllowed(url3)
      #expect(requestCount == 2)  // New request made
    }
  }
}
