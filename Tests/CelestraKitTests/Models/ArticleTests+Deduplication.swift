import Foundation
import Testing

@testable import CelestraKit

extension ArticleTests {
  @Suite("Article Deduplication Tests")
  internal struct Deduplication {
    @Test("isDuplicate returns true for same contentHash")
    func isDuplicateSameHash() async throws {
      let article1 = Article(
        feedRecordName: "feed123",
        guid: "article-guid-1",
        title: "Same Article",
        url: "https://example.com/article1"
      )

      let article2 = Article(
        feedRecordName: "feed456",
        guid: "article-guid-1",
        title: "Same Article",
        url: "https://example.com/article1"
      )

      #expect(article1.isDuplicate(of: article2) == true)
    }

    @Test("isDuplicate returns false for different contentHash")
    func isDuplicateDifferentHash() async throws {
      let article1 = Article(
        feedRecordName: "feed123",
        guid: "article-guid-1",
        title: "Article 1",
        url: "https://example.com/article1"
      )

      let article2 = Article(
        feedRecordName: "feed123",
        guid: "article-guid-2",
        title: "Article 2",
        url: "https://example.com/article2"
      )

      #expect(article1.isDuplicate(of: article2) == false)
    }

    @Test("isDuplicate with same title but different URLs")
    func isDuplicateSameTitleDifferentURL() async throws {
      let article1 = Article(
        feedRecordName: "feed123",
        guid: "article-guid-1",
        title: "Same Title",
        url: "https://example.com/article1"
      )

      let article2 = Article(
        feedRecordName: "feed123",
        guid: "article-guid-1",
        title: "Same Title",
        url: "https://example.com/article2"
      )

      #expect(article1.isDuplicate(of: article2) == false)
    }
  }
}
