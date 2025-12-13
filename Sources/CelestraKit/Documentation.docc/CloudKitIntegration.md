# CloudKit Integration

Learn how CelestraKit models map to CloudKit's public database.

## Overview

CelestraKit models are designed to work seamlessly with CloudKit's public database, enabling data sharing across all Celestra users. Both ``Feed`` and ``Article`` models include CloudKit-specific fields for optimistic locking and record management.

## Public Database Architecture

The Celestra ecosystem uses CloudKit's **public database** to share:
- **Feed metadata**: Shared catalog of RSS feeds with quality metrics
- **Article content**: Cached RSS articles with TTL-based expiration

This allows:
- **Client apps** to read shared feed catalog and cached articles
- **Server-side tools** to update feed metrics and populate article cache

## CloudKit Fields

### Record Management

Both models include CloudKit record management fields:

```swift
// Feed and Article both include:
public var recordName: String           // CloudKit record identifier
public var recordChangeTag: String?     // For optimistic locking
```

#### Optimistic Locking

CloudKit uses `recordChangeTag` to prevent conflicting updates:

1. Fetch record with current `recordChangeTag`
2. Modify local copy
3. Save with original `recordChangeTag`
4. CloudKit rejects if tag doesn't match (record was modified)

Example:

```swift
// Server-side: Update feed metrics
var feed = fetchedFeed
feed.totalAttempts += 1
feed.successfulAttempts += 1

// Save with recordChangeTag - CloudKit ensures no conflicts
// If another process updated the feed, save fails with conflict error
```

### Feed Model Mapping

The ``Feed`` model maps to CloudKit records with these characteristics:

**Record Type**: `Feed`
**Unique Identifier**: `feedURL` (enforced via record name)

Key fields:
- **Identity**: `recordName`, `feedURL`
- **Metadata**: `title`, `description`, `category`, `imageURL`, `siteURL`
- **Quality**: `qualityScore`, `isVerified`, `isFeatured`, `isHealthy` (computed)
- **Server Metrics**: `totalAttempts`, `successfulAttempts`, `failureCount`
- **HTTP Caching**: `etag`, `lastModified`

### Article Model Mapping

The ``Article`` model maps to CloudKit records with these characteristics:

**Record Type**: `Article`
**Unique Identifier**: Composite of `feedRecordName` + `guid`

Key fields:
- **Identity**: `recordName`, `feedRecordName`, `guid`
- **Content**: `title`, `content`, `contentText`, `excerpt`
- **Caching**: `fetchedAt`, `expiresAt`, `contentHash`, `isExpired` (computed)
- **Metadata**: `author`, `publishedDate`, `wordCount`, `estimatedReadingTime`

## Data Flow Patterns

### Server-Side Updates

Server tools (like CelestraCloud) update the public database:

```swift
// 1. Fetch feed with RSS parser
let parsedFeed = try await fetchAndParseFeed(url: feedURL)

// 2. Update Feed record metrics
var feed = existingFeed
feed.totalAttempts += 1
feed.successfulAttempts += 1
feed.lastAttempted = Date()
feed.etag = response.etag

// 3. Save to CloudKit with optimistic locking
// CloudKit uses recordChangeTag to prevent conflicts

// 4. Create/update Article records
for item in parsedFeed.items {
    let article = Article(
        feedRecordName: feed.recordName,
        guid: item.id,
        title: item.title,
        content: item.content,
        url: item.link,
        ttl: 2_592_000 // 30 days
    )
    // Save article to CloudKit
}
```

### Client-Side Reads

iOS apps read from the public database:

```swift
// 1. Query feeds by category
let feeds = try await fetchFeeds(category: "Technology")

// 2. Check feed health
let healthyFeeds = feeds.filter { $0.isHealthy }

// 3. Fetch recent articles for feed
let articles = try await fetchArticles(feedRecordName: feed.recordName)

// 4. Filter unexpired articles
let freshArticles = articles.filter { !$0.isExpired }
```

## Content Deduplication

Articles use ``Article/calculateContentHash(title:url:guid:)`` for deduplication:

```swift
// Composite key: title|url|guid
let hash = Article.calculateContentHash(
    title: "Swift Concurrency",
    url: "https://example.com/article",
    guid: "abc123"
)

// Use hash to detect duplicates before saving
let duplicate = existingArticles.contains { $0.contentHash == hash }
```

This prevents duplicate articles when:
- Feed includes same article with different timestamps
- Multiple feeds share content (canonical URLs)
- Feed updates article content

## Caching Strategy

### TTL-Based Expiration

Articles use Time-To-Live (TTL) based caching:

```swift
// Default: 30 days (2,592,000 seconds)
let article = Article(
    // ... other fields
    ttl: 2_592_000
)

// Automatic expiration check
if article.isExpired {
    // Article past expiresAt - should be refreshed
}
```

### Feed-Specific TTL

Feeds can specify custom update intervals:

```swift
// RSS <ttl> tag or calculated from update frequency
let feed = Feed(
    // ...
    updateFrequency: 3600, // Hourly updates
    minUpdateInterval: 900  // Don't check more than every 15 min
)
```

## Query Patterns

### Finding Feeds

```swift
// By category
let techFeeds = feeds.filter { $0.category == "Technology" }

// By health status
let healthyFeeds = feeds.filter { $0.isHealthy }

// By quality score
let qualityFeeds = feeds.filter { $0.qualityScore >= 70 }

// Featured/verified
let featuredFeeds = feeds.filter { $0.isFeatured || $0.isVerified }
```

### Finding Articles

```swift
// By feed
let feedArticles = articles.filter { $0.feedRecordName == feed.recordName }

// Fresh articles only
let freshArticles = articles.filter { !$0.isExpired }

// Recent articles
let recentArticles = articles
    .sorted { $0.publishedDate > $1.publishedDate }
    .prefix(20)
```

## Best Practices

### On the Server

- **Always use optimistic locking** via `recordChangeTag`
- **Update feed metrics** after each fetch attempt
- **Respect HTTP caching** headers (ETag, Last-Modified)
- **Set appropriate TTL** based on feed update frequency
- **Use content hashing** to prevent duplicates

### On the Client

- **Filter expired articles** before displaying
- **Cache CloudKit queries** to reduce database reads
- **Respect feed quality scores** when recommending content
- **Monitor `isHealthy`** to detect broken feeds
- **Use `recordChangeTag`** when modifying records

## Platform Considerations

CelestraKit is designed for both CloudKit-enabled platforms and server environments:

- **Apple Platforms** (iOS, macOS, etc.): Full CloudKit integration available
- **Linux/Server**: Models work as DTOs with Codable conformance

This enables server-side feed processing tools to populate CloudKit data that client apps consume.

## See Also

- ``Feed``
- ``Article``
- <doc:RateLimiting>
- <doc:WebEtiquette>
