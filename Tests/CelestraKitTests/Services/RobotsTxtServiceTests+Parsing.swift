import Foundation
import Testing

@testable import CelestraKit

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension RobotsTxtServiceTests {
  @Suite("RobotsTxtService Parsing Tests", .serialized, .tags(.networkMock))
  final class Parsing {
    init() {
      mockURLProtocolSemaphore.wait()
    }

    deinit {
      MockURLProtocol.requestHandler = nil
      mockURLProtocolSemaphore.signal()
    }

    @Test("Parse robots.txt with wildcard user-agent")
    func testParseRobotsTxtWithWildcardUserAgent() async {
      let service = RobotsTxtService(userAgent: UserAgent.app(build: 1))

      let content = """
        User-agent: *
        Disallow: /api/
        Disallow: /private/
        Crawl-delay: 2
        """

      let rules = await RobotsTxtServiceTests.testParseContent(service, content: content)

      #expect(rules.disallowedPaths.count == 2)
      #expect(rules.disallowedPaths.contains("/api/"))
      #expect(rules.disallowedPaths.contains("/private/"))
      #expect(rules.crawlDelay == 2.0)
    }

    @Test("Parse robots.txt with specific user-agent")
    func testParseRobotsTxtWithSpecificUserAgent() async throws {
      let service = RobotsTxtService(userAgent: UserAgent.app(build: 1))

      let content = """
        User-agent: Googlebot
        Disallow: /google/

        User-agent: Celestra
        Disallow: /celestra/
        Crawl-delay: 5
        """

      let rules = await RobotsTxtServiceTests.testParseContent(service, content: content)

      // Should only apply Celestra rules, not Googlebot
      #expect(rules.disallowedPaths.count == 1)
      #expect(rules.disallowedPaths.contains("/celestra/"))
      #expect(!rules.disallowedPaths.contains("/google/"))
      #expect(rules.crawlDelay == 5.0)
    }

    @Test("RobotsRules isAllowed checks path prefixes")
    func testIsAllowedPathMatching() {
      let rules = RobotsRules(
        disallowedPaths: ["/api/", "/admin"],
        crawlDelay: nil,
        fetchedAt: Date()
      )

      // Disallowed paths
      #expect(!rules.isAllowed("/api/"))
      #expect(!rules.isAllowed("/api/users"))
      #expect(!rules.isAllowed("/api/v1/posts"))
      #expect(!rules.isAllowed("/admin"))
      #expect(!rules.isAllowed("/admin/settings"))

      // Allowed paths
      #expect(rules.isAllowed("/"))
      #expect(rules.isAllowed("/public"))
      #expect(rules.isAllowed("/about"))
      #expect(rules.isAllowed("/posts"))
    }

    @Test("RobotsRules allows everything when no disallow rules")
    func testIsAllowedEmptyDisallowList() {
      let rules = RobotsRules(
        disallowedPaths: [],
        crawlDelay: nil,
        fetchedAt: Date()
      )

      #expect(rules.isAllowed("/api/"))
      #expect(rules.isAllowed("/private/"))
      #expect(rules.isAllowed("/anything"))
      #expect(rules.isAllowed("/"))
    }

    @Test("Parse robots.txt handles empty and comment lines")
    func testParseRobotsTxtWithCommentsAndEmptyLines() async {
      let service = RobotsTxtService(userAgent: UserAgent.app(build: 1))

      let content = """
        # This is a comment
        User-agent: *

        # Another comment
        Disallow: /test/

        # Empty lines above and below

        """

      let rules = await RobotsTxtServiceTests.testParseContent(service, content: content)

      #expect(rules.disallowedPaths.count == 1)
      #expect(rules.disallowedPaths.contains("/test/"))
    }

    @Test("Parse robots.txt handles case-insensitive directives")
    func testParseRobotsTxtCaseInsensitive() async {
      let service = RobotsTxtService(userAgent: UserAgent.app(build: 1))

      let content = """
        USER-AGENT: *
        DISALLOW: /api/
        Crawl-Delay: 3
        """

      let rules = await RobotsTxtServiceTests.testParseContent(service, content: content)

      #expect(rules.disallowedPaths.count == 1)
      #expect(rules.disallowedPaths.contains("/api/"))
      #expect(rules.crawlDelay == 3.0)
    }

    @Test("Parse robots.txt with multiple user-agents using wildcard")
    func testParseRobotsTxtMultipleUserAgents() async {
      let service = RobotsTxtService(userAgent: UserAgent.app(build: 1))

      let content = """
        User-agent: Googlebot
        Disallow: /google-only/

        User-agent: *
        Disallow: /all/
        Crawl-delay: 2

        User-agent: BadBot
        Disallow: /
        """

      let rules = await RobotsTxtServiceTests.testParseContent(service, content: content)

      // Should match the wildcard (*) section
      #expect(rules.disallowedPaths.contains("/all/"))
      #expect(rules.crawlDelay == 2.0)
    }
  }
}
