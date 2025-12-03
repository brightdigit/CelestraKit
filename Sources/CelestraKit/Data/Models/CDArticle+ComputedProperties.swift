// CDArticle+ComputedProperties.swift
// CelestraKit
//
// Created for Celestra on 2025-12-03.
//

#if canImport(CoreData)
  import CoreData
  import Foundation

  // MARK: - Computed Properties
  extension CDArticle {
    public var isRecent: Bool {
      guard let publishedDate = publishedDate else { return false }
      let dayAgo = Date().addingTimeInterval(-24 * 60 * 60)
      return publishedDate > dayAgo
    }

    public var readingTimeString: String {
      let minutes = max(1, Int(estimatedReadingTime))
      return "\(minutes) min read"
    }

    public var hasFullContent: Bool {
      content?.isEmpty == false
    }
  }
#endif
