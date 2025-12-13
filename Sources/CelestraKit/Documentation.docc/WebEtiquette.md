# Web Etiquette

Responsible RSS feed fetching with rate limiting and robots.txt compliance.

## Overview

CelestraKit provides two services for **responsible web crawling**:
- ``RateLimiter``: Prevent server overload with configurable delays
- ``RobotsTxtService``: Respect robots.txt policies

## Rate Limiting

### Why Rate Limit?

Rate limiting prevents:
- **Server overload**: Too many requests in short time
- **IP bans**: Servers may block aggressive clients
- **Poor user experience**: Network congestion

### Basic Usage

```swift
let rateLimiter = RateLimiter(
    defaultDelay: 2.0,        // 2s between any requests
    perDomainDelay: 5.0       // 5s between requests to same domain
)

// Wait before fetching
await rateLimiter.waitIfNeeded(for: feedURL)

// Fetch feed
let data = try await URLSession.shared.data(from: feedURL)
```

### Configuration

```swift
// Conservative: slower, more polite
let conservative = RateLimiter(
    defaultDelay: 5.0,
    perDomainDelay: 10.0
)

// Aggressive: faster, higher risk
let aggressive = RateLimiter(
    defaultDelay: 0.5,
    perDomainDelay: 2.0
)

// Respect feed's TTL
await rateLimiter.waitIfNeeded(
    for: feedURL,
    minimumInterval: feed.minUpdateInterval
)
```

## Robots.txt Compliance

### Why Robots.txt?

robots.txt allows sites to:
- **Specify crawl rules** for automated clients
- **Set crawl delays** to prevent overload
- **Block specific paths** from crawling

### Basic Usage

```swift
let robotsService = RobotsTxtService(userAgent: "Celestra/1.0")

// Check if URL is allowed
let isAllowed = try await robotsService.isAllowed(feedURL)

if isAllowed {
    // Fetch content
    let data = try await URLSession.shared.data(from: feedURL)
}
```

### Getting Crawl Delay

```swift
if let delay = try await robotsService.getCrawlDelay(for: feedURL) {
    print("Site requests \(delay)s delay between requests")

    // Use this delay with RateLimiter
    await rateLimiter.waitIfNeeded(
        for: feedURL,
        minimumInterval: delay
    )
}
```

### Combined Usage

```swift
actor ResponsibleFetcher {
    private let rateLimiter = RateLimiter()
    private let robotsService = RobotsTxtService(userAgent: "Celestra/1.0")

    func fetch(_ url: URL) async throws -> Data {
        // Check robots.txt
        guard try await robotsService.isAllowed(url) else {
            throw FetchError.disallowedByRobots
        }

        // Get crawl delay
        let crawlDelay = try await robotsService.getCrawlDelay(for: url)

        // Rate limit
        await rateLimiter.waitIfNeeded(
            for: url,
            minimumInterval: crawlDelay
        )

        // Fetch
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}
```

## Best Practices

### 1. Combine Services

```swift
actor EthicalFetcher {
    private let rateLimiter = RateLimiter(
        defaultDelay: 2.0,
        perDomainDelay: 5.0
    )
    private let robotsService = RobotsTxtService(
        userAgent: "Celestra/1.0 (+https://celestra.app/bot; contact@celestra.app)"
    )

    func fetch(_ url: URL) async throws -> Data {
        // Robots.txt check
        guard try await robotsService.isAllowed(url) else {
            throw FetchError.robotsDisallowed
        }

        // Respect crawl delay
        let crawlDelay = try await robotsService.getCrawlDelay(for: url)

        // Rate limit
        await rateLimiter.waitIfNeeded(
            for: url,
            minimumInterval: crawlDelay
        )

        // Fetch with proper User-Agent
        var request = URLRequest(url: url)
        request.setValue("Celestra/1.0 (+https://celestra.app/bot; contact@celestra.app)", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
}
```

### 2. Identify Your Crawler

```swift
// Always use descriptive User-Agent
let userAgent = "Celestra/1.0 (+https://celestra.app/bot; contact@celestra.app)"

var request = URLRequest(url: url)
request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
```

### 3. Respect TTL Headers

```swift
func fetchWithRespect(_ feed: Feed) async throws -> Data {
    let url = URL(string: feed.feedURL)!

    // Use feed's minimum update interval
    if let minInterval = feed.minUpdateInterval {
        await rateLimiter.waitIfNeeded(
            for: url,
            minimumInterval: minInterval
        )
    }

    // Use HTTP caching headers
    var request = URLRequest(url: url)

    if let etag = feed.etag {
        request.setValue(etag, forHTTPHeaderField: "If-None-Match")
    }

    if let lastModified = feed.lastModified {
        request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
    }

    let (data, response) = try await URLSession.shared.data(for: request)

    // Handle 304 Not Modified
    if let httpResponse = response as? HTTPURLResponse,
       httpResponse.statusCode == 304 {
        throw FetchError.notModified
    }

    return data
}
```

## See Also

- ``RateLimiter``
- ``RobotsTxtService``
- ``RobotsTxtService/RobotsRules``
- <doc:ConcurrencyPatterns>
