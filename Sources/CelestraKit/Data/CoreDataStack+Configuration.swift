// CoreDataStack+Configuration.swift
// CelestraKit
//
// Created for Celestra on 2025-12-03.
//

#if canImport(CoreData)
  import CoreData
  import Foundation

  // MARK: - Configuration
  extension CoreDataStack {
    /// CloudKit container identifier from Info.plist
    internal static var containerIdentifier: String {
      guard let identifier = Bundle.main.object(forInfoDictionaryKey: "CKContainerIdentifier") as? String else {
        fatalError("CKContainerIdentifier not found in Info.plist. Ensure Project.swift defines this key.")
      }
      guard !identifier.isEmpty else {
        fatalError("CKContainerIdentifier in Info.plist is empty.")
      }
      return identifier
    }
  }
#endif
