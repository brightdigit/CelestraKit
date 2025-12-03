// CDUserPreferences.swift
// CelestraKit
//
// Created for Celestra on 2025-10-16.
//

#if canImport(CoreData)
  public import CoreData
  public import Foundation

  #if canImport(CloudKit)
    public import CloudKit
  #endif

  @objc(CDUserPreferences)
  public final class CDUserPreferences: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var syncEnabled: Bool
    @NSManaged public var lastSyncDate: Date?

    #if canImport(CloudKit)
      // CloudKit support
      @NSManaged public var ckRecordID: CKRecord.ID?
      @NSManaged public var ckRecordSystemFields: Data?
    #endif

    public override func awakeFromInsert() {
      super.awakeFromInsert()
      id = UUID()
      syncEnabled = true
    }
  }
#endif
