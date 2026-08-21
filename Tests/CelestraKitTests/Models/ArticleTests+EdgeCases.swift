import Foundation
import Testing

@testable import CelestraKit

extension ArticleTests {
  @Suite("Article Edge Cases Tests")
  internal struct EdgeCases {
    @Test("Very long content handling")
    internal func veryLongContent() async throws {
      let longContent = String(repeating: "word ", count: 10_000)
      let article = Article(
        feedRecordName: "feed123",
        guid: "article-guid-1",
        title: "Long Article",
        contentText: longContent,
        url: "https://example.com/article1"
      )

      #expect(article.wordCount == 10_000)
      #expect(article.estimatedReadingTime == 50)  // 10000 / 200 = 50 minutes
    }

    @Test("Special characters in content hash")
    internal func specialCharactersInHash() async throws {
      let hash = Article.calculateContentHash(
        title: "Title with émojis 🚀 and ñ",
        url: "https://example.com/article?param=value&other=test",
        guid: "guid-with-special-chars-123!@#"
      )

      #expect(!hash.isEmpty)
      #expect(hash.contains("|"))  // Contains separator
      #expect(hash.contains("🚀"))  // Preserves emojis
    }

    @Test("Empty content text extraction")
    internal func emptyContentExtraction() async throws {
      let article = Article(
        feedRecordName: "feed123",
        guid: "article-guid-1",
        title: "Test Article",
        content: "",
        url: "https://example.com/article1"
      )

      #expect(article.contentText?.isEmpty == true || article.contentText == nil)
    }
  }
}
