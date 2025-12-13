# Feed Model Guide

Complete guide to working with ``Feed`` models in CelestraKit.

## Overview

The ``Feed`` struct represents RSS feeds in CloudKit's public database, providing metadata, server-side metrics, and health indicators for feed processing and monitoring.

## Feed Structure

### Core Metadata

```swift
let feed = Feed(
    recordName: "unique-feed-id",        // CloudKit record name
    feedURL: "https://example.com/rss",  // Unique feed URL
    title: "Example Blog",               // Feed title
    description: "Daily tech articles",  // Feed description
    category: "Technology",              // Primary category
    imageURL: "https://example.com/img", // Feed icon/logo
    siteURL: "https://example.com",      // Website URL
    language: "en"                       // ISO 639-1 language code
)
```

### Quality Indicators

```swift
let feed = Feed(
    // ... metadata
    qualityScore: 85,      // 0-100 quality score
    isVerified: true,      // Manually verified/trusted
    isFeatured: false,     // Featured in app
    subscriberCount: 1500,
    tags: ["swift", "ios"] // Categorization tags
)
```

### Server-Side Metrics

These metrics are typically updated by server-side feed processors:

```swift
let feed = Feed(
    // ... metadata
    totalAttempts: 100,         // Total fetch attempts
    successfulAttempts: 95,     // Successful fetches
    failureCount: 2,            // Consecutive failures
    lastAttempted: Date(),      // Last fetch attempt
    lastFailureReason: nil,     // Error message if failed
    isActive: true              // Still being processed
)
```

## Working with Feeds

### Creating Feeds

```swift
// Minimal feed creation
let minimalFeed = Feed(
    feedURL: "https://example.com/feed.xml",
    title: "Example Feed"
)

// Full feed with all properties
let completeFeed = Feed(
    recordName: "tech-feed-001",
    feedURL: "https://techblog.example.com/rss",
    title: "Tech Blog",
    description: "Daily technology news and tutorials",
    category: "Technology",
    imageURL: "https://techblog.example.com/icon.png",
    siteURL: "https://techblog.example.com",
    language: "en",
    isFeatured: false,
    isVerified: true,
    qualityScore: 92,
    subscriberCount: 1500,
    addedAt: Date(),
    updateFrequency: 3600, // Updates every hour
    tags: ["tech", "programming", "tutorials"],
    totalAttempts: 100,
    successfulAttempts: 95,
    isActive: true
)
```

### Checking Feed Health

```swift
func processFeed(_ feed: Feed) async {
    // Check if feed is healthy
    if feed.isHealthy {
        print("✓ Feed is healthy")
        print("  Success rate: \(feed.successRate * 100)%")
        print("  Quality score: \(feed.qualityScore)")
    } else {
        print("⚠️ Feed has issues")
        print("  Failure count: \(feed.failureCount)")
        print("  Success rate: \(feed.successRate * 100)%")

        if let reason = feed.lastFailureReason {
            print("  Last error: \(reason)")
        }
    }
}
```

### HTTP Caching Headers

Feeds store HTTP caching metadata for efficient fetching:

```swift
let feed = Feed(
    // ... metadata
    etag: "\"686897696a7c876b7e\"",           // ETag header
    lastModified: "Wed, 21 Oct 2015 07:28:00 GMT", // Last-Modified
    minUpdateInterval: 3600                  // RSS <ttl> in seconds
)

// Use in conditional requests
func fetchFeed(_ feed: Feed) async throws -> Data {
    var request = URLRequest(url: URL(string: feed.feedURL)!)

    if let etag = feed.etag {
        request.setValue(etag, forHTTPHeaderField: "If-None-Match")
    }

    if let lastModified = feed.lastModified {
        request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
    }

    let (data, response) = try await URLSession.shared.data(for: request)

    if let httpResponse = response as? HTTPURLResponse,
       httpResponse.statusCode == 304 {
        print("Not modified - use cached content")
    }

    return data
}
```

## Feed Properties Reference

### Identification

| Property | Type | Description |
|----------|------|-------------|
| `recordName` | `String?` | CloudKit record identifier |
| `recordChangeTag` | `String?` | CloudKit optimistic locking tag |
| `feedURL` | `String` | Unique RSS feed URL |
| `id` | `String` | Computed: recordName or feedURL |

### Metadata

| Property | Type | Description |
|----------|------|-------------|
| `title` | `String` | Feed title from RSS |
| `description` | `String?` | Feed description/subtitle |
| `category` | `String?` | Primary category |
| `imageURL` | `String?` | Feed icon/logo URL |
| `siteURL` | `String?` | Website URL |
| `language` | `String?` | ISO 639-1 language code |
| `tags` | `[String]` | Categorization tags |

### Quality Metrics

| Property | Type | Description |
|----------|------|-------------|
| `qualityScore` | `Int` | Quality score (0-100) |
| `isVerified` | `Bool` | Manually verified feed |
| `isFeatured` | `Bool` | Featured in app |
| `subscriberCount` | `Int64` | Number of subscribers |

### Server Metrics

| Property | Type | Description |
|----------|------|-------------|
| `totalAttempts` | `Int64` | Total fetch attempts |
| `successfulAttempts` | `Int64` | Successful fetches |
| `failureCount` | `Int64` | Consecutive failures |
| `lastAttempted` | `Date?` | Last fetch attempt time |
| `lastFailureReason` | `String?` | Last error message |
| `isActive` | `Bool` | Still being processed |

### HTTP Caching

| Property | Type | Description |
|----------|------|-------------|
| `etag` | `String?` | HTTP ETag for conditional requests |
| `lastModified` | `String?` | HTTP Last-Modified header |
| `minUpdateInterval` | `TimeInterval?` | Minimum seconds between updates |

### Computed Properties

| Property | Type | Description |
|----------|------|-------------|
| `successRate` | `Double` | Success rate (0.0-1.0) |
| `isHealthy` | `Bool` | Health status indicator |

## Common Patterns

### Filtering Quality Feeds

```swift
func getQualityFeeds(_ feeds: [Feed]) -> [Feed] {
    feeds.filter { feed in
        feed.isHealthy &&
        feed.qualityScore > 70 &&
        feed.successRate > 0.9
    }
}
```

### Sorting by Quality

```swift
let sortedFeeds = feeds.sorted { lhs, rhs in
    // Featured feeds first
    if lhs.isFeatured != rhs.isFeatured {
        return lhs.isFeatured
    }

    // Then by quality score
    if lhs.qualityScore != rhs.qualityScore {
        return lhs.qualityScore > rhs.qualityScore
    }

    // Finally by subscriber count
    return lhs.subscriberCount > rhs.subscriberCount
}
```

### Update Frequency Calculation

```swift
func shouldFetch(_ feed: Feed) -> Bool {
    guard let lastAttempted = feed.lastAttempted else {
        return true // Never fetched
    }

    let timeSinceLastFetch = Date().timeIntervalSince(lastAttempted)

    // Respect feed's minimum update interval
    if let minInterval = feed.minUpdateInterval {
        return timeSinceLastFetch >= minInterval
    }

    // Respect feed's typical update frequency
    if let updateFreq = feed.updateFrequency {
        return timeSinceLastFetch >= updateFreq
    }

    // Default: fetch every hour
    return timeSinceLastFetch >= 3600
}
```

### Health Monitoring

```swift
func monitorFeedHealth(_ feed: Feed) -> HealthStatus {
    if feed.failureCount >= 5 {
        return .critical
    } else if feed.failureCount >= 3 {
        return .warning
    } else if feed.successRate < 0.8 {
        return .degraded
    } else if feed.isHealthy {
        return .healthy
    } else {
        return .unknown
    }
}

enum HealthStatus {
    case healthy
    case degraded
    case warning
    case critical
    case unknown
}
```

## See Also

- ``Feed``
- <doc:ArticleModelGuide>
- <doc:CloudKitIntegration>
- <doc:CachingAndDeduplication>
