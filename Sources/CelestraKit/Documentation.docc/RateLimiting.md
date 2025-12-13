# Rate Limiting for Feed Fetching

Learn how to use the RateLimiter actor for responsible web crawling.

## Overview

The ``RateLimiter`` actor provides both **per-domain** and **global** rate limiting for RSS feed fetching. This ensures your feed reader respects server resources and avoids overwhelming feed publishers.

## Why Rate Limiting Matters

RSS feed fetching can put load on publishers' servers. Rate limiting helps:

- **Prevent server overload**: Avoid hammering publishers with rapid requests
- **Respect RSS TTL**: Honor the `<ttl>` tag indicating how often to check
- **Be a good web citizen**: Follow ethical web crawling practices
- **Avoid IP bans**: Prevent getting blocked for aggressive fetching

## Creating a RateLimiter

```swift
import CelestraKit

// Default: 1 second global delay, 5 seconds per domain
let rateLimiter = RateLimiter()

// Custom delays
let customLimiter = RateLimiter(
    defaultDelay: 0.5,      // 500ms between any requests
    perDomainDelay: 10.0    // 10 seconds per domain
)
```

### Configuration Parameters

- **defaultDelay**: Minimum time between *any* requests (global rate limit)
- **perDomainDelay**: Minimum time between requests to the *same domain*

## Per-Domain Rate Limiting

Use ``RateLimiter/waitIfNeeded(for:minimumInterval:)`` before fetching a feed:

```swift
let feedURL = URL(string: "https://example.com/feed.xml")!

// Wait if needed based on last fetch to example.com
await rateLimiter.waitIfNeeded(for: feedURL)

// Now safe to fetch
let data = try await URLSession.shared.data(from: feedURL)
```

### Respecting RSS TTL

RSS feeds can specify a `<ttl>` (time-to-live) tag indicating update frequency:

```swift
// Example: RSS feed has <ttl>60</ttl> (60 minutes)
let ttlSeconds: TimeInterval = 60 * 60 // Convert to seconds

// Respect feed's TTL
await rateLimiter.waitIfNeeded(
    for: feedURL,
    minimumInterval: ttlSeconds
)
```

The rate limiter will enforce **whichever is longer**:
- Your configured `perDomainDelay`
- The feed-specific `minimumInterval`

### How Per-Domain Works

The rate limiter tracks the last fetch time for each domain:

```swift
// First request to example.com - no delay
await rateLimiter.waitIfNeeded(for: URL(string: "https://example.com/feed1.xml")!)

// Second request to example.com immediately after - waits 5 seconds
await rateLimiter.waitIfNeeded(for: URL(string: "https://example.com/feed2.xml")!)

// Request to different domain - no delay
await rateLimiter.waitIfNeeded(for: URL(string: "https://other.com/feed.xml")!)
```

## Global Rate Limiting

Use ``RateLimiter/waitGlobal()`` to enforce a minimum delay between *any* requests:

```swift
// Wait 1 second since last request to any domain
await rateLimiter.waitGlobal()

// Safe to fetch any URL
let data = try await URLSession.shared.data(from: anyURL)
```

This is useful when:
- You want to limit total request rate regardless of domain
- Your network connection has bandwidth limits
- You're fetching from many different domains

## Combining Both Strategies

For maximum respect, use both per-domain and global rate limiting:

```swift
actor FeedFetcher {
    let rateLimiter = RateLimiter(
        defaultDelay: 1.0,      // At most 1 request/second globally
        perDomainDelay: 60.0    // At most 1 request/minute per domain
    )

    func fetchFeed(url: URL) async throws -> Data {
        // Wait for both conditions
        await rateLimiter.waitIfNeeded(for: url)
        await rateLimiter.waitGlobal()

        // Now fetch
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}
```

## Advanced Patterns

### Batch Processing Feeds

When processing multiple feeds, respect rate limits:

```swift
let feedURLs: [URL] = [ /* ... */ ]

for feedURL in feedURLs {
    // Per-domain rate limiting
    await rateLimiter.waitIfNeeded(for: feedURL)

    do {
        let data = try await URLSession.shared.data(from: feedURL)
        // Process feed
    } catch {
        print("Error fetching \(feedURL): \(error)")
    }
}
```

### Resetting Rate Limits

In testing or when restarting:

```swift
// Clear all rate limiting history
await rateLimiter.reset()

// Clear history for specific domain
await rateLimiter.reset(for: "example.com")
```

### Dynamic TTL Based on Feed Quality

Adjust fetch frequency based on feed health:

```swift
func fetchIntervalFor(feed: Feed) -> TimeInterval {
    switch feed.qualityScore {
    case 80...100:
        return 3600      // High quality: Check hourly
    case 50..<80:
        return 7200      // Medium: Check every 2 hours
    default:
        return 14400     // Low quality: Check every 4 hours
    }
}

// Use dynamic interval
let interval = fetchIntervalFor(feed: myFeed)
await rateLimiter.waitIfNeeded(for: feedURL, minimumInterval: interval)
```

## Thread Safety

``RateLimiter`` is an **actor**, making it thread-safe:

```swift
// Safe to call from multiple tasks concurrently
await withTaskGroup(of: Void.self) { group in
    for feedURL in feedURLs {
        group.addTask {
            await rateLimiter.waitIfNeeded(for: feedURL)
            // Fetch feed
        }
    }
}
```

The actor ensures:
- No race conditions when updating last fetch times
- Proper sequencing of delays
- Thread-safe access to internal state

## Best Practices

1. **Always rate limit**: Use `waitIfNeeded()` before every feed fetch
2. **Respect RSS TTL**: Pass `minimumInterval` based on `<ttl>` tag
3. **Use per-domain limits**: Prevents overwhelming individual publishers
4. **Add global limits**: Prevents overwhelming your own network
5. **Adjust for feed quality**: Check lower-quality feeds less frequently
6. **Handle errors gracefully**: Don't retry immediately on failures
7. **Test with longer delays**: Better to be conservative
8. **Combine with robots.txt**: See <doc:WebEtiquette>

## Example: Complete Feed Fetcher

```swift
import CelestraKit
import Foundation

actor FeedFetcher {
    let rateLimiter = RateLimiter(
        defaultDelay: 1.0,
        perDomainDelay: 60.0
    )

    func fetchFeed(_ feed: Feed) async throws -> Data {
        let url = URL(string: feed.feedURL)!

        // Calculate minimum interval from feed's update frequency
        let minInterval = TimeInterval(feed.updateFrequency ?? 3600)

        // Wait for rate limits
        await rateLimiter.waitIfNeeded(for: url, minimumInterval: minInterval)
        await rateLimiter.waitGlobal()

        // Fetch with timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        let session = URLSession(configuration: config)

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return data
    }
}
```

## See Also

- ``RateLimiter``
- <doc:WebEtiquette>
- ``Feed``
