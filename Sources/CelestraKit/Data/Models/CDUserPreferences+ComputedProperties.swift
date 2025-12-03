// CDUserPreferences+ComputedProperties.swift
// CelestraKit
//
// Created for Celestra on 2025-12-03.
//

#if canImport(CoreData)
  import CoreData
  import Foundation

  // MARK: - Computed Properties
  extension CDUserPreferences {
    public var needsSync: Bool {
      guard let lastSyncDate = lastSyncDate else { return true }
      return Date().timeIntervalSince(lastSyncDate) > 300  // 5 minutes
    }
  }
#endif
