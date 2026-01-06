import Foundation
import Testing

@testable import CelestraKit

extension FeedTests {
  @Suite("Feed Computed Properties Tests")
  internal struct ComputedProperties {
    @Test("ID returns recordName when available")
    func idReturnsRecordName() async throws {
      let feed = Feed(
        recordName: "record123",
        feedURL: "https://example.com/feed.xml",
        title: "Test Feed"
      )

      #expect(feed.id == "record123")
    }

    @Test("ID returns feedURL when recordName is nil")
    func idReturnsFeedURL() async throws {
      let feed = Feed(
        recordName: nil,
        feedURL: "https://example.com/feed.xml",
        title: "Test Feed"
      )

      #expect(feed.id == "https://example.com/feed.xml")
    }

    @Test("Success rate with zero attempts returns 0.0")
    func successRateZeroAttempts() async throws {
      let feed = Feed(
        feedURL: "https://example.com/feed.xml",
        title: "Test Feed",
        totalAttempts: 0,
        successfulAttempts: 0
      )

      #expect(feed.successRate == 0.0)
    }

    @Test("Success rate with all successful attempts returns 1.0")
    func successRateAllSuccessful() async throws {
      let feed = Feed(
        feedURL: "https://example.com/feed.xml",
        title: "Test Feed",
        totalAttempts: 50,
        successfulAttempts: 50
      )

      #expect(feed.successRate == 1.0)
    }

    @Test("Success rate with partial success returns correct ratio")
    func successRatePartialSuccess() async throws {
      let feed = Feed(
        feedURL: "https://example.com/feed.xml",
        title: "Test Feed",
        totalAttempts: 100,
        successfulAttempts: 75
      )

      #expect(feed.successRate == 0.75)
    }

    @Test("isHealthy returns true when qualityScore >= 70")
    func isHealthyHighQuality() async throws {
      let feed = Feed(
        feedURL: "https://example.com/feed.xml",
        title: "Healthy Feed",
        qualityScore: 85,
        totalAttempts: 100,
        successfulAttempts: 90,
        failureCount: 2
      )

      #expect(feed.isHealthy == true)
    }

    @Test("isHealthy returns false when successRate is low")
    func isHealthyLowSuccessRate() async throws {
      let feed = Feed(
        feedURL: "https://example.com/feed.xml",
        title: "Unhealthy Feed",
        qualityScore: 85,
        totalAttempts: 100,
        successfulAttempts: 50,  // 50% success rate (< 0.8)
        failureCount: 2
      )

      #expect(feed.isHealthy == false)
    }

    @Test("isHealthy returns false when failureCount is high")
    func isHealthyHighFailures() async throws {
      let feed = Feed(
        feedURL: "https://example.com/feed.xml",
        title: "Failing Feed",
        qualityScore: 85,
        totalAttempts: 100,
        successfulAttempts: 90,
        failureCount: 5  // >= 3
      )

      #expect(feed.isHealthy == false)
    }
  }
}
