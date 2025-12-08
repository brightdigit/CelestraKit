// Article+CloudKit.swift
// CelestraKit
//
// Created for Celestra on 2025-12-07.
//

#if canImport(CloudKit)
  public import CloudKit
  public import Foundation

  extension Article {
    /// Initialize Article from CloudKit record
    /// Note: contentHash is recalculated from title/url/guid; expiresAt is derived from ttlDays
    public init(from record: CKRecord) throws {
      guard let feedRecordName = record["feedRecordName"] as? String,
        let guid = record["guid"] as? String,
        let title = record["title"] as? String,
        let url = record["url"] as? String
      else {
        throw CloudKitConversionError.missingRequiredField
      }

      // Calculate ttlDays from fetchedAt and expiresAt if available
      let fetchedAt = record["fetchedAt"] as? Date ?? Date()
      let expiresAt = record["expiresAt"] as? Date
      let ttlDays: Int
      if let expiresAt = expiresAt {
        let interval = expiresAt.timeIntervalSince(fetchedAt)
        ttlDays = max(1, Int(interval / (24 * 60 * 60)))
      } else {
        ttlDays = 30  // Default TTL
      }

      self.init(
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
        fetchedAt: fetchedAt,
        ttlDays: ttlDays,
        wordCount: record["wordCount"] as? Int,
        estimatedReadingTime: record["estimatedReadingTime"] as? Int,
        language: record["language"] as? String,
        tags: record["tags"] as? [String] ?? []
      )
    }

    /// Convert Article to CloudKit record
    public func toCKRecord() -> CKRecord {
      let recordID =
        recordName.map { CKRecord.ID(recordName: $0) }
        ?? CKRecord.ID(recordName: UUID().uuidString)
      let record = CKRecord(recordType: "Article", recordID: recordID)

      record["feedRecordName"] = feedRecordName
      record["guid"] = guid
      record["title"] = title
      record["excerpt"] = excerpt
      record["content"] = content
      record["contentText"] = contentText
      record["author"] = author
      record["url"] = url
      record["imageURL"] = imageURL
      record["publishedDate"] = publishedDate
      record["fetchedAt"] = fetchedAt
      record["expiresAt"] = expiresAt
      record["contentHash"] = contentHash
      record["wordCount"] = wordCount
      record["estimatedReadingTime"] = estimatedReadingTime
      record["language"] = language
      record["tags"] = tags

      return record
    }
  }
#endif
