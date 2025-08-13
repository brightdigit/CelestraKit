//
//  FeedCacheProtocol.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

public import Foundation

/// Protocol for feed caching abstraction
/// Designed to support in-memory, CloudKit, SwiftData, CoreData, or GRDB implementations
public protocol FeedCacheProtocol: Sendable {
  /// Retrieves a cached parsed feed
  /// - Parameter url: The feed URL used as cache key
  /// - Returns: Cached ParsedFeed if available and not expired, nil otherwise
  func get(for url: URL) async throws -> ParsedFeed?

  /// Stores a parsed feed in cache
  /// - Parameters:
  ///   - feed: The parsed feed to cache
  ///   - url: The feed URL to use as cache key
  ///   - expirationDate: When this cache entry should expire
  func set(_ feed: ParsedFeed, for url: URL, expirationDate: Date) async throws

  /// Removes a cached entry
  /// - Parameter url: The feed URL to remove from cache
  func remove(for url: URL) async throws

  /// Clears all cached entries
  func clear() async throws

  /// Removes expired cache entries
  func cleanExpired() async throws
}

/// Cache configuration for feed caching behavior
public struct FeedCacheConfig: Sendable {
  public let defaultExpirationInterval: TimeInterval
  public let maxCacheSize: Int?
  public let cleanupInterval: TimeInterval

  public init(
    defaultExpirationInterval: TimeInterval = 3600,  // 1 hour
    maxCacheSize: Int? = nil,
    cleanupInterval: TimeInterval = 86400  // 24 hours
  ) {
    self.defaultExpirationInterval = defaultExpirationInterval
    self.maxCacheSize = maxCacheSize
    self.cleanupInterval = cleanupInterval
  }
}

/// Errors that can occur during cache operations
public enum FeedCacheError: Error, Sendable {
  case entryNotFound
  case entryExpired
  case cacheCorrupted
  case storageError(underlying: Error)
  case cacheFull

  public var localizedDescription: String {
    switch self {
    case .entryNotFound:
      return "Cache entry not found"
    case .entryExpired:
      return "Cache entry has expired"
    case .cacheCorrupted:
      return "Cache data is corrupted"
    case .storageError(let underlying):
      return "Storage error: \(underlying.localizedDescription)"
    case .cacheFull:
      return "Cache is full"
    }
  }
}
