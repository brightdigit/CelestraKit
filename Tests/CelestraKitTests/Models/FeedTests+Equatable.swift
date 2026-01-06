import Foundation
import Testing

@testable import CelestraKit

extension FeedTests {
  @Suite("Feed Hashable/Equatable Tests")
  internal struct Equatable {
    @Test("Equal feeds have same hash")
    func equalFeedsSameHash() async throws {
      let now = Date()
      let feed1 = Feed(
        feedURL: "https://example.com/feed.xml",
        title: "Test Feed",
        addedAt: now
      )

      let feed2 = Feed(
        feedURL: "https://example.com/feed.xml",
        title: "Test Feed",
        addedAt: now
      )

      #expect(feed1.hashValue == feed2.hashValue)
    }

    @Test("Different feeds have different hash values")
    func differentFeedsDifferentHash() async throws {
      let feed1 = Feed(
        feedURL: "https://example.com/feed1.xml",
        title: "Feed 1"
      )

      let feed2 = Feed(
        feedURL: "https://example.com/feed2.xml",
        title: "Feed 2"
      )

      #expect(feed1.hashValue != feed2.hashValue)
    }

    @Test("Feeds with same feedURL but different data are not equal")
    func sameFeedURLDifferentData() async throws {
      let feed1 = Feed(
        feedURL: "https://example.com/feed.xml",
        title: "Feed 1"
      )

      let feed2 = Feed(
        feedURL: "https://example.com/feed.xml",
        title: "Feed 2"
      )

      #expect(feed1 != feed2)
    }
  }
}
