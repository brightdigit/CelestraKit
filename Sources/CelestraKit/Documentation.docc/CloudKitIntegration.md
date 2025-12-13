# CloudKit Integration

Comprehensive guide to integrating CelestraKit with CloudKit in production.

## Overview

CelestraKit models are designed for CloudKit's **public database**, enabling efficient content sharing across all users without requiring authentication.

## CloudKit Setup

### 1. Enable CloudKit Capability

In Xcode:
1. Select your target
2. Go to "Signing & Capabilities"
3. Add "CloudKit" capability
4. Create/select CloudKit container

### 2. Configure Container

```swift
import CloudKit

let container = CKContainer(identifier: "iCloud.com.example.celestra")
let publicDatabase = container.publicCloudDatabase
```

### 3. Define Record Types

Create these record types in CloudKit Dashboard:

**Feed Record Type** - Type name: `Feed`

Required fields:
- `feedURL` (String, indexed, queryable)
- `title` (String, indexed)
- `qualityScore` (Int64, indexed)
- `isVerified` (Int64)
- `isFeatured` (Int64)
- `isActive` (Int64)
- `totalAttempts` (Int64)
- `successfulAttempts` (Int64)
- `failureCount` (Int64)
- `subscriberCount` (Int64)
- `addedAt` (Date/Time, indexed)
- `tags` (String List)

Optional fields:
- `description`, `category`, `imageURL`, `siteURL`, `language`
- `lastVerified`, `updateFrequency`, `lastAttempted`
- `etag`, `lastModified`, `lastFailureReason`, `minUpdateInterval`

**Article Record Type** - Type name: `Article`

Required fields:
- `feedRecordName` (String, indexed, queryable)
- `guid` (String, indexed)
- `title` (String, indexed)
- `url` (String, indexed)
- `contentHash` (String, indexed)
- `fetchedAt` (Date/Time, indexed)
- `expiresAt` (Date/Time, indexed)

Optional fields:
- `excerpt`, `content`, `contentText`, `author`, `imageURL`
- `publishedDate`, `wordCount`, `estimatedReadingTime`
- `language`, `tags`

## CRUD Operations

### Create

```swift
func saveFeed(_ feed: Feed) async throws -> Feed {
    let record = CKRecord(recordType: "Feed")

    // Map Feed to CKRecord
    record["feedURL"] = feed.feedURL
    record["title"] = feed.title
    record["qualityScore"] = feed.qualityScore as CKRecordValue
    record["isVerified"] = feed.isVerified ? 1 : 0
    record["isFeatured"] = feed.isFeatured ? 1 : 0
    // ... map other fields

    let savedRecord = try await publicDatabase.save(record)
    return try mapToFeed(savedRecord)
}
```

### Read

```swift
func fetchFeed(recordName: String) async throws -> Feed {
    let recordID = CKRecord.ID(recordName: recordName)
    let record = try await publicDatabase.record(for: recordID)
    return try mapToFeed(record)
}
```

### Update (with Optimistic Locking)

```swift
func updateFeed(_ feed: Feed) async throws -> Feed {
    guard let recordName = feed.recordName,
          let changeTag = feed.recordChangeTag else {
        throw CloudKitError.missingRecordInfo
    }

    let recordID = CKRecord.ID(recordName: recordName)

    // Fetch current record
    let record = try await publicDatabase.record(for: recordID)

    // Check for conflicts
    guard record.recordChangeTag == changeTag else {
        throw CloudKitError.conflictDetected
    }

    // Update fields
    record["title"] = feed.title
    record["qualityScore"] = feed.qualityScore as CKRecordValue
    // ... update other fields

    // Save with change tag
    let savedRecord = try await publicDatabase.save(record)
    return try mapToFeed(savedRecord)
}
```

### Delete

```swift
func deleteFeed(recordName: String) async throws {
    let recordID = CKRecord.ID(recordName: recordName)
    try await publicDatabase.deleteRecord(withID: recordID)
}
```

## Querying

### Query Feeds by Category

```swift
func fetchFeeds(category: String) async throws -> [Feed] {
    let predicate = NSPredicate(format: "category == %@", category)
    let query = CKQuery(recordType: "Feed", predicate: predicate)
    query.sortDescriptors = [
        NSSortDescriptor(key: "qualityScore", ascending: false)
    ]

    let (results, _) = try await publicDatabase.records(matching: query)

    return try results.compactMap { try $0.1.get() }
        .compactMap { try? mapToFeed($0) }
}
```

### Query Articles by Feed

```swift
func fetchArticles(feedRecordName: String) async throws -> [Article] {
    let predicate = NSPredicate(
        format: "feedRecordName == %@",
        feedRecordName
    )
    let query = CKQuery(recordType: "Article", predicate: predicate)
    query.sortDescriptors = [
        NSSortDescriptor(key: "publishedDate", ascending: false)
    ]

    let (results, _) = try await publicDatabase.records(matching: query)

    return try results.compactMap { try $0.1.get() }
        .compactMap { try? mapToArticle($0) }
}
```

### Query Non-Expired Articles

```swift
func fetchFreshArticles(feedRecordName: String) async throws -> [Article] {
    let predicate = NSPredicate(
        format: "feedRecordName == %@ AND expiresAt > %@",
        feedRecordName,
        Date() as NSDate
    )
    let query = CKQuery(recordType: "Article", predicate: predicate)

    let (results, _) = try await publicDatabase.records(matching: query)

    return try results.compactMap { try $0.1.get() }
        .compactMap { try? mapToArticle($0) }
}
```

## Concurrency-Safe Operations

### Using Actors

```swift
actor FeedManager {
    private let database: CKDatabase
    private var cache: [String: Feed] = [:]

    init(database: CKDatabase) {
        self.database = database
    }

    func getFeed(recordName: String) async throws -> Feed {
        // Check cache
        if let cached = cache[recordName] {
            return cached
        }

        // Fetch from CloudKit
        let recordID = CKRecord.ID(recordName: recordName)
        let record = try await database.record(for: recordID)
        let feed = try mapToFeed(record)

        // Cache result
        cache[recordName] = feed

        return feed
    }

    func clearCache() {
        cache.removeAll()
    }
}
```

## Best Practices

### 1. Batch Operations

```swift
func saveFeeds(_ feeds: [Feed]) async throws -> [Feed] {
    let records = feeds.map { feed -> CKRecord in
        let record = CKRecord(recordType: "Feed")
        record["feedURL"] = feed.feedURL
        record["title"] = feed.title
        // ... map other fields
        return record
    }

    let savedRecords = try await publicDatabase.modifyRecords(
        saving: records,
        deleting: []
    ).saveResults.compactMap { try? $0.value.get() }

    return try savedRecords.compactMap { try? mapToFeed($0) }
}
```

### 2. Handle Conflicts

```swift
func handleConflict(
    clientFeed: Feed,
    serverRecord: CKRecord
) throws -> Feed {
    // Server wins for most fields
    var mergedFeed = try mapToFeed(serverRecord)

    // Client wins for user-specific data (if any)
    // (In this case, all fields are server-managed)

    return mergedFeed
}
```

### 3. Error Handling

```swift
enum CloudKitError: Error {
    case missingRecordInfo
    case conflictDetected
    case networkFailure
}

func fetchWithRetry<T>(
    _ operation: @Sendable () async throws -> T,
    maxRetries: Int = 3
) async throws -> T {
    var lastError: Error?

    for attempt in 0..<maxRetries {
        do {
            return try await operation()
        } catch {
            lastError = error

            // Exponential backoff
            let delay = pow(2.0, Double(attempt))
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    }

    throw lastError ?? CloudKitError.networkFailure
}
```

## Mapping Helpers

### CKRecord to Feed

```swift
func mapToFeed(_ record: CKRecord) throws -> Feed {
    guard let feedURL = record["feedURL"] as? String,
          let title = record["title"] as? String else {
        throw CloudKitError.missingRecordInfo
    }

    return Feed(
        recordName: record.recordID.recordName,
        recordChangeTag: record.recordChangeTag,
        feedURL: feedURL,
        title: title,
        description: record["description"] as? String,
        category: record["category"] as? String,
        imageURL: record["imageURL"] as? String,
        siteURL: record["siteURL"] as? String,
        language: record["language"] as? String,
        isFeatured: (record["isFeatured"] as? Int64) == 1,
        isVerified: (record["isVerified"] as? Int64) == 1,
        qualityScore: record["qualityScore"] as? Int ?? 50,
        subscriberCount: record["subscriberCount"] as? Int64 ?? 0,
        addedAt: record["addedAt"] as? Date ?? Date(),
        lastVerified: record["lastVerified"] as? Date,
        updateFrequency: record["updateFrequency"] as? Double,
        tags: record["tags"] as? [String] ?? [],
        totalAttempts: record["totalAttempts"] as? Int64 ?? 0,
        successfulAttempts: record["successfulAttempts"] as? Int64 ?? 0,
        lastAttempted: record["lastAttempted"] as? Date,
        isActive: (record["isActive"] as? Int64) == 1,
        etag: record["etag"] as? String,
        lastModified: record["lastModified"] as? String,
        failureCount: record["failureCount"] as? Int64 ?? 0,
        lastFailureReason: record["lastFailureReason"] as? String,
        minUpdateInterval: record["minUpdateInterval"] as? Double
    )
}
```

### CKRecord to Article

```swift
func mapToArticle(_ record: CKRecord) throws -> Article {
    guard let feedRecordName = record["feedRecordName"] as? String,
          let guid = record["guid"] as? String,
          let title = record["title"] as? String,
          let url = record["url"] as? String else {
        throw CloudKitError.missingRecordInfo
    }

    return Article(
        recordName: record.recordID.recordName,
        recordChangeTag: record.recordChangeTag,
        feedRecordName: feedRecordName,
        guid: guid,
        title: title,
        excerpt: record["excerpt"] as? String,
        content: record["content"] as? String,
        contentText: record["contentText"] as? String,
        author: record["author"] as? String,
        url: url,
        imageURL: record["imageURL"] as? String,
        publishedDate: record["publishedDate"] as? Date,
        fetchedAt: record["fetchedAt"] as? Date ?? Date(),
        ttlDays: 30, // Will be overridden by expiresAt
        wordCount: record["wordCount"] as? Int,
        estimatedReadingTime: record["estimatedReadingTime"] as? Int,
        language: record["language"] as? String,
        tags: record["tags"] as? [String] ?? []
    )
}
```

## See Also

- <doc:ModelArchitecture>
- <doc:ConcurrencyPatterns>
- ``Feed``
- ``Article``
