// Article.swift
// CelestraKit
//
// Created for Celestra on 2025-08-07.

public import Foundation

#if canImport(CoreData)
  public import CoreData
#endif

/// Article model that wraps Core Data entity for SwiftUI compatibility
public struct Article: Identifiable, Sendable, Codable {
  public let id: String  // Using GUID as ID
  public let feedID: UUID
  public let title: String
  public let excerpt: String?
  public let content: String?
  public let author: String?
  public let url: URL
  public let imageURL: URL?
  public let publishedDate: Date
  public let readDate: Date?
  public let isRead: Bool
  public let isStarred: Bool
  public let estimatedReadingTime: Int  // in minutes

  public init(
    id: String = UUID().uuidString,
    feedID: UUID,
    title: String,
    excerpt: String? = nil,
    content: String? = nil,
    author: String? = nil,
    url: URL,
    imageURL: URL? = nil,
    publishedDate: Date = Date(),
    readDate: Date? = nil,
    isRead: Bool = false,
    isStarred: Bool = false,
    estimatedReadingTime: Int = 5
  ) {
    self.id = id
    self.feedID = feedID
    self.title = title
    self.excerpt = excerpt
    self.content = content
    self.author = author
    self.url = url
    self.imageURL = imageURL
    self.publishedDate = publishedDate
    self.readDate = readDate
    self.isRead = isRead
    self.isStarred = isStarred
    self.estimatedReadingTime = estimatedReadingTime
  }

  /// Create Article from Core Data entity
  /// Returns nil if required fields are missing
  #if canImport(CoreData)
    public init?(from cdArticle: CDArticle) {
      guard let guid = cdArticle.guid,
        let feed = cdArticle.feed,
        let feedID = feed.id,
        let title = cdArticle.title,
        let url = cdArticle.url,
        let publishedDate = cdArticle.publishedDate
      else {
        assertionFailure(
          """
          CDArticle missing fields: guid=\(cdArticle.guid != nil), feed=\(cdArticle.feed != nil), \
          feedID=\(cdArticle.feed?.id != nil), title=\(cdArticle.title != nil), url=\(cdArticle.url != nil), \
          publishedDate=\(cdArticle.publishedDate != nil)
          """
        )
        return nil
      }

      self.id = guid
      self.feedID = feedID
      self.title = title
      self.excerpt = cdArticle.excerpt
      self.content = cdArticle.content
      self.author = cdArticle.author
      self.url = url
      self.imageURL = cdArticle.imageURL
      self.publishedDate = publishedDate
      self.readDate = cdArticle.readDate
      self.isRead = cdArticle.isRead
      self.isStarred = cdArticle.isStarred
      self.estimatedReadingTime = Int(cdArticle.estimatedReadingTime)
    }
  #endif

  /// Returns a copy with updated read status
  public func markAsRead(_ read: Bool = true) -> Article {
    Article(
      id: id,
      feedID: feedID,
      title: title,
      excerpt: excerpt,
      content: content,
      author: author,
      url: url,
      imageURL: imageURL,
      publishedDate: publishedDate,
      readDate: read ? Date() : nil,
      isRead: read,
      isStarred: isStarred,
      estimatedReadingTime: estimatedReadingTime
    )
  }

  /// Returns a copy with updated starred status
  public func toggleStarred() -> Article {
    Article(
      id: id,
      feedID: feedID,
      title: title,
      excerpt: excerpt,
      content: content,
      author: author,
      url: url,
      imageURL: imageURL,
      publishedDate: publishedDate,
      readDate: readDate,
      isRead: isRead,
      isStarred: !isStarred,
      estimatedReadingTime: estimatedReadingTime
    )
  }
}
