// CoreDataStackProtocol.swift
// CelestraKit
//
// Created for Celestra on 2025-08-13.
//

#if canImport(CoreData)
  public import CoreData

  /// Protocol for Core Data stack implementations
  public protocol CoreDataStackProtocol {
    var persistentContainer: NSPersistentContainer { get }
    var viewContext: NSManagedObjectContext { get }
    var backgroundContext: NSManagedObjectContext { get }
    func saveIgnoringErrors()
  }
#endif
