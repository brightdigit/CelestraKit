// CDArticle.swift
// CelestraKit
//
// Created for Celestra on 2025-08-13.
//

#if canImport(CoreData)
  public import CoreData
  public import Foundation

  #if canImport(CloudKit)
    public import CloudKit
  #endif

  @objc(CDArticle)
  public final class CDArticle: NSManagedObject {
    @NSManaged public var guid: String?
    @NSManaged public var title: String?
    @NSManaged public var excerpt: String?
    @NSManaged public var content: String?
    @NSManaged public var author: String?
    @NSManaged public var url: URL?
    @NSManaged public var imageURL: URL?
    @NSManaged public var publishedDate: Date?
    @NSManaged public var readDate: Date?
    @NSManaged public var isRead: Bool
    @NSManaged public var isStarred: Bool
    @NSManaged public var estimatedReadingTime: Int32
    @NSManaged public var cachedContentHash: String?
    @NSManaged public var feed: CDFeed?

    #if canImport(CloudKit)
      // CloudKit support
      @NSManaged public var ckRecordID: CKRecord.ID?
      @NSManaged public var ckRecordSystemFields: Data?
    #endif

    public override func awakeFromInsert() {
      super.awakeFromInsert()
      publishedDate = Date()
      isRead = false
      isStarred = false
      estimatedReadingTime = 5  // Default 5 minutes
    }
  }
#endif
