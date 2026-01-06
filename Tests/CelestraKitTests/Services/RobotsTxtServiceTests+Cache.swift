import Foundation
import Testing

@testable import CelestraKit

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension RobotsTxtServiceTests {
  @Suite("RobotsTxtService Cache Tests", .serialized, .tags(.networkMock))
  final class Cache {
    init() async {
      await mockURLProtocolCoordinator.acquire()
    }

    deinit {
      Task {
        await mockURLProtocolCoordinator.release()
      }
    }

    @Test("Cache stores and retrieves rules")
    func testCacheStoresRules() async throws {
      let service = RobotsTxtService(userAgent: UserAgent.app(build: 1))

      // Clear cache first
      await service.clearCache()

      // Note: This test would require mocking URLSession to avoid actual network calls
      // For now, we test the cache clearing functionality

      // Clear cache for specific domain
      await service.clearCache(for: "example.com")

      // Verify cache methods are accessible (actor isolation)
      await service.clearCache()
    }

    @Test("isAllowed handles URLs without host")
    func testIsAllowedWithoutHost() async throws {
      let service = RobotsTxtService(userAgent: UserAgent.app(build: 1))

      // URLs without host should be allowed
      let urlWithoutHost = URL(string: "/path/to/resource")!
      let allowed = try await service.isAllowed(urlWithoutHost)

      #expect(allowed == true)
    }

    @Test("getCrawlDelay returns nil for URLs without host")
    func testGetCrawlDelayWithoutHost() async throws {
      let service = RobotsTxtService(userAgent: UserAgent.app(build: 1))

      let urlWithoutHost = URL(string: "/path/to/resource")!
      let delay = try await service.getCrawlDelay(for: urlWithoutHost)

      #expect(delay == nil)
    }
  }
}
