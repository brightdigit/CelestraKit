import Foundation
import Testing

@testable import CelestraKit

extension FeedTests {
  @Suite("Feed Initialization Tests")
  internal struct Initialization {
    @Test("Initialize with minimal parameters")
    func initializeMinimal() async throws {
      let feed = Feed(
        feedURL: "https://example.com/feed.xml",
        title: "Example Feed"
      )

      #expect(feed.feedURL == "https://example.com/feed.xml")
      #expect(feed.title == "Example Feed")
      #expect(feed.description == nil)
      #expect(feed.category == nil)
      #expect(feed.isFeatured == false)
      #expect(feed.isVerified == false)
      #expect(feed.qualityScore == 50)
      #expect(feed.subscriberCount == 0)
      #expect(feed.tags.isEmpty)
      #expect(feed.totalAttempts == 0)
      #expect(feed.successfulAttempts == 0)
      #expect(feed.isActive == true)
    }

    @Test("Initialize with all parameters")
    func initializeComplete() async throws {
      let now = Date()
      let feed = Feed(
        recordName: "record123",
        recordChangeTag: "tag456",
        feedURL: "https://example.com/feed.xml",
        title: "Complete Feed",
        description: "A fully featured feed",
        category: "technology",
        imageURL: "https://example.com/image.png",
        siteURL: "https://example.com",
        language: "en",
        isFeatured: true,
        isVerified: true,
        qualityScore: 95,
        subscriberCount: 1_000,
        addedAt: now,
        lastVerified: now,
        updateFrequency: 3_600,
        tags: ["swift", "ios", "programming"],
        totalAttempts: 100,
        successfulAttempts: 95,
        lastAttempted: now,
        isActive: true,
        etag: "etag123",
        lastModified: "Mon, 01 Jan 2024 00:00:00 GMT",
        failureCount: 5,
        lastFailureReason: "Timeout",
        minUpdateInterval: 1_800
      )

      #expect(feed.recordName == "record123")
      #expect(feed.recordChangeTag == "tag456")
      #expect(feed.description == "A fully featured feed")
      #expect(feed.category == "technology")
      #expect(feed.isFeatured == true)
      #expect(feed.isVerified == true)
      #expect(feed.qualityScore == 95)
      #expect(feed.subscriberCount == 1_000)
      #expect(feed.tags.count == 3)
      #expect(feed.totalAttempts == 100)
      #expect(feed.successfulAttempts == 95)
    }

    @Test("Initialize with nil optional fields")
    func initializeWithNils() async throws {
      let feed = Feed(
        feedURL: "https://example.com/feed.xml",
        title: "Feed with Nils",
        description: nil,
        category: nil,
        imageURL: nil,
        siteURL: nil,
        language: nil,
        lastVerified: nil,
        updateFrequency: nil,
        lastAttempted: nil,
        etag: nil,
        lastModified: nil,
        lastFailureReason: nil,
        minUpdateInterval: nil
      )

      #expect(feed.description == nil)
      #expect(feed.category == nil)
      #expect(feed.lastVerified == nil)
      #expect(feed.etag == nil)
      #expect(feed.lastModified == nil)
    }

    @Test("Initialize with empty arrays and strings")
    func initializeWithEmptyValues() async throws {
      let feed = Feed(
        feedURL: "",
        title: "",
        tags: []
      )

      #expect(feed.feedURL.isEmpty)
      #expect(feed.title.isEmpty)
      #expect(feed.tags.isEmpty)
    }

    @Test("Initialize with boundary quality score values")
    func initializeBoundaryValues() async throws {
      let feed1 = Feed(
        feedURL: "https://example.com/feed1.xml",
        title: "Feed 1",
        qualityScore: 0
      )
      #expect(feed1.qualityScore == 0)

      let feed2 = Feed(
        feedURL: "https://example.com/feed2.xml",
        title: "Feed 2",
        qualityScore: 100
      )
      #expect(feed2.qualityScore == 100)
    }
  }
}
