import Foundation
import Testing

@testable import CelestraKit

extension FeedTests {
  @Suite("Feed Edge Cases Tests")
  internal struct EdgeCases {
    @Test("Very large attempt counts")
    func veryLargeAttemptCounts() async throws {
      let feed = Feed(
        feedURL: "https://example.com/feed.xml",
        title: "High Volume Feed",
        totalAttempts: Int64.max,
        successfulAttempts: Int64.max - 100
      )

      #expect(feed.totalAttempts == Int64.max)
      #expect(feed.successfulAttempts == Int64.max - 100)
      #expect(feed.successRate > 0.99)
    }

    @Test("Success rate calculation precision")
    func successRatePrecision() async throws {
      let feed = Feed(
        feedURL: "https://example.com/feed.xml",
        title: "Test Feed",
        totalAttempts: 3,
        successfulAttempts: 1
      )

      let expectedRate = 1.0 / 3.0
      #expect(abs(feed.successRate - expectedRate) < 0.0001)
    }
  }
}
