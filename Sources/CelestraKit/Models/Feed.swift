// Feed.swift
// CelestraKit
//
// Created for Celestra on 2025-08-07.

public import Foundation

#if canImport(CoreData)
  public import CoreData
#endif

/// Feed model that wraps Core Data entity for SwiftUI compatibility
public struct Feed: Identifiable, Sendable {
  public let id: UUID
  public let title: String
  public let subtitle: String?
  public let url: URL
  public let imageURL: URL?
  public let lastUpdated: Date
  public let unreadCount: Int
  public let category: FeedCategory
  public let isActive: Bool
  public let sortOrder: Int

  public init(
    id: UUID = UUID(),
    title: String,
    subtitle: String? = nil,
    url: URL,
    imageURL: URL? = nil,
    lastUpdated: Date = Date(),
    unreadCount: Int = 0,
    category: FeedCategory = .general,
    isActive: Bool = true,
    sortOrder: Int = 0
  ) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
    self.url = url
    self.imageURL = imageURL
    self.lastUpdated = lastUpdated
    self.unreadCount = unreadCount
    self.category = category
    self.isActive = isActive
    self.sortOrder = sortOrder
  }

  /// Create Feed from Core Data entity
  /// Returns nil if required fields are missing
  #if canImport(CoreData)
    public init?(from cdFeed: CDFeed) {
      guard let id = cdFeed.id,
        let title = cdFeed.title,
        let url = cdFeed.url,
        let lastUpdated = cdFeed.lastUpdated
      else {
        assertionFailure(
          """
          CDFeed missing required fields: id=\(cdFeed.id != nil), \
          title=\(cdFeed.title != nil), url=\(cdFeed.url != nil), \
          lastUpdated=\(cdFeed.lastUpdated != nil)
          """
        )
        return nil
      }

      self.id = id
      self.title = title
      self.subtitle = cdFeed.subtitle
      self.url = url
      self.imageURL = cdFeed.imageURL
      self.lastUpdated = lastUpdated
      self.unreadCount = cdFeed.unreadCount
      self.category = cdFeed.feedCategory
      self.isActive = cdFeed.isActive
      self.sortOrder = Int(cdFeed.sortOrder)
    }
  #endif
}
