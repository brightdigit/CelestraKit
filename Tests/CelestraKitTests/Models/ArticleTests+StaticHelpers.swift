import Foundation
import Testing

@testable import CelestraKit

extension ArticleTests {
  @Suite("Article Static Helper Method Tests")
  internal struct StaticHelpers {
    @Test("calculateContentHash produces consistent hash for same inputs")
    func contentHashConsistency() async throws {
      let hash1 = Article.calculateContentHash(
        title: "Test Article",
        url: "https://example.com/article1",
        guid: "guid123"
      )

      let hash2 = Article.calculateContentHash(
        title: "Test Article",
        url: "https://example.com/article1",
        guid: "guid123"
      )

      #expect(hash1 == hash2)
    }

    @Test("calculateContentHash produces different hash for different inputs")
    func contentHashDifferentInputs() async throws {
      let hash1 = Article.calculateContentHash(
        title: "Test Article 1",
        url: "https://example.com/article1",
        guid: "guid123"
      )

      let hash2 = Article.calculateContentHash(
        title: "Test Article 2",
        url: "https://example.com/article2",
        guid: "guid456"
      )

      #expect(hash1 != hash2)
    }

    @Test("calculateContentHash handles empty strings")
    func contentHashEmptyStrings() async throws {
      let hash = Article.calculateContentHash(
        title: "",
        url: "",
        guid: ""
      )

      #expect(!hash.isEmpty)
      #expect(hash == "||")  // Composite key with empty components
    }

    @Test("extractPlainText removes HTML tags")
    func extractPlainTextRemoveTags() async throws {
      let html = "<div><p>This is <strong>bold</strong> and <em>italic</em> text</p></div>"
      let plainText = Article.extractPlainText(from: html)

      #expect(plainText?.contains("<") == false)
      #expect(plainText?.contains(">") == false)
      #expect(plainText?.contains("bold") == true)
      #expect(plainText?.contains("italic") == true)
    }

    @Test("extractPlainText decodes HTML entities")
    func extractPlainTextDecodeEntities() async throws {
      let html = "Test&nbsp;&amp;&lt;&gt;&quot;"
      let plainText = Article.extractPlainText(from: html)

      #expect(plainText?.contains("&") == true)
      #expect(plainText?.contains("<") == true)
      #expect(plainText?.contains(">") == true)
      #expect(plainText?.contains("\"") == true)
      #expect(plainText?.contains("&nbsp;") == false)
      #expect(plainText?.contains("&amp;") == false)
    }

    @Test("extractPlainText handles nested HTML")
    func extractPlainTextNestedHTML() async throws {
      let html = "<div><article><h1>Title</h1><p>Paragraph</p></article></div>"
      let plainText = Article.extractPlainText(from: html)

      #expect(plainText?.contains("<") == false)
      #expect(plainText?.contains("Title") == true)
      #expect(plainText?.contains("Paragraph") == true)
    }

    @Test("extractPlainText returns nil for nil input")
    func extractPlainTextNilInput() async throws {
      let plainText = Article.extractPlainText(from: nil)
      #expect(plainText == nil)
    }

    @Test("calculateWordCount accurate for normal text")
    func calculateWordCountNormalText() async throws {
      let text = "This is a simple test with seven words"
      let count = Article.calculateWordCount(from: text)

      #expect(count == 8)  // 8 words
    }

    @Test("calculateWordCount handles multiple spaces")
    func calculateWordCountMultipleSpaces() async throws {
      let text = "Words   with    multiple     spaces"
      let count = Article.calculateWordCount(from: text)

      #expect(count == 4)
    }

    @Test("calculateWordCount returns nil for nil input")
    func calculateWordCountNilInput() async throws {
      let count = Article.calculateWordCount(from: nil)
      #expect(count == nil)
    }

    @Test("estimateReadingTime assumes 200 words per minute")
    func estimateReadingTime200WPM() async throws {
      let time = Article.estimateReadingTime(wordCount: 200)
      #expect(time == 1)

      let time2 = Article.estimateReadingTime(wordCount: 400)
      #expect(time2 == 2)

      let time3 = Article.estimateReadingTime(wordCount: 1_000)
      #expect(time3 == 5)
    }

    @Test("estimateReadingTime returns minimum 1 minute")
    func estimateReadingTimeMinimum() async throws {
      let time = Article.estimateReadingTime(wordCount: 50)
      #expect(time == 1)  // Less than 200 words still returns 1 minute
    }

    @Test("estimateReadingTime returns nil for nil or zero input")
    func estimateReadingTimeNilZero() async throws {
      #expect(Article.estimateReadingTime(wordCount: nil) == nil)
      #expect(Article.estimateReadingTime(wordCount: 0) == nil)
    }
  }
}
