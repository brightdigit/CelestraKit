// FeedManager.swift
// CelestraKit
//
// Created for Celestra on 2025-10-27.
//

import Foundation

#if canImport(CoreData)
  public import CoreData
  public import Observation

  /// Feed sorting options (simplified for MVP)
  public enum FeedSortOrder: Sendable {
    case alphabetical
    case sortOrder
  }

  /// Feed data for batch operations
  public struct FeedData: Sendable {
    public let title: String
    public let url: URL
    public let category: FeedCategory
    public let subtitle: String?

    public init(title: String, url: URL, category: FeedCategory, subtitle: String? = nil) {
      self.title = title
      self.url = url
      self.category = category
      self.subtitle = subtitle
    }
  }

  /// Simplified feed manager focused on MVP essentials
  @Observable
  public final class FeedManager {
    // MARK: - Constants

    /// Maximum number of feeds allowed in MVP (can be configured for future tiers)
    public static let maximumFeedCount = 200

    // MARK: - Properties

    private let feedRepository: FeedRepository
    private let logger = createLogger(subsystem: "com.celestra.kit", category: "FeedManager")

    // MARK: - Initialization

    public init(feedRepository: FeedRepository = FeedRepository()) {
      self.feedRepository = feedRepository
    }

    // MARK: - Feed Count Management

    /// Get the current number of active feeds
    public func getCurrentFeedCount() -> Int {
      feedRepository.getFeedCount()
    }

    /// Check if adding new feeds would exceed the limit
    public func canAddFeeds(count: Int = 1) -> Bool {
      let currentCount = getCurrentFeedCount()
      return currentCount + count <= Self.maximumFeedCount
    }

    /// Get the number of feeds that can still be added
    public var remainingFeedSlots: Int {
      max(0, Self.maximumFeedCount - getCurrentFeedCount())
    }

    // MARK: - Add Operations

    /// Add a new feed with limit validation
    @discardableResult
    public func addFeed(
      title: String,
      url: URL,
      category: FeedCategory = .general,
      subtitle: String? = nil
    ) throws -> CDFeed {
      // Check if feed already exists
      if let existingFeed = feedRepository.getFeed(by: url) {
        #if canImport(OSLog)
          logger.warning("Attempted to add duplicate feed: \(url.absoluteString)")
        #endif
        throw FeedManagerError.feedAlreadyExists(url: url)
      }

      // Check feed limit
      let currentCount = getCurrentFeedCount()
      guard canAddFeeds(count: 1) else {
        #if canImport(OSLog)
          logger.error("Feed limit reached: \(currentCount)/\(Self.maximumFeedCount)")
        #endif
        throw FeedManagerError.feedLimitReached(
          currentCount: currentCount,
          limit: Self.maximumFeedCount
        )
      }

      // Add the feed
      let feed = feedRepository.addFeed(
        title: title,
        url: url,
        category: category,
        subtitle: subtitle
      )

      #if canImport(OSLog)
        logger.info("Successfully added feed: \(title) (\(currentCount + 1)/\(Self.maximumFeedCount))")
      #endif
      return feed
    }

    /// Add multiple feeds (throws on first error)
    public func addFeeds(_ feedData: [FeedData]) throws {
      // Pre-check: ensure we won't exceed the limit
      let currentCount = getCurrentFeedCount()
      let totalAfterAdd = currentCount + feedData.count

      if totalAfterAdd > Self.maximumFeedCount {
        #if canImport(OSLog)
          logger.error("Batch add would exceed limit: \(totalAfterAdd)/\(Self.maximumFeedCount)")
        #endif
        throw FeedManagerError.feedLimitReached(
          currentCount: currentCount,
          limit: Self.maximumFeedCount
        )
      }

      // Add feeds, throw on first error
      for data in feedData {
        try addFeed(
          title: data.title,
          url: data.url,
          category: data.category,
          subtitle: data.subtitle
        )
      }

      #if canImport(OSLog)
        logger.info("Successfully added \(feedData.count) feeds")
      #endif
    }

    // MARK: - Remove Operations

    /// Remove a feed by ID
    public func removeFeed(id feedId: UUID) throws {
      guard let feed = feedRepository.getFeed(by: feedId) else {
        #if canImport(OSLog)
          logger.error("Attempted to remove non-existent feed: \(feedId.uuidString)")
        #endif
        throw FeedManagerError.feedNotFound(id: feedId)
      }

      feedRepository.deleteFeed(feed)
      #if canImport(OSLog)
        logger.info("Successfully removed feed: \(feed.title ?? "Unknown")")
      #endif
    }

    /// Remove a feed by URL
    public func removeFeed(url: URL) throws {
      guard let feed = feedRepository.getFeed(by: url) else {
        #if canImport(OSLog)
          logger.error("Attempted to remove non-existent feed: \(url.absoluteString)")
        #endif
        throw FeedManagerError.feedNotFound(id: UUID())
      }

      feedRepository.deleteFeed(feed)
      #if canImport(OSLog)
        logger.info("Successfully removed feed: \(feed.title ?? "Unknown")")
      #endif
    }

    /// Remove multiple feeds (throws on first error)
    public func removeFeeds(ids feedIds: [UUID]) throws {
      for feedId in feedIds {
        try removeFeed(id: feedId)
      }

      #if canImport(OSLog)
        logger.info("Successfully removed \(feedIds.count) feeds")
      #endif
    }

    // MARK: - Query Operations

    /// Get feeds sorted by the specified order
    public func getFeeds(sortedBy sortOrder: FeedSortOrder = .alphabetical) -> [CDFeed] {
      let feeds = feedRepository.getAllFeeds()

      switch sortOrder {
      case .alphabetical:
        return feeds.sorted { ($0.title ?? "").localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending }

      case .sortOrder:
        return feeds.sorted { $0.sortOrder < $1.sortOrder }
      }
    }

    /// Update the sort order of feeds
    public func updateFeedOrder(_ feeds: [CDFeed]) {
      feedRepository.updateFeedOrder(feeds)
      #if canImport(OSLog)
        logger.info("Updated feed order for \(feeds.count) feeds")
      #endif
    }
  }
#endif
