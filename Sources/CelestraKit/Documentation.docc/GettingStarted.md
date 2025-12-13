# Getting Started with CelestraKit

Get up and running with CelestraKit in minutes.

## Installation

### Swift Package Manager

Add CelestraKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/brightdigit/CelestraKit.git", from: "0.0.1")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/brightdigit/CelestraKit.git`
3. Select version and add to your target

## Requirements

- **Swift**: 6.2+
- **Platforms**: iOS 26+, macOS 26+, watchOS 26+, tvOS 26+, visionOS 26+, macCatalyst 26+
- **CloudKit**: Requires CloudKit entitlement for production use

## First Steps

### 1. Import CelestraKit

```swift
import CelestraKit
```

### 2. Create a Feed

```swift
let feed = Feed(
    recordName: "tech-blog",
    feedURL: "https://example.com/feed.xml",
    title: "Tech Blog",
    description: "Latest technology articles",
    category: "Technology",
    qualityScore: 85,
    isVerified: true
)
```

### 3. Create Articles

```swift
let article = Article(
    feedRecordName: feed.recordName ?? feed.feedURL,
    guid: "article-001",
    title: "Getting Started with Swift 6",
    excerpt: "Learn the basics of Swift 6 concurrency",
    content: "<p>Swift 6 introduces strict concurrency checking...</p>",
    url: "https://example.com/swift-6",
    publishedDate: Date(),
    ttlDays: 30  // Cache for 30 days
)

// Check cache status
if article.isExpired {
    print("Article needs refresh")
}

// Get estimated reading time
if let readingTime = article.estimatedReadingTime {
    print("Reading time: \(readingTime) minutes")
}
```

### 4. Using Web Etiquette Services

```swift
// Rate limiting
let rateLimiter = RateLimiter(
    defaultDelay: 2.0,
    perDomainDelay: 5.0
)

// Wait before fetching
let feedURL = URL(string: feed.feedURL)!
await rateLimiter.waitIfNeeded(for: feedURL)

// Robots.txt compliance
let robotsService = RobotsTxtService(userAgent: "Celestra/1.0")
let isAllowed = try await robotsService.isAllowed(feedURL)

if isAllowed {
    // Fetch feed
    let (data, _) = try await URLSession.shared.data(from: feedURL)
}
```

## Next Steps

- Read the <doc:ModelArchitecture> to understand the design
- Learn about <doc:CloudKitIntegration> for production use
- Explore <doc:ConcurrencyPatterns> for safe concurrent access

## Common Patterns

### Checking Feed Health

```swift
func checkFeedHealth(_ feed: Feed) {
    if feed.isHealthy {
        print("✓ Feed is healthy")
        print("  Success rate: \(feed.successRate * 100)%")
        print("  Quality score: \(feed.qualityScore)")
    } else {
        print("⚠️ Feed experiencing issues")
        print("  Failure count: \(feed.failureCount)")
        if let reason = feed.lastFailureReason {
            print("  Last error: \(reason)")
        }
    }
}
```

### Article Deduplication

```swift
func deduplicateArticles(_ articles: [Article]) -> [Article] {
    var seen: Set<String> = []
    var unique: [Article] = []

    for article in articles {
        if seen.insert(article.contentHash).inserted {
            unique.append(article)
        }
    }

    return unique
}

// Check if two articles are duplicates
if article1.isDuplicate(of: article2) {
    print("Duplicate content detected")
}
```

### Estimating Reading Time

```swift
func formatReadingTime(_ article: Article) -> String {
    guard let minutes = article.estimatedReadingTime else {
        return "Unknown"
    }

    if minutes < 1 {
        return "< 1 min read"
    } else if minutes == 1 {
        return "1 min read"
    } else {
        return "\(minutes) min read"
    }
}
```

### Finding Fresh Articles

```swift
func getFreshArticles(_ articles: [Article]) -> [Article] {
    articles.filter { !$0.isExpired }
}

func sortByFreshness(_ articles: [Article]) -> [Article] {
    articles.sorted { lhs, rhs in
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
}
```

## See Also

- ``Feed``
- ``Article``
- ``RateLimiter``
- ``RobotsTxtService``
