// CDArticle+StateManagement.swift
// CelestraKit
//
// Created for Celestra on 2025-12-03.
//

#if canImport(CoreData)
  import CoreData
  import Foundation

  // MARK: - Article State Management
  extension CDArticle {
    public func markAsRead(_ read: Bool = true) {
      isRead = read
      readDate = read ? Date() : nil
    }

    public func toggleStarred() {
      isStarred.toggle()
    }

    public func updateContent(_ newContent: String) {
      content = newContent
      cachedContentHash = newContent.contentHash
    }
  }
#endif
