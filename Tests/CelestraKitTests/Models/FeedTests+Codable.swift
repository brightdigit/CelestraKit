import Foundation
import Testing

@testable import CelestraKit

extension FeedTests {
  @Suite("Feed Codable Tests")
  internal struct Codable {
    @Test("Encode and decode round-trip preserves all data")
    func codableRoundTrip() async throws {
      let now = Date()
      let original = Feed(
        recordName: "record123",
        recordChangeTag: "tag456",
        feedURL: "https://example.com/feed.xml",
        title: "Test Feed",
        description: "A test feed",
        category: "tech",
        imageURL: "https://example.com/image.png",
        siteURL: "https://example.com",
        language: "en",
        isFeatured: true,
        isVerified: true,
        qualityScore: 90,
        subscriberCount: 500,
        addedAt: now,
        lastVerified: now,
        updateFrequency: 3_600,
        tags: ["swift", "ios"],
        totalAttempts: 50,
        successfulAttempts: 45,
        lastAttempted: now,
        isActive: true,
        etag: "etag123",
        lastModified: "Mon, 01 Jan 2024 00:00:00 GMT",
        failureCount: 2,
        lastFailureReason: "Timeout",
        minUpdateInterval: 1_800
      )

      let encoder = JSONEncoder()
      let data = try encoder.encode(original)

      let decoder = JSONDecoder()
      let decoded = try decoder.decode(Feed.self, from: data)

      #expect(decoded.recordName == original.recordName)
      #expect(decoded.feedURL == original.feedURL)
      #expect(decoded.title == original.title)
      #expect(decoded.qualityScore == original.qualityScore)
      #expect(decoded.tags == original.tags)
    }

    @Test("Decode with missing optional fields succeeds")
    func decodeMissingOptionals() async throws {
      let json = """
        {
          "feedURL": "https://example.com/feed.xml",
          "title": "Minimal Feed",
          "isFeatured": false,
          "isVerified": false,
          "qualityScore": 50,
          "subscriberCount": 0,
          "addedAt": \(Date().timeIntervalSinceReferenceDate),
          "tags": [],
          "totalAttempts": 0,
          "successfulAttempts": 0,
          "isActive": true,
          "failureCount": 0
        }
        """

      let data = Data(json.utf8)
      let decoder = JSONDecoder()
      let feed = try decoder.decode(Feed.self, from: data)

      #expect(feed.feedURL == "https://example.com/feed.xml")
      #expect(feed.title == "Minimal Feed")
      #expect(feed.recordName == nil)
      #expect(feed.description == nil)
    }

    @Test("Encode includes all required fields")
    func encodeIncludesRequiredFields() async throws {
      let feed = Feed(
        feedURL: "https://example.com/feed.xml",
        title: "Test Feed"
      )

      let encoder = JSONEncoder()
      let data = try encoder.encode(feed)
      let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

      #expect(json?["feedURL"] as? String == "https://example.com/feed.xml")
      #expect(json?["title"] as? String == "Test Feed")
      #expect(json?["qualityScore"] as? Int == 50)
      #expect(json?["isActive"] as? Bool == true)
    }

    @Test("Date fields encode and decode correctly")
    func dateFieldsEncodeDecodeCorrectly() async throws {
      let now = Date()
      let feed = Feed(
        feedURL: "https://example.com/feed.xml",
        title: "Test Feed",
        addedAt: now,
        lastVerified: now,
        lastAttempted: now
      )

      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .secondsSince1970

      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .secondsSince1970

      let data = try encoder.encode(feed)
      let decoded = try decoder.decode(Feed.self, from: data)

      let tolerance: TimeInterval = 0.001
      #expect(abs(decoded.addedAt.timeIntervalSince1970 - now.timeIntervalSince1970) < tolerance)
    }
  }
}
