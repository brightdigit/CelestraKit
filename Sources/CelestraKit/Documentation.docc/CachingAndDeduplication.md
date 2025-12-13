# Caching and Deduplication

Advanced strategies for efficient content caching and duplicate detection.

## Overview

CelestraKit implements **TTL-based caching** and **composite key deduplication** to minimize network requests and storage while ensuring content freshness.

## TTL-Based Caching

### How It Works

Articles use **Time-To-Live (TTL)** expiration:

```swift
let article = Article(
    // ... properties
    fetchedAt: Date(),        // When fetched
    ttlDays: 30               // Cache for 30 days
)

// Expiration calculated automatically
article.expiresAt  // fetchedAt + 30 days

// Check validity
if article.isExpired {
    // Time to refresh
}
```

### Dynamic TTL Strategies

```swift
func calculateTTL(for article: Article, feed: Feed) -> Int {
    // News feeds: short TTL
    if feed.category == "News" {
        return 7
    }

    // High-frequency feeds: medium TTL
    if let updateFreq = feed.updateFrequency,
       updateFreq < 3600 {  // Updates hourly
        return 14
    }

    // Evergreen content: long TTL
    if feed.tags.contains("tutorial") || feed.tags.contains("reference") {
        return 90
    }

    // Default: 30 days
    return 30
}
```

### Cache Invalidation

```swift
actor ArticleCache {
    private var articles: [String: Article] = [:]

    func getValid(id: String) -> Article? {
        guard let article = articles[id],
              !article.isExpired else {
            return nil
        }
        return article
    }

    func prune() {
        articles = articles.filter { !$0.value.isExpired }
    }

    func invalidate(feedRecordName: String) {
        articles = articles.filter {
            $0.value.feedRecordName != feedRecordName
        }
    }
}
```

## Content Deduplication

### Composite Key Hashing

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

**Why this approach?**
- **Title**: Identifies content theme
- **URL**: Ensures uniqueness across sources
- **GUID**: Distinguishes updates/versions

### Deduplication Algorithm

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

## Caching Strategies

### Memory Cache

```swift
actor MemoryCache<Key: Hashable, Value> {
    private var cache: [Key: CacheEntry<Value>] = [:]
    private let maxSize: Int

    struct CacheEntry<V> {
        let value: V
        let expiresAt: Date
    }

    init(maxSize: Int = 1000) {
        self.maxSize = maxSize
    }

    func get(_ key: Key) -> Value? {
        guard let entry = cache[key],
              entry.expiresAt > Date() else {
            cache.removeValue(forKey: key)
            return nil
        }
        return entry.value
    }

    func set(_ key: Key, value: Value, ttl: TimeInterval) {
        // Evict if at capacity
        if cache.count >= maxSize {
            evictOldest()
        }

        cache[key] = CacheEntry(
            value: value,
            expiresAt: Date().addingTimeInterval(ttl)
        )
    }

    private func evictOldest() {
        guard let oldestKey = cache.min(by: {
            $0.value.expiresAt < $1.value.expiresAt
        })?.key else {
            return
        }

        cache.removeValue(forKey: oldestKey)
    }
}
```

## Best Practices

### 1. Choose Appropriate TTL

```swift
func selectTTL(for article: Article) -> Int {
    // Time-sensitive: short TTL
    if article.tags.contains("breaking") {
        return 1
    }

    // Recent: medium TTL
    if let published = article.publishedDate,
       Date().timeIntervalSince(published) < 86400 {
        return 7
    }

    // Archived: long TTL
    return 30
}
```

### 2. Periodic Cache Pruning

```swift
actor CacheManager {
    private let cache: ArticleCache

    func startPeriodicPruning() {
        Task {
            while true {
                try await Task.sleep(for: .hours(1))
                await cache.prune()
            }
        }
    }
}
```

## See Also

- ``Article``
- <doc:ArticleModelGuide>
- <doc:CloudKitIntegration>
- <doc:ConcurrencyPatterns>
