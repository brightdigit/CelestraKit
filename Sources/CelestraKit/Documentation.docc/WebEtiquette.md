# Web Etiquette and robots.txt Compliance

Learn how to respect website policies using RobotsTxtService.

## Overview

The ``RobotsTxtService`` actor helps your feed reader respect website policies by fetching and parsing `robots.txt` files. This ensures you're a good web citizen and follow the Robots Exclusion Protocol.

## What is robots.txt?

`robots.txt` is a standard file websites use to communicate crawling policies:

- **Allowed/Disallowed paths**: Which URLs can be accessed
- **Crawl delays**: How long to wait between requests
- **User-agent specific rules**: Different policies for different bots

Example `robots.txt`:

```
User-agent: *
Disallow: /private/
Crawl-delay: 10

User-agent: CelestraBot
Allow: /
Crawl-delay: 5
```

## Creating a RobotsTxtService

```swift
import CelestraKit

// Default user agent
let robotsService = RobotsTxtService()

// Custom user agent (recommended)
let customService = RobotsTxtService(userAgent: "CelestraBot/1.0")
```

### Choosing a User-Agent

Use a descriptive, identifiable user-agent:

```swift
// Good: Identifies your bot
let service = RobotsTxtService(userAgent: "MyCoolRSSReader/1.0 (+https://example.com/bot-info)")

// Bad: Generic or misleading
let service = RobotsTxtService(userAgent: "Mozilla/5.0") // Don't impersonate browsers
```

This helps website owners:
- Identify your bot in logs
- Set specific policies for your bot
- Contact you if issues arise

## Checking if a URL is Allowed

Use ``RobotsTxtService/isAllowed(_:)`` before fetching a feed:

```swift
let feedURL = URL(string: "https://example.com/feed.xml")!

do {
    let allowed = try await robotsService.isAllowed(feedURL)

    if allowed {
        // Safe to fetch
        let data = try await URLSession.shared.data(from: feedURL)
    } else {
        print("Feed is disallowed by robots.txt")
    }
} catch {
    // robots.txt fetch failed - proceed with caution
    print("Could not fetch robots.txt: \(error)")
}
```

### Error Handling

If `robots.txt` cannot be fetched (404, timeout, etc.), consider:

- **Conservative approach**: Assume disallowed
- **Permissive approach**: Assume allowed (most sites don't block RSS)

```swift
let allowed: Bool
do {
    allowed = try await robotsService.isAllowed(feedURL)
} catch {
    // robots.txt not found - most sites allow RSS feeds
    allowed = true
    print("Assuming allowed: \(error)")
}
```

## Respecting Crawl Delays

Use ``RobotsTxtService/getCrawlDelay(for:)`` to get the requested delay:

```swift
let feedURL = URL(string: "https://example.com/feed.xml")!

do {
    if let crawlDelay = try await robotsService.getCrawlDelay(for: feedURL) {
        print("Site requests \(crawlDelay) second delay between requests")

        // Respect the delay
        await rateLimiter.waitIfNeeded(for: feedURL, minimumInterval: crawlDelay)
    }
} catch {
    print("Could not fetch crawl delay: \(error)")
}
```

### Combining with RateLimiter

Use both robots.txt crawl delay and rate limiting:

```swift
actor FeedFetcher {
    let robotsService = RobotsTxtService(userAgent: "MyBot/1.0")
    let rateLimiter = RateLimiter(defaultDelay: 1.0, perDomainDelay: 5.0)

    func fetchFeed(url: URL) async throws -> Data {
        // 1. Check robots.txt permission
        guard try await robotsService.isAllowed(url) else {
            throw FeedError.disallowedByRobotsTxt
        }

        // 2. Get crawl delay from robots.txt
        let crawlDelay = try await robotsService.getCrawlDelay(for: url)

        // 3. Wait for rate limits (respects crawl delay if longer)
        await rateLimiter.waitIfNeeded(
            for: url,
            minimumInterval: crawlDelay ?? 5.0
        )

        // 4. Fetch feed
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}
```

## Caching Behavior

``RobotsTxtService`` automatically caches robots.txt rules:

```swift
// First call: Fetches robots.txt
let allowed1 = try await robotsService.isAllowed(someURL)

// Second call: Uses cached rules
let allowed2 = try await robotsService.isAllowed(anotherURLSameDomain)
```

### Cache Management

Clear cache when needed:

```swift
// Clear all cached robots.txt
await robotsService.clearCache()

// Clear cache for specific domain
await robotsService.clearCache(for: "example.com")
```

Consider clearing cache:
- Periodically (e.g., daily) to get fresh policies
- When robots.txt fetch fails
- When website owners contact you about issues

## Understanding RobotsRules

The service returns ``RobotsTxtService/RobotsRules`` containing:

```swift
public struct RobotsRules {
    public let disallowedPaths: [String]  // Paths that are disallowed
    public let crawlDelay: TimeInterval?   // Requested delay in seconds
    public let fetchedAt: Date            // When rules were fetched

    public func isAllowed(_ path: String) -> Bool
}
```

### Path Matching

```swift
let rules = RobotsRules(
    disallowedPaths: ["/private/", "/admin/"],
    crawlDelay: 10,
    fetchedAt: Date()
)

rules.isAllowed("/feed.xml")        // true - not in disallowed paths
rules.isAllowed("/private/data")    // false - matches /private/
rules.isAllowed("/admin/users")     // false - matches /admin/
```

## Best Practices

1. **Always check robots.txt** before fetching feeds from a new domain
2. **Use descriptive user-agent** that identifies your bot
3. **Respect crawl delays** specified in robots.txt
4. **Handle fetch errors gracefully** (assume allowed for RSS feeds)
5. **Cache robots.txt** to avoid fetching it repeatedly
6. **Periodically refresh cache** to get updated policies
7. **Combine with rate limiting** for double protection
8. **Provide contact info** in your user-agent string

## Example: Complete Ethical Fetcher

```swift
import CelestraKit
import Foundation

actor EthicalFeedFetcher {
    let robotsService = RobotsTxtService(
        userAgent: "CelestraBot/1.0 (+https://celestra.example.com/bot)"
    )
    let rateLimiter = RateLimiter(defaultDelay: 1.0, perDomainDelay: 5.0)

    func fetchFeed(url: URL) async throws -> Data {
        // Step 1: Check robots.txt
        let allowed: Bool
        do {
            allowed = try await robotsService.isAllowed(url)
        } catch {
            // If robots.txt unavailable, assume RSS feeds are allowed
            print("Warning: Could not fetch robots.txt: \(error)")
            allowed = true
        }

        guard allowed else {
            throw FeedError.disallowedByRobotsTxt
        }

        // Step 2: Get crawl delay
        let crawlDelay: TimeInterval?
        do {
            crawlDelay = try await robotsService.getCrawlDelay(for: url)
        } catch {
            crawlDelay = nil
        }

        // Step 3: Respect rate limits and crawl delay
        await rateLimiter.waitIfNeeded(
            for: url,
            minimumInterval: crawlDelay ?? 5.0
        )
        await rateLimiter.waitGlobal()

        // Step 4: Fetch with proper headers
        var request = URLRequest(url: url)
        request.setValue(
            "CelestraBot/1.0 (+https://celestra.example.com/bot)",
            forHTTPHeaderField: "User-Agent"
        )
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return data
    }

    func refreshRobotsTxtCache() async {
        // Periodically clear cache to get fresh policies
        await robotsService.clearCache()
    }
}

enum FeedError: Error {
    case disallowedByRobotsTxt
}
```

## Thread Safety

``RobotsTxtService`` is an **actor**, making it thread-safe:

```swift
// Safe to call from multiple tasks concurrently
await withTaskGroup(of: Bool.self) { group in
    for url in feedURLs {
        group.addTask {
            try await robotsService.isAllowed(url)
        }
    }
}
```

## Common robots.txt Patterns

### Allowing All

```
User-agent: *
Allow: /
```

### Disallowing Specific Paths

```
User-agent: *
Disallow: /private/
Disallow: /admin/
Allow: /
```

### Bot-Specific Rules

```
User-agent: *
Disallow: /

User-agent: CelestraBot
Allow: /
Crawl-delay: 5
```

### No robots.txt

If a site has no `robots.txt` file (404), all paths are implicitly allowed.

## See Also

- ``RobotsTxtService``
- ``RobotsTxtService/RobotsRules``
- <doc:RateLimiting>
- ``RateLimiter``
