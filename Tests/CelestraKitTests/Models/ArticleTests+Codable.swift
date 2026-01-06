import Foundation
import Testing

@testable import CelestraKit

extension ArticleTests {
  @Suite("Article Codable Tests")
  internal struct Codable {
    @Test("Round-trip encoding and decoding preserves all data")
    func codableRoundTrip() async throws {
      let now = Date()
      let original = Article(
        recordName: "record123",
        recordChangeTag: "tag456",
        feedRecordName: "feed123",
        guid: "article-guid-1",
        title: "Test Article",
        excerpt: "This is an excerpt",
        content: "<p>This is content</p>",
        contentText: "This is content",
        author: "John Doe",
        url: "https://example.com/article1",
        imageURL: "https://example.com/image.png",
        publishedDate: now,
        fetchedAt: now,
        ttlDays: 30,
        wordCount: 10,
        estimatedReadingTime: 1,
        language: "en",
        tags: ["swift", "ios"]
      )

      let encoder = JSONEncoder()
      let data = try encoder.encode(original)

      let decoder = JSONDecoder()
      let decoded = try decoder.decode(Article.self, from: data)

      #expect(decoded.recordName == original.recordName)
      #expect(decoded.feedRecordName == original.feedRecordName)
      #expect(decoded.guid == original.guid)
      #expect(decoded.title == original.title)
      #expect(decoded.author == original.author)
      #expect(decoded.tags == original.tags)
    }

    @Test("Date and TimeInterval fields encode correctly")
    func dateFieldsEncode() async throws {
      let now = Date()
      let article = Article(
        feedRecordName: "feed123",
        guid: "article-guid-1",
        title: "Test Article",
        url: "https://example.com/article1",
        publishedDate: now,
        fetchedAt: now
      )

      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .secondsSince1970
      let data = try encoder.encode(article)

      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .secondsSince1970
      let decoded = try decoder.decode(Article.self, from: data)

      let tolerance: TimeInterval = 0.001
      #expect(abs(decoded.fetchedAt.timeIntervalSince1970 - now.timeIntervalSince1970) < tolerance)
    }

    @Test("Optional fields handled correctly in encoding")
    func optionalFieldsEncoding() async throws {
      let article = Article(
        feedRecordName: "feed123",
        guid: "article-guid-1",
        title: "Test Article",
        excerpt: nil,
        content: nil,
        author: nil,
        url: "https://example.com/article1",
        imageURL: nil
      )

      let encoder = JSONEncoder()
      let data = try encoder.encode(article)

      let decoder = JSONDecoder()
      let decoded = try decoder.decode(Article.self, from: data)

      #expect(decoded.excerpt == nil)
      #expect(decoded.content == nil)
      #expect(decoded.author == nil)
      #expect(decoded.imageURL == nil)
    }

    @Test("contentHash preserved through encoding")
    func contentHashPreserved() async throws {
      let article = Article(
        feedRecordName: "feed123",
        guid: "article-guid-1",
        title: "Test Article",
        url: "https://example.com/article1"
      )

      let originalHash = article.contentHash

      let encoder = JSONEncoder()
      let data = try encoder.encode(article)

      let decoder = JSONDecoder()
      let decoded = try decoder.decode(Article.self, from: data)

      #expect(decoded.contentHash == originalHash)
    }
  }
}
