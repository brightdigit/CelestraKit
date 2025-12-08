// Feed+CloudKit.swift
// CelestraKit
//
// Created for Celestra on 2025-12-07.
//

#if canImport(CloudKit)
  public import CloudKit
  public import Foundation

  extension Feed {
    /// Initialize Feed from CloudKit record
    public init(from record: CKRecord) throws {
      guard let feedURL = record["feedURL"] as? String,
        let title = record["title"] as? String
      else {
        throw CloudKitConversionError.missingRequiredField
      }

      self.init(
        recordName: record.recordID.recordName,
        recordChangeTag: record.recordChangeTag,
        feedURL: feedURL,
        title: title,
        description: record["description"] as? String,
        category: record["category"] as? String,
        imageURL: record["imageURL"] as? String,
        siteURL: record["siteURL"] as? String,
        language: record["language"] as? String,
        isFeatured: record["isFeatured"] as? Bool ?? false,
        isVerified: record["isVerified"] as? Bool ?? false,
        qualityScore: record["qualityScore"] as? Int ?? 50,
        subscriberCount: record["subscriberCount"] as? Int64 ?? 0,
        addedAt: record["addedAt"] as? Date ?? Date(),
        lastVerified: record["lastVerified"] as? Date,
        updateFrequency: record["updateFrequency"] as? TimeInterval,
        tags: record["tags"] as? [String] ?? [],
        totalAttempts: record["totalAttempts"] as? Int64 ?? 0,
        successfulAttempts: record["successfulAttempts"] as? Int64 ?? 0,
        lastAttempted: record["lastAttempted"] as? Date,
        isActive: record["isActive"] as? Bool ?? true,
        etag: record["etag"] as? String,
        lastModified: record["lastModified"] as? String,
        failureCount: record["failureCount"] as? Int64 ?? 0,
        lastFailureReason: record["lastFailureReason"] as? String,
        minUpdateInterval: record["minUpdateInterval"] as? TimeInterval
      )
    }

    /// Convert Feed to CloudKit record
    public func toCKRecord() -> CKRecord {
      let recordID =
        recordName.map { CKRecord.ID(recordName: $0) }
        ?? CKRecord.ID(recordName: UUID().uuidString)
      let record = CKRecord(recordType: "Feed", recordID: recordID)

      record["feedURL"] = feedURL
      record["title"] = title
      record["description"] = description
      record["category"] = category
      record["imageURL"] = imageURL
      record["siteURL"] = siteURL
      record["language"] = language
      record["isFeatured"] = isFeatured
      record["isVerified"] = isVerified
      record["qualityScore"] = qualityScore
      record["subscriberCount"] = subscriberCount
      record["addedAt"] = addedAt
      record["lastVerified"] = lastVerified
      record["updateFrequency"] = updateFrequency
      record["tags"] = tags
      record["totalAttempts"] = totalAttempts
      record["successfulAttempts"] = successfulAttempts
      record["lastAttempted"] = lastAttempted
      record["isActive"] = isActive
      record["etag"] = etag
      record["lastModified"] = lastModified
      record["failureCount"] = failureCount
      record["lastFailureReason"] = lastFailureReason
      record["minUpdateInterval"] = minUpdateInterval

      return record
    }
  }

  public enum CloudKitConversionError: Error {
    case missingRequiredField
  }
#endif
