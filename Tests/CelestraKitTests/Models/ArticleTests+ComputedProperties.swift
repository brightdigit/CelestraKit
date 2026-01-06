import Foundation
import Testing

@testable import CelestraKit

extension ArticleTests {
  @Suite("Article Computed Properties Tests")
  internal struct ComputedProperties {
    @Test("ID composition from recordName and guid when recordName exists")
    func idWithRecordName() async throws {
      let article = Article(
        recordName: "record123",
        feedRecordName: "feed123",
        guid: "article-guid-1",
        title: "Test Article",
        url: "https://example.com/article1"
      )

      #expect(article.id == "record123")
    }

    @Test("ID composition from feedRecordName and guid when recordName is nil")
    func idWithoutRecordName() async throws {
      let article = Article(
        recordName: nil,
        feedRecordName: "feed123",
        guid: "article-guid-1",
        title: "Test Article",
        url: "https://example.com/article1"
      )

      #expect(article.id == "feed123:article-guid-1")
    }

    @Test("isExpired returns true for past expiresAt")
    func isExpiredPastDate() async throws {
      let pastDate = Date().addingTimeInterval(-3_600)  // 1 hour ago
      let article = Article(
        feedRecordName: "feed123",
        guid: "article-guid-1",
        title: "Test Article",
        url: "https://example.com/article1",
        fetchedAt: pastDate,
        ttlDays: 0
      )

      #expect(article.isExpired == true)
    }

    @Test("isExpired returns false for future expiresAt")
    func isExpiredFutureDate() async throws {
      let now = Date()
      let article = Article(
        feedRecordName: "feed123",
        guid: "article-guid-1",
        title: "Test Article",
        url: "https://example.com/article1",
        fetchedAt: now,
        ttlDays: 30
      )

      #expect(article.isExpired == false)
    }

    @Test("isExpired boundary test")
    func isExpiredBoundary() async throws {
      let now = Date()
      // Set expiration to exactly now (technically expired)
      let article = Article(
        feedRecordName: "feed123",
        guid: "article-guid-1",
        title: "Test Article",
        url: "https://example.com/article1",
        fetchedAt: now.addingTimeInterval(-TimeInterval(30 * 24 * 60 * 60)),
        ttlDays: 30
      )

      // Should be expired or very close to expiration
      let tolerance: TimeInterval = 60
      let timeUntilExpiration = article.expiresAt.timeIntervalSince(Date())
      #expect(abs(timeUntilExpiration) < tolerance)
    }
  }
}
