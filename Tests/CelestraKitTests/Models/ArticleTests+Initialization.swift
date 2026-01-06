import Foundation
import Testing

@testable import CelestraKit

extension ArticleTests {
  @Suite("Article Initialization Tests")
  internal struct Initialization {
    @Test("Initialize with default TTL (30 days)")
    func initializeDefaultTTL() async throws {
      let now = Date()
      let article = Article(
        feedRecordName: "feed123",
        guid: "article-guid-1",
        title: "Test Article",
        url: "https://example.com/article1"
      )

      let expectedExpiration = now.addingTimeInterval(TimeInterval(30 * 24 * 60 * 60))
      let tolerance: TimeInterval = 60  // 1 minute tolerance

      #expect(abs(article.expiresAt.timeIntervalSince(expectedExpiration)) < tolerance)
    }

    @Test("Initialize with custom TTL")
    func initializeCustomTTL() async throws {
      let now = Date()
      let article = Article(
        feedRecordName: "feed123",
        guid: "article-guid-1",
        title: "Test Article",
        url: "https://example.com/article1",
        fetchedAt: now,
        ttlDays: 7
      )

      let expectedExpiration = now.addingTimeInterval(TimeInterval(7 * 24 * 60 * 60))
      let tolerance: TimeInterval = 60

      #expect(abs(article.expiresAt.timeIntervalSince(expectedExpiration)) < tolerance)
    }

    @Test("Initialize with automatic contentText extraction")
    func initializeContentTextExtraction() async throws {
      let htmlContent = "<p>This is <strong>HTML</strong> content</p>"
      let article = Article(
        feedRecordName: "feed123",
        guid: "article-guid-1",
        title: "Test Article",
        content: htmlContent,
        url: "https://example.com/article1"
      )

      #expect(article.contentText != nil)
      #expect(article.contentText?.contains("<") == false)
      #expect(article.contentText?.contains("HTML") == true)
    }

    @Test("Initialize with automatic wordCount calculation")
    func initializeWordCount() async throws {
      let content = "This is a test article with nine words here"
      let article = Article(
        feedRecordName: "feed123",
        guid: "article-guid-1",
        title: "Test Article",
        contentText: content,
        url: "https://example.com/article1"
      )

      #expect(article.wordCount == 9)
    }

    @Test("Initialize with automatic estimatedReadingTime")
    func initializeReadingTime() async throws {
      // 400 words at 200 wpm = 2 minutes
      let words = Array(repeating: "word", count: 400).joined(separator: " ")
      let article = Article(
        feedRecordName: "feed123",
        guid: "article-guid-1",
        title: "Test Article",
        contentText: words,
        url: "https://example.com/article1"
      )

      #expect(article.wordCount == 400)
      #expect(article.estimatedReadingTime == 2)
    }

    @Test("Initialize with nil optional fields")
    func initializeWithNils() async throws {
      let article = Article(
        recordName: nil,
        recordChangeTag: nil,
        feedRecordName: "feed123",
        guid: "article-guid-1",
        title: "Test Article",
        excerpt: nil,
        content: nil,
        contentText: nil,
        author: nil,
        url: "https://example.com/article1",
        imageURL: nil,
        publishedDate: nil,
        wordCount: nil,
        estimatedReadingTime: nil,
        language: nil,
        tags: []
      )

      #expect(article.recordName == nil)
      #expect(article.excerpt == nil)
      #expect(article.content == nil)
      #expect(article.author == nil)
      #expect(article.imageURL == nil)
    }
  }
}
