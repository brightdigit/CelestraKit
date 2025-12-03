// CoreDataStack+ModelVersioning.swift
// CelestraKit
//
// Created for Celestra on 2025-12-03.
//

#if canImport(CoreData)
  import CoreData

  // MARK: - Model Versioning
  extension CoreDataStack {
    /// Current data model version
    public static let currentModelVersion = "1.0.0"

    /// Model version identifier for Core Data
    public static let modelVersionIdentifier = "com.celestra.model.v1"
  }
#endif
