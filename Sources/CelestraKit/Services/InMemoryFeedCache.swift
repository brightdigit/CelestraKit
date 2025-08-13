//
//  InMemoryFeedCache.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

public import Foundation

/// Simple in-memory implementation of FeedCacheProtocol
/// Placeholder until CloudKit/SwiftData/CoreData/GRDB implementation is added
public actor InMemoryFeedCache: FeedCacheProtocol {
  private struct CacheEntry {
    let feed: ParsedFeed
    let expirationDate: Date
    let cachedAt: Date

    var isExpired: Bool {
      Date() > expirationDate
    }
  }

  private var cache: [URL: CacheEntry] = [:]
  private let config: FeedCacheConfig
  private var lastCleanup = Date()

  public init(config: FeedCacheConfig = FeedCacheConfig()) {
    self.config = config
  }

  public func get(for url: URL) async throws -> ParsedFeed? {
    await cleanupIfNeeded()

    guard let entry = cache[url] else {
      return nil
    }

    guard !entry.isExpired else {
      cache.removeValue(forKey: url)
      throw FeedCacheError.entryExpired
    }

    return entry.feed
  }

  public func set(_ feed: ParsedFeed, for url: URL, expirationDate: Date) async throws {
    await cleanupIfNeeded()

    // Check if cache is full (if maxCacheSize is set)
    if let maxSize = config.maxCacheSize, cache.count >= maxSize {
      await evictOldestEntry()
    }

    let entry = CacheEntry(
      feed: feed,
      expirationDate: expirationDate,
      cachedAt: Date()
    )

    cache[url] = entry
  }

  public func remove(for url: URL) async throws {
    cache.removeValue(forKey: url)
  }

  public func clear() async throws {
    cache.removeAll()
    lastCleanup = Date()
  }

  public func cleanExpired() async throws {
    let expiredKeys = cache.compactMap { key, entry in
      entry.isExpired ? key : nil
    }

    for key in expiredKeys {
      cache.removeValue(forKey: key)
    }

    lastCleanup = Date()
  }

  // MARK: - Private Methods

  private func cleanupIfNeeded() async {
    let timeSinceLastCleanup = Date().timeIntervalSince(lastCleanup)

    if timeSinceLastCleanup > config.cleanupInterval {
      try? await cleanExpired()
    }
  }

  private func evictOldestEntry() async {
    guard !cache.isEmpty else { return }

    // Find the entry with the oldest cachedAt date
    let oldestKey = cache.min { lhs, rhs in
      lhs.value.cachedAt < rhs.value.cachedAt
    }?.key

    if let keyToRemove = oldestKey {
      cache.removeValue(forKey: keyToRemove)
    }
  }
}
