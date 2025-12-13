# Concurrency Patterns

Safe concurrent programming with CelestraKit using Swift 6 strict concurrency.

## Overview

CelestraKit is built with **Swift 6 strict concurrency** checking, ensuring data-race freedom at compile time. All public types are `Sendable`, enabling safe concurrent access across actor boundaries.

## Sendable Models

### Why Sendable?

All CelestraKit models conform to `Sendable`:

```swift
public struct Feed: Sendable, Codable, Hashable, Identifiable { }
public struct Article: Sendable, Codable, Hashable, Identifiable { }
```

This guarantees:
- Safe passage across actor boundaries
- No data races when shared between tasks
- Compile-time verification of thread safety

### Using Sendable Models

```swift
actor FeedProcessor {
    // ✓ Safe: Feed is Sendable
    func process(_ feed: Feed) async {
        print("Processing: \(feed.title)")
    }

    // ✓ Safe: Array of Sendable is Sendable
    func processAll(_ feeds: [Feed]) async {
        for feed in feeds {
            await process(feed)
        }
    }
}

Task {
    let feed = Feed(feedURL: "...", title: "Example")
    let processor = FeedProcessor()

    // ✓ Crosses task boundary safely
    await processor.process(feed)
}
```

## Actor-Based Services

### RateLimiter Actor

```swift
let rateLimiter = RateLimiter(
    defaultDelay: 2.0,
    perDomainDelay: 5.0
)

// All access is serialized through the actor
await rateLimiter.waitIfNeeded(for: url)
```

**Why an actor?**
- Serializes access to mutable state (`lastFetchTimes`)
- Prevents data races when multiple tasks fetch simultaneously
- Provides atomic "check and update" operations

### RobotsTxtService Actor

```swift
let robotsService = RobotsTxtService(userAgent: "Celestra")

// Cache access is serialized
let isAllowed = try await robotsService.isAllowed(url)
```

**Why an actor?**
- Manages shared cache safely
- Prevents duplicate fetches of robots.txt
- Atomic cache updates

## Common Patterns

### Pattern 1: Concurrent Feed Fetching

```swift
func fetchAllFeeds(_ feeds: [Feed]) async throws -> [Article] {
    // ✓ Safe: Concurrent execution with actor coordination
    let rateLimiter = RateLimiter()

    return try await withThrowingTaskGroup(of: [Article].self) { group in
        for feed in feeds {
            group.addTask {
                // Rate limiting is actor-isolated
                await rateLimiter.waitIfNeeded(
                    for: URL(string: feed.feedURL)!
                )

                return try await fetchArticles(for: feed)
            }
        }

        var allArticles: [Article] = []
        for try await articles in group {
            allArticles.append(contentsOf: articles)
        }

        return allArticles
    }
}
```

### Pattern 2: Actor-Isolated Cache

```swift
actor FeedCache {
    private var feeds: [String: Feed] = [:]
    private var lastUpdate: Date?

    func getFeed(_ url: String) -> Feed? {
        feeds[url]
    }

    func setFeed(_ feed: Feed) {
        feeds[feed.feedURL] = feed
        lastUpdate = Date()
    }

    func clear() {
        feeds.removeAll()
        lastUpdate = nil
    }
}

// Usage
let cache = FeedCache()

Task {
    // All access serialized through actor
    await cache.setFeed(feed)

    if let cached = await cache.getFeed(feed.feedURL) {
        print("Cache hit: \(cached.title)")
    }
}
```

### Pattern 3: MainActor UI Updates

```swift
@MainActor
class FeedViewModel: ObservableObject {
    @Published var feeds: [Feed] = []
    @Published var isLoading = false

    func loadFeeds() async {
        isLoading = true
        defer { isLoading = false }

        // Fetch on background
        let fetchedFeeds = try? await fetchAllFeeds()

        // Update on MainActor
        self.feeds = fetchedFeeds ?? []
    }
}

// SwiftUI view
struct FeedListView: View {
    @StateObject var viewModel = FeedViewModel()

    var body: some View {
        List(viewModel.feeds) { feed in
            FeedRow(feed: feed)
        }
        .task {
            await viewModel.loadFeeds()
        }
    }
}
```

## Best Practices

### 1. Prefer Sendable Types

```swift
// ✓ Good: Sendable struct
struct FeedMetrics: Sendable {
    let successRate: Double
    let healthScore: Int
}

// ✗ Bad: Non-Sendable class
class FeedMetrics {
    var successRate: Double = 0
    var healthScore: Int = 0
}
```

### 2. Use Actors for Mutable State

```swift
// ✓ Good: Actor protects mutable state
actor Counter {
    private var value = 0

    func increment() {
        value += 1
    }
}

// ✗ Bad: Unprotected mutable state
class Counter {
    var value = 0  // ⚠️ Data race possible

    func increment() {
        value += 1
    }
}
```

## See Also

- ``RateLimiter``
- ``RobotsTxtService``
- <doc:CloudKitIntegration>
- <doc:WebEtiquette>
