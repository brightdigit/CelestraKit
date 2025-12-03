// CoreDataStack.swift
// CelestraKit
//
// Created for Celestra on 2025-08-13.
//

#if canImport(CoreData)
  public import CoreData
  public import Foundation

  #if canImport(CloudKit)
    public import CloudKit
  #endif

  /// Core Data stack with CloudKit integration for private database
  public final class CoreDataStack: CoreDataStackProtocol {
    nonisolated(unsafe) public static let shared = CoreDataStack()

    internal let logger = createLogger(subsystem: "com.celestra.kit", category: "CoreData")

    // MARK: - Core Data Stack

    #if canImport(CloudKit)
      private lazy var _persistentContainer: NSPersistentCloudKitContainer = {
        // Create model programmatically
        let model = createDataModel()
        let container = NSPersistentCloudKitContainer(name: "CelestraModel", managedObjectModel: model)

        // Configure CloudKit
        guard let description = container.persistentStoreDescriptions.first else {
          fatalError("Failed to retrieve persistent store description")
        }

        // CloudKit configuration
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
          containerIdentifier: Self.containerIdentifier
        )

        // Enable remote notifications and history tracking
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // Load stores
        container.loadPersistentStores { _, error in
          if let error = error {
            self.logger.error("Core Data error: \(error.localizedDescription)")
            fatalError("Core Data error: \(error.localizedDescription)")
          }
        }

        // Configure view context
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        container.viewContext.automaticallyMergesChangesFromParent = true

        return container
      }()
    #else
      private lazy var _persistentContainer: NSPersistentContainer = {
        // Create model programmatically
        let model = createDataModel()
        let container = NSPersistentContainer(name: "CelestraModel", managedObjectModel: model)

        // Enable history tracking
        guard let description = container.persistentStoreDescriptions.first else {
          fatalError("Failed to retrieve persistent store description")
        }

        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // Load stores
        container.loadPersistentStores { _, error in
          if let error = error {
            self.logger.error("Core Data error: \(error.localizedDescription)")
            fatalError("Core Data error: \(error.localizedDescription)")
          }
        }

        // Configure view context
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        container.viewContext.automaticallyMergesChangesFromParent = true

        return container
      }()
    #endif

    public var persistentContainer: NSPersistentContainer {
      _persistentContainer
    }

    public var viewContext: NSManagedObjectContext {
      _persistentContainer.viewContext
    }

    public var backgroundContext: NSManagedObjectContext {
      _persistentContainer.newBackgroundContext()
    }

    private init() {}
  }
#endif
