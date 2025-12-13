# Getting Started with CelestraKit

Learn how to integrate CelestraKit into your project and start working with CloudKit models.

## Overview

CelestraKit provides shared CloudKit models for RSS feeds and articles, designed to work across the Celestra ecosystem. This guide will help you get started with the package.

## Installation

### Swift Package Manager

Add CelestraKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/brightdigit/CelestraKit.git", from: "0.0.1")
]
```

Then add it to your target dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: ["CelestraKit"]
)
```

### Xcode

1. In Xcode, go to **File** → **Add Package Dependencies**
2. Enter the repository URL: `https://github.com/brightdigit/CelestraKit.git`
3. Select the version and add to your project

## Quick Start

### Working with Feeds

```swift
import CelestraKit

// Create a new feed
let feed = Feed(
    feedURL: "https://example.com/feed.xml",
    title: "Example Blog",
    description: "A great tech blog",
    category: "Technology"
)

// Check feed health
if feed.isHealthy {
    print("Feed is healthy with \(feed.successRate)% success rate")
}

// Track server metrics
print("Total attempts: \(feed.totalAttempts)")
print("Successful: \(feed.successfulAttempts)")
```

### Working with Articles

```swift
import CelestraKit
import Foundation

// Create an article with automatic TTL
let article = Article(
    feedRecordName: "feed-123",
    guid: "article-456",
    title: "Understanding Swift Concurrency",
    content: "<p>Swift concurrency makes async code easier...</p>",
    url: "https://example.com/article"
)

// Check if article is expired
if !article.isExpired {
    print("Article is still fresh")
    print("Word count: \(article.wordCount)")
    print("Reading time: \(article.estimatedReadingTime) minutes")
}

// Detect duplicates
let contentHash = Article.calculateContentHash(
    title: article.title,
    url: article.url,
    guid: article.guid
)
```

### Rate Limiting for Feed Fetching

```swift
import CelestraKit
import Foundation

// Create a rate limiter
let rateLimiter = RateLimiter(
    defaultDelay: 1.0,      // 1 second between requests
    perDomainDelay: 5.0     // 5 seconds per domain
)

// Use before fetching feeds
let feedURL = URL(string: "https://example.com/feed.xml")!
await rateLimiter.waitIfNeeded(for: feedURL, minimumInterval: 3600)
// Now safe to fetch the feed
```

### Respecting robots.txt

```swift
import CelestraKit
import Foundation

// Create robots.txt service
let robotsService = RobotsTxtService(userAgent: "CelestraBot/1.0")

// Check if URL is allowed
let url = URL(string: "https://example.com/feed.xml")!
do {
    let allowed = try await robotsService.isAllowed(url)
    if allowed {
        // Safe to fetch
        if let crawlDelay = try await robotsService.getCrawlDelay(for: url) {
            print("Respect crawl delay: \(crawlDelay) seconds")
        }
    }
} catch {
    print("Error checking robots.txt: \(error)")
}
```

## Next Steps

- Learn about <doc:CloudKitIntegration> for syncing data
- Understand <doc:RateLimiting> strategies
- Follow <doc:WebEtiquette> best practices
- Explore the ``Feed`` and ``Article`` model documentation

## See Also

- ``Feed``
- ``Article``
- ``RateLimiter``
- ``RobotsTxtService``
