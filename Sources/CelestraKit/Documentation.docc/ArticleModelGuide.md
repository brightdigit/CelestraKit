# Article Model Guide

Complete guide to working with ``Article`` models and content caching.

## Overview

The ``Article`` struct represents cached RSS articles in CloudKit's public database, providing content, metadata, and automatic expiration management.

## Article Structure

### Core Properties

```swift
let article = Article(
    feedRecordName: "tech-feed-001",     // Parent feed reference
    guid: "article-2024-001",            // Unique ID within feed
    title: "Introduction to Swift 6",    // Article title
    excerpt: "Brief summary here",       // Summary/description
    content: "<p>Full HTML content</p>", // Full article HTML
    author: "Jane Smith",                // Author name
    url: "https://example.com/article",  // Article URL
    publishedDate: Date(),               // Publication date
    ttlDays: 30                          // Cache for 30 days
)
```

### Automatic Processing

Articles automatically compute several properties:

```swift
// Plain text extracted from HTML
print(article.contentText ?? "")

// Word count calculated from plain text
print("Words: \(article.wordCount ?? 0)")

// Reading time estimated at 200 wpm
print("Reading time: \(article.estimatedReadingTime ?? 0) min")

// Content hash for deduplication
print("Hash: \(article.contentHash)")
```

## Content Deduplication

### Content Hash Calculation

Articles use a **composite key** for deduplication:

```swift
public static func calculateContentHash(
    title: String,
    url: String,
    guid: String
) -> String {
    "\(title)|\(url)|\(guid)"
}
```

**Why composite key?**
- Same article from different feeds has different guid
- Different articles with same title are distinguished by URL
- Handles edge cases like updated articles

### Detecting Duplicates

```swift
let article1 = Article(
    feedRecordName: "feed-1",
    guid: "123",
    title: "Swift 6 Released",
    url: "https://example.com/swift-6",
    // ...
)

let article2 = Article(
    feedRecordName: "feed-2",
    guid: "456",
    title: "Swift 6 Released",
    url: "https://example.com/swift-6",
    // ...
)

// Check for duplicates
if article1.isDuplicate(of: article2) {
    print("Same content from different feeds")
}
```

### Deduplication in Practice

```swift
func deduplicateArticles(_ articles: [Article]) -> [Article] {
    var seen: Set<String> = []
    var unique: [Article] = []

    for article in articles {
        let hash = article.contentHash

        if !seen.contains(hash) {
            seen.insert(hash)
            unique.append(article)
        }
    }

    return unique
}
```

## TTL-Based Caching

### Cache Expiration

Articles use **Time-To-Live (TTL)** for cache management:

```swift
let article = Article(
    // ... properties
    ttlDays: 30  // Cache for 30 days
)

// Expiration calculated automatically
print("Fetched: \(article.fetchedAt)")
print("Expires: \(article.expiresAt)")

// Check if expired
if article.isExpired {
    print("Article needs refresh")
}
```

### Custom TTL Strategies

```swift
func createArticle(
    feed: Feed,
    item: RSSItem,
    ttlStrategy: TTLStrategy
) -> Article {
    let ttlDays: Int

    switch ttlStrategy {
    case .news:
        ttlDays = 7   // News expires quickly
    case .evergreen:
        ttlDays = 90  // Tutorials stay fresh longer
    case .archive:
        ttlDays = 365 // Archive content rarely changes
    case .custom(let days):
        ttlDays = days
    }

    return Article(
        feedRecordName: feed.recordName ?? feed.feedURL,
        guid: item.guid,
        title: item.title,
        url: item.link,
        publishedDate: item.pubDate,
        ttlDays: ttlDays
    )
}

enum TTLStrategy {
    case news
    case evergreen
    case archive
    case custom(Int)
}
```

## Content Processing

### HTML to Plain Text

Articles automatically extract plain text from HTML:

```swift
let html = "<p>Hello <strong>world</strong>!</p>"
let plainText = Article.extractPlainText(from: html)
// Result: "Hello world!"
```

**Note:** This is a basic implementation. For production use, consider a proper HTML parser.

### Word Count and Reading Time

```swift
let content = "This is a sample article with several words..."

// Calculate word count
let wordCount = Article.calculateWordCount(from: content)
// Result: 8

// Estimate reading time (200 words/minute)
let readingTime = Article.estimateReadingTime(wordCount: wordCount)
// Result: 1 minute (minimum)
```

## Article Properties Reference

### Identification

| Property | Type | Description |
|----------|------|-------------|
| `recordName` | `String?` | CloudKit record ID |
| `feedRecordName` | `String` | Parent feed reference |
| `guid` | `String` | Unique ID within feed |
| `id` | `String` | Computed composite ID |

### Content

| Property | Type | Description |
|----------|------|-------------|
| `title` | `String` | Article title |
| `excerpt` | `String?` | Summary/description |
| `content` | `String?` | Full HTML content |
| `contentText` | `String?` | Plain text (auto-computed) |
| `url` | `String` | Article URL |
| `imageURL` | `String?` | Featured image URL |

### Metadata

| Property | Type | Description |
|----------|------|-------------|
| `author` | `String?` | Author name |
| `publishedDate` | `Date?` | Publication date |
| `language` | `String?` | ISO 639-1 language code |
| `tags` | `[String]` | Article tags/categories |

### Caching

| Property | Type | Description |
|----------|------|-------------|
| `fetchedAt` | `Date` | When article was fetched |
| `expiresAt` | `Date` | Cache expiration time |
| `contentHash` | `String` | Deduplication hash |

### Computed

| Property | Type | Description |
|----------|------|-------------|
| `wordCount` | `Int?` | Word count (auto-computed) |
| `estimatedReadingTime` | `Int?` | Reading time in minutes |
| `isExpired` | `Bool` | Cache validity check |

## Common Patterns

### Finding Expired Articles

```swift
func getExpiredArticles(_ articles: [Article]) -> [Article] {
    articles.filter { $0.isExpired }
}
```

### Sorting by Freshness

```swift
let sortedArticles = articles.sorted { lhs, rhs in
    // Not expired first
    if lhs.isExpired != rhs.isExpired {
        return !lhs.isExpired
    }

    // Then by publication date
    guard let lhsDate = lhs.publishedDate,
          let rhsDate = rhs.publishedDate else {
        return false
    }

    return lhsDate > rhsDate
}
```

### Filtering by Reading Time

```swift
func quickReads(_ articles: [Article], maxMinutes: Int = 5) -> [Article] {
    articles.filter { article in
        guard let readingTime = article.estimatedReadingTime else {
            return false
        }
        return readingTime <= maxMinutes
    }
}
```

### Cross-Feed Deduplication

```swift
func deduplicateAcrossFeeds(
    _ articlesByFeed: [[Article]]
) -> [Article] {
    var hashToArticle: [String: Article] = [:]

    for articles in articlesByFeed {
        for article in articles {
            let hash = article.contentHash

            // Keep first occurrence or higher quality
            if let existing = hashToArticle[hash] {
                if article.wordCount ?? 0 > existing.wordCount ?? 0 {
                    hashToArticle[hash] = article
                }
            } else {
                hashToArticle[hash] = article
            }
        }
    }

    return Array(hashToArticle.values)
}
```

## See Also

- ``Article``
- <doc:FeedModelGuide>
- <doc:CachingAndDeduplication>
- <doc:CloudKitIntegration>
