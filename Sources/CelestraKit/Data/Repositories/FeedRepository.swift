// FeedRepository.swift
// CelestraKit
//
// Created for Celestra on 2025-08-13.
//

#if canImport(CoreData)
  import CoreData
  import Foundation
  import Observation

  @Observable
  public final class FeedRepository {
    private let coreDataStack: CoreDataStackProtocol
    private let logger = createLogger(subsystem: "com.celestra.kit", category: "FeedRepository")

    public init(coreDataStack: CoreDataStackProtocol = CoreDataStack.shared) {
      self.coreDataStack = coreDataStack
    }

    // MARK: - Feed Operations

    public func getAllFeeds() -> [CDFeed] {
      let request: NSFetchRequest<CDFeed> = CDFeed.fetchRequest()
      request.sortDescriptors = [
        NSSortDescriptor(keyPath: \CDFeed.sortOrder, ascending: true),
        NSSortDescriptor(keyPath: \CDFeed.title, ascending: true),
      ]
      request.predicate = NSPredicate(format: "isActive == YES")

      do {
        return try coreDataStack.viewContext.fetch(request)
      } catch {
        logger.error("Failed to fetch feeds: \(error.localizedDescription)")
        return []
      }
    }

    public func getActiveFeeds() -> [CDFeed] {
      let request: NSFetchRequest<CDFeed> = CDFeed.fetchRequest()
      request.predicate = NSPredicate(format: "isActive == YES")
      request.sortDescriptors = [
        NSSortDescriptor(keyPath: \CDFeed.sortOrder, ascending: true),
        NSSortDescriptor(keyPath: \CDFeed.title, ascending: true),
      ]

      do {
        return try coreDataStack.viewContext.fetch(request)
      } catch {
        logger.error("Failed to fetch active feeds: \(error.localizedDescription)")
        return []
      }
    }

    public func getFeed(by id: UUID) -> CDFeed? {
      let request: NSFetchRequest<CDFeed> = CDFeed.fetchRequest()
      request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
      request.fetchLimit = 1

      do {
        return try coreDataStack.viewContext.fetch(request).first
      } catch {
        logger.error("Failed to fetch feed by ID: \(error.localizedDescription)")
        return nil
      }
    }

    public func getFeed(by url: URL) -> CDFeed? {
      let request: NSFetchRequest<CDFeed> = CDFeed.fetchRequest()
      request.predicate = NSPredicate(format: "url == %@", url as CVarArg)
      request.fetchLimit = 1

      do {
        return try coreDataStack.viewContext.fetch(request).first
      } catch {
        logger.error("Failed to fetch feed by URL: \(error.localizedDescription)")
        return nil
      }
    }

    public func addFeed(
      title: String,
      url: URL,
      category: FeedCategory = .general,
      subtitle: String? = nil
    ) -> CDFeed {
      let feed = CDFeed(context: coreDataStack.viewContext)
      feed.title = title
      feed.url = url
      feed.category = category.rawValue
      feed.subtitle = subtitle
      feed.sortOrder = Int32(getAllFeeds().count)

      coreDataStack.saveIgnoringErrors()
      logger.info("Added new feed: \(title)")

      return feed
    }

    public func deleteFeed(_ feed: CDFeed) {
      coreDataStack.viewContext.delete(feed)
      coreDataStack.saveIgnoringErrors()
      logger.info("Deleted feed: \(feed.title ?? "Unknown")")
    }

    public func updateFeedOrder(_ feeds: [CDFeed]) {
      for (index, feed) in feeds.enumerated() {
        feed.sortOrder = Int32(index)
      }
      coreDataStack.saveIgnoringErrors()
      logger.info("Updated feed order")
    }

    public func save() throws {
      try coreDataStack.viewContext.save()
    }

    // MARK: - Statistics

    public func getFeedCount() -> Int {
      let request: NSFetchRequest<CDFeed> = CDFeed.fetchRequest()
      request.predicate = NSPredicate(format: "isActive == YES")

      do {
        return try coreDataStack.viewContext.count(for: request)
      } catch {
        logger.error("Failed to get feed count: \(error.localizedDescription)")
        return 0
      }
    }

    public func getTotalUnreadCount() -> Int {
      let request: NSFetchRequest<CDArticle> = CDArticle.fetchRequest()
      request.predicate = NSPredicate(format: "isRead == NO AND feed.isActive == YES")

      do {
        return try coreDataStack.viewContext.count(for: request)
      } catch {
        logger.error("Failed to get unread count: \(error.localizedDescription)")
        return 0
      }
    }
  }

  // MARK: - Fetch Requests
  extension CDFeed {
    fileprivate static func fetchRequest() -> NSFetchRequest<CDFeed> {
      NSFetchRequest<CDFeed>(entityName: "CDFeed")
    }
  }

  extension CDArticle {
    fileprivate static func fetchRequest() -> NSFetchRequest<CDArticle> {
      NSFetchRequest<CDArticle>(entityName: "CDArticle")
    }
  }
#endif
