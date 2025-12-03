// ArticleRepository.swift
// CelestraKit
//
// Created for Celestra on 2025-08-13.
//

#if canImport(CoreData)
  import CoreData
  import Foundation
  import Observation

  @Observable
  public final class ArticleRepository {
    private let coreDataStack: CoreDataStack
    private let logger = createLogger(subsystem: "com.celestra.kit", category: "ArticleRepository")

    public init(coreDataStack: CoreDataStack = .shared) {
      self.coreDataStack = coreDataStack
    }

    // MARK: - Article Queries

    public func getAllArticles(limit: Int? = nil) -> [CDArticle] {
      let request: NSFetchRequest<CDArticle> = CDArticle.fetchRequest()
      request.sortDescriptors = [
        NSSortDescriptor(keyPath: \CDArticle.publishedDate, ascending: false)
      ]
      request.predicate = NSPredicate(format: "feed.isActive == YES")

      if let limit = limit {
        request.fetchLimit = limit
      }

      do {
        return try coreDataStack.viewContext.fetch(request)
      } catch {
        logger.error("Failed to fetch articles: \(error.localizedDescription)")
        return []
      }
    }

    public func getUnreadArticles(limit: Int? = nil) -> [CDArticle] {
      let request: NSFetchRequest<CDArticle> = CDArticle.fetchRequest()
      request.predicate = NSPredicate(format: "isRead == NO AND feed.isActive == YES")
      request.sortDescriptors = [
        NSSortDescriptor(keyPath: \CDArticle.publishedDate, ascending: false)
      ]

      if let limit = limit {
        request.fetchLimit = limit
      }

      do {
        return try coreDataStack.viewContext.fetch(request)
      } catch {
        logger.error("Failed to fetch unread articles: \(error.localizedDescription)")
        return []
      }
    }

    public func getStarredArticles() -> [CDArticle] {
      let request: NSFetchRequest<CDArticle> = CDArticle.fetchRequest()
      request.predicate = NSPredicate(format: "isStarred == YES AND feed.isActive == YES")
      request.sortDescriptors = [
        NSSortDescriptor(keyPath: \CDArticle.publishedDate, ascending: false)
      ]

      do {
        return try coreDataStack.viewContext.fetch(request)
      } catch {
        logger.error("Failed to fetch starred articles: \(error.localizedDescription)")
        return []
      }
    }

    public func getArticles(for feed: CDFeed, limit: Int? = nil) -> [CDArticle] {
      let request: NSFetchRequest<CDArticle> = CDArticle.fetchRequest()
      request.predicate = NSPredicate(format: "feed == %@", feed)
      request.sortDescriptors = [
        NSSortDescriptor(keyPath: \CDArticle.publishedDate, ascending: false)
      ]

      if let limit = limit {
        request.fetchLimit = limit
      }

      do {
        return try coreDataStack.viewContext.fetch(request)
      } catch {
        logger.error("Failed to fetch articles for feed: \(error.localizedDescription)")
        return []
      }
    }

    // MARK: - Article Management

    public func getArticle(by guid: String) -> CDArticle? {
      let request: NSFetchRequest<CDArticle> = CDArticle.fetchRequest()
      request.predicate = NSPredicate(format: "guid == %@", guid)
      request.fetchLimit = 1

      do {
        return try coreDataStack.viewContext.fetch(request).first
      } catch {
        logger.error("Failed to fetch article by GUID: \(error.localizedDescription)")
        return nil
      }
    }

    public func addArticle(
      guid: String,
      title: String,
      url: URL,
      feed: CDFeed,
      content: String? = nil,
      excerpt: String? = nil,
      author: String? = nil,
      publishedDate: Date = Date(),
      estimatedReadingTime: Int = 5
    ) throws -> CDArticle {
      // Check for existing article - throw instead of returning nil
      if getArticle(by: guid) != nil {
        throw CoreDataError.duplicateEntry(guid)
      }

      let article = CDArticle(context: coreDataStack.viewContext)
      article.guid = guid
      article.title = title
      article.url = url
      article.content = content
      article.excerpt = excerpt
      article.author = author
      article.publishedDate = publishedDate
      article.estimatedReadingTime = Int32(estimatedReadingTime)
      article.feed = feed

      // Save and propagate errors instead of ignoring them
      do {
        try coreDataStack.viewContext.save()
        logger.info("Added new article: \(title)")
        return article
      } catch {
        throw CoreDataError.saveFailed(underlying: error)
      }
    }

    public func markAsRead(_ article: CDArticle, read: Bool = true) {
      article.markAsRead(read)
      coreDataStack.saveIgnoringErrors()
      logger.debug("Marked article as \(read ? "read" : "unread"): \(article.title ?? "Unknown")")
    }

    public func markAllAsRead(for feed: CDFeed? = nil) {
      let request: NSFetchRequest<CDArticle> = CDArticle.fetchRequest()

      if let feed = feed {
        request.predicate = NSPredicate(format: "feed == %@ AND isRead == NO", feed)
      } else {
        request.predicate = NSPredicate(format: "isRead == NO AND feed.isActive == YES")
      }

      do {
        let articles = try coreDataStack.viewContext.fetch(request)
        for article in articles {
          article.markAsRead(true)
        }
        coreDataStack.saveIgnoringErrors()
        logger.info("Marked \(articles.count) articles as read")
      } catch {
        logger.error("Failed to mark all as read: \(error.localizedDescription)")
      }
    }

    public func toggleStarred(_ article: CDArticle) {
      article.toggleStarred()
      coreDataStack.saveIgnoringErrors()
      logger.debug("Toggled starred status for article: \(article.title ?? "Unknown")")
    }

    public func deleteArticle(_ article: CDArticle) {
      coreDataStack.viewContext.delete(article)
      coreDataStack.saveIgnoringErrors()
      logger.info("Deleted article: \(article.title ?? "Unknown")")
    }

    // MARK: - Search

    public func searchArticles(query: String, limit: Int = 50) -> [CDArticle] {
      guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        return []
      }

      let request: NSFetchRequest<CDArticle> = CDArticle.fetchRequest()
      request.predicate = NSPredicate(
        format: "(title CONTAINS[cd] %@ OR content CONTAINS[cd] %@ OR author CONTAINS[cd] %@) AND feed.isActive == YES",
        query,
        query,
        query
      )
      request.sortDescriptors = [
        NSSortDescriptor(keyPath: \CDArticle.publishedDate, ascending: false)
      ]
      request.fetchLimit = limit

      do {
        return try coreDataStack.viewContext.fetch(request)
      } catch {
        logger.error("Failed to search articles: \(error.localizedDescription)")
        return []
      }
    }

    // MARK: - Statistics

    public func getUnreadCount(for feed: CDFeed? = nil) -> Int {
      let request: NSFetchRequest<CDArticle> = CDArticle.fetchRequest()

      if let feed = feed {
        request.predicate = NSPredicate(format: "feed == %@ AND isRead == NO", feed)
      } else {
        request.predicate = NSPredicate(format: "isRead == NO AND feed.isActive == YES")
      }

      do {
        return try coreDataStack.viewContext.count(for: request)
      } catch {
        logger.error("Failed to get unread count: \(error.localizedDescription)")
        return 0
      }
    }

    public func getStarredCount() -> Int {
      let request: NSFetchRequest<CDArticle> = CDArticle.fetchRequest()
      request.predicate = NSPredicate(format: "isStarred == YES AND feed.isActive == YES")

      do {
        return try coreDataStack.viewContext.count(for: request)
      } catch {
        logger.error("Failed to get starred count: \(error.localizedDescription)")
        return 0
      }
    }
  }

  // MARK: - Fetch Requests
  extension CDArticle {
    fileprivate static func fetchRequest() -> NSFetchRequest<CDArticle> {
      NSFetchRequest<CDArticle>(entityName: "CDArticle")
    }
  }
#endif
