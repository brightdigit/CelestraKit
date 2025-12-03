// CDUserPreferences+Updates.swift
// CelestraKit
//
// Created for Celestra on 2025-12-03.
//

#if canImport(CoreData)
  import CoreData
  import Foundation

  // MARK: - Preference Updates
  extension CDUserPreferences {
    public func updateSyncDate() {
      lastSyncDate = Date()
    }
  }
#endif
