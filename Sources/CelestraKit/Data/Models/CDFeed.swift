// CDFeed.swift
// CelestraKit
//
// Created for Celestra on 2025-08-13.
//

#if canImport(CoreData)
  #if canImport(CloudKit)
    public import CloudKit
  #endif
  public import CoreData
  public import Foundation

  @objc(CDFeed)
  public final class CDFeed: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var subtitle: String?
    @NSManaged public var url: URL?
    @NSManaged public var imageURL: URL?
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var lastFetched: Date?
    @NSManaged public var category: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var sortOrder: Int32
    @NSManaged public var updateFrequency: TimeInterval
    @NSManaged public var etag: String?
    @NSManaged public var articles: Set<CDArticle>?

    #if canImport(CloudKit)
      // CloudKit support
      @NSManaged public var ckRecordID: CKRecord.ID?
      @NSManaged public var ckRecordSystemFields: Data?
    #endif

    public override func awakeFromInsert() {
      super.awakeFromInsert()
      id = UUID()
      lastUpdated = Date()
      lastFetched = nil
      isActive = true
      sortOrder = 0
      updateFrequency = 3600  // 1 hour default
      category = FeedCategory.general.rawValue
    }
  }

  // MARK: - Computed Properties
  extension CDFeed {
    public var unreadCount: Int {
      articles?.filter { !$0.isRead }.count ?? 0
    }

    public var feedCategory: FeedCategory {
      category.flatMap(FeedCategory.init(rawValue:)) ?? .general
    }

    public var needsUpdate: Bool {
      guard let lastFetched = lastFetched else { return true }
      return Date().timeIntervalSince(lastFetched) > updateFrequency
    }
  }

  // MARK: - Core Data Relationships
  extension CDFeed {
    @objc(addArticlesObject:)
    @NSManaged public func addToArticles(_ article: CDArticle)

    @objc(removeArticlesObject:)
    @NSManaged public func removeFromArticles(_ article: CDArticle)

    @objc(addArticles:)
    @NSManaged public func addToArticles(_ articles: Set<CDArticle>)

    @objc(removeArticles:)
    @NSManaged public func removeFromArticles(_ articles: Set<CDArticle>)
  }
#endif
