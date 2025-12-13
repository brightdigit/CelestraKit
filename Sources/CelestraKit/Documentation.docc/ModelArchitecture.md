# Model Architecture

Understanding CelestraKit's data model design and architectural decisions.

## Overview

CelestraKit uses a **shared public database** model where all feeds and articles are stored in CloudKit's public database, accessible to all users. This architecture reduces redundant network requests and enables efficient content distribution.

## Design Principles

### 1. Shared Public Database

All content lives in CloudKit's public database:
- **One canonical Feed** per RSS feed URL
- **One canonical Article** per feed item
- **Shared across all users** for efficiency
- **Server-managed updates** for consistency

### 2. Optimistic Locking

Models include CloudKit metadata for conflict resolution:

```swift
public struct Feed {
    public let recordName: String?
    public let recordChangeTag: String?
    // ... other properties
}
```

The `recordChangeTag` enables optimistic locking when updating records.

### 3. Sendable-First Design

All models conform to `Sendable` for Swift 6 strict concurrency:

```swift
public struct Feed: Sendable, Codable, Hashable, Identifiable { }
public struct Article: Sendable, Codable, Hashable, Identifiable { }
public actor RateLimiter { }
public actor RobotsTxtService { }
```

This ensures safe concurrent access across actor boundaries.

## Feed-Article Relationship

### One-to-Many Relationship

```
┌──────────────┐
│     Feed     │
│  (feedURL)   │
└──────┬───────┘
       │
       │ 1:N
       │
┌──────▼────────────────┐
│      Articles         │
│  (feedRecordName)     │
└───────────────────────┘
```

Articles reference their parent feed via `feedRecordName`:

```swift
let article = Article(
    feedRecordName: feed.recordName ?? feed.feedURL,
    guid: "unique-article-id",
    // ...
)
```

### Identity and Uniqueness

**Feed Identity:**
- Primary: `recordName` (CloudKit record ID)
- Fallback: `feedURL` (unique RSS feed URL)

**Article Identity:**
- Composite: `feedRecordName` + `guid`
- Computed: `id` property returns `"\(feedRecordName):\(guid)"`

```swift
public var id: String {
    recordName ?? "\(feedRecordName):\(guid)"
}
```

## Data Flow

### Server-Side Processing

1. CelestraCloud fetches RSS feeds
2. Creates/updates Feed records in CloudKit
3. Parses articles and creates Article records
4. Updates Feed metrics (success rate, health)
5. Respects TTL and caching headers

### Client-Side Consumption

1. CelestraApp queries CloudKit public database
2. Fetches Feed records with filters
3. Loads Article records for subscribed feeds
4. Checks `isExpired` for cache validity
5. Displays content to user

## Type Safety

### Strong Typing

All models use Swift's type system for safety:

```swift
public struct Feed {
    public let qualityScore: Int            // Not Double
    public let subscriberCount: Int64       // Explicit size
    public let updateFrequency: TimeInterval? // Optional
}
```

### Computed Properties

Models expose computed properties for convenience:

```swift
extension Feed {
    public var successRate: Double {
        guard totalAttempts > 0 else { return 0.0 }
        return Double(successfulAttempts) / Double(totalAttempts)
    }

    public var isHealthy: Bool {
        failureCount < 3 && successRate > 0.8
    }
}
```

## Platform Compatibility

### CloudKit vs. DTO Mode

Models are designed to work in two modes:

**CloudKit Mode (Apple Platforms):**
```swift
// Map to CKRecord
let record = CKRecord(recordType: "Feed")
record["feedURL"] = feed.feedURL
record["title"] = feed.title
// ...
```

**DTO Mode (Linux/Server):**
```swift
// Encode to JSON
let encoder = JSONEncoder()
let json = try encoder.encode(feed)
```

Both modes use the same struct definition.

## See Also

- <doc:FeedModelGuide>
- <doc:ArticleModelGuide>
- <doc:CloudKitIntegration>
- <doc:ConcurrencyPatterns>
