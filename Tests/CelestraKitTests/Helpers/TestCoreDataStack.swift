// TestCoreDataStack.swift
// CelestraKitTests
//
// Created for Celestra on 2025-10-27.
//

// swiftlint:disable function_body_length

#if canImport(CoreData)
  import CoreData

  import Foundation

  @testable import CelestraKit

  /// In-memory Core Data stack for testing
  final class TestCoreDataStack: CoreDataStackProtocol {
    private var _persistentContainer: NSPersistentContainer?

    var persistentContainer: NSPersistentContainer {
      guard let container = _persistentContainer else {
        fatalError("Persistent container not initialized")
      }
      return container
    }

    var viewContext: NSManagedObjectContext {
      persistentContainer.viewContext
    }

    var backgroundContext: NSManagedObjectContext {
      persistentContainer.newBackgroundContext()
    }

    func saveIgnoringErrors() {
      let context = viewContext
      guard context.hasChanges else { return }

      do {
        try context.save()
      } catch {
        print("Failed to save test context: \(error)")
      }
    }

    init() {
      setupInMemoryStore()
    }

    private func setupInMemoryStore() {
      // Use the same model creation logic as the real CoreDataStack
      let model = createTestDataModel()
      let container = NSPersistentContainer(name: "TestModel", managedObjectModel: model)

      // Configure in-memory store
      let description = NSPersistentStoreDescription()
      description.type = NSInMemoryStoreType
      container.persistentStoreDescriptions = [description]

      // Load store synchronously for testing
      container.loadPersistentStores { _, error in
        if let error = error {
          fatalError("Failed to load test store: \(error)")
        }
      }

      container.viewContext.automaticallyMergesChangesFromParent = true
      _persistentContainer = container
    }

    private func createTestDataModel() -> NSManagedObjectModel {
      let model = NSManagedObjectModel()

      // Create simplified entities for testing
      let feedEntity = createTestFeedEntity()
      let articleEntity = createTestArticleEntity()

      // Setup relationship
      let feedToArticles = NSRelationshipDescription()
      feedToArticles.name = "articles"
      feedToArticles.destinationEntity = articleEntity
      feedToArticles.minCount = 0
      feedToArticles.maxCount = 0
      feedToArticles.deleteRule = .cascadeDeleteRule
      feedToArticles.isOptional = true

      let articlesToFeed = NSRelationshipDescription()
      articlesToFeed.name = "feed"
      articlesToFeed.destinationEntity = feedEntity
      articlesToFeed.minCount = 0
      articlesToFeed.maxCount = 1
      articlesToFeed.deleteRule = .nullifyDeleteRule
      articlesToFeed.isOptional = true

      feedToArticles.inverseRelationship = articlesToFeed
      articlesToFeed.inverseRelationship = feedToArticles

      feedEntity.properties.append(feedToArticles)
      articleEntity.properties.append(articlesToFeed)

      model.entities = [feedEntity, articleEntity]
      return model
    }

    private func createTestFeedEntity() -> NSEntityDescription {
      let entity = NSEntityDescription()
      entity.name = "CDFeed"
      entity.managedObjectClassName = NSStringFromClass(CDFeed.self)

      var properties: [NSPropertyDescription] = []

      // ID
      let idAttr = NSAttributeDescription()
      idAttr.name = "id"
      idAttr.attributeType = .UUIDAttributeType
      idAttr.isOptional = true
      properties.append(idAttr)

      // Title
      let titleAttr = NSAttributeDescription()
      titleAttr.name = "title"
      titleAttr.attributeType = .stringAttributeType
      titleAttr.isOptional = true
      properties.append(titleAttr)

      // URL
      let urlAttr = NSAttributeDescription()
      urlAttr.name = "url"
      urlAttr.attributeType = .URIAttributeType
      urlAttr.isOptional = true
      properties.append(urlAttr)

      // Category
      let categoryAttr = NSAttributeDescription()
      categoryAttr.name = "category"
      categoryAttr.attributeType = .stringAttributeType
      categoryAttr.isOptional = true
      properties.append(categoryAttr)

      // Subtitle
      let subtitleAttr = NSAttributeDescription()
      subtitleAttr.name = "subtitle"
      subtitleAttr.attributeType = .stringAttributeType
      subtitleAttr.isOptional = true
      properties.append(subtitleAttr)

      // isActive
      let isActiveAttr = NSAttributeDescription()
      isActiveAttr.name = "isActive"
      isActiveAttr.attributeType = .booleanAttributeType
      isActiveAttr.defaultValue = true
      properties.append(isActiveAttr)

      // sortOrder
      let sortOrderAttr = NSAttributeDescription()
      sortOrderAttr.name = "sortOrder"
      sortOrderAttr.attributeType = .integer32AttributeType
      sortOrderAttr.defaultValue = 0
      properties.append(sortOrderAttr)

      // lastUpdated
      let lastUpdatedAttr = NSAttributeDescription()
      lastUpdatedAttr.name = "lastUpdated"
      lastUpdatedAttr.attributeType = .dateAttributeType
      lastUpdatedAttr.isOptional = true
      properties.append(lastUpdatedAttr)

      // lastFetched
      let lastFetchedAttr = NSAttributeDescription()
      lastFetchedAttr.name = "lastFetched"
      lastFetchedAttr.attributeType = .dateAttributeType
      lastFetchedAttr.isOptional = true
      properties.append(lastFetchedAttr)

      // updateFrequency
      let updateFrequencyAttr = NSAttributeDescription()
      updateFrequencyAttr.name = "updateFrequency"
      updateFrequencyAttr.attributeType = .doubleAttributeType
      updateFrequencyAttr.defaultValue = 3600.0
      properties.append(updateFrequencyAttr)

      // imageURL
      let imageURLAttr = NSAttributeDescription()
      imageURLAttr.name = "imageURL"
      imageURLAttr.attributeType = .URIAttributeType
      imageURLAttr.isOptional = true
      properties.append(imageURLAttr)

      // etag
      let etagAttr = NSAttributeDescription()
      etagAttr.name = "etag"
      etagAttr.attributeType = .stringAttributeType
      etagAttr.isOptional = true
      properties.append(etagAttr)

      entity.properties = properties
      return entity
    }

    private func createTestArticleEntity() -> NSEntityDescription {
      let entity = NSEntityDescription()
      entity.name = "CDArticle"
      entity.managedObjectClassName = NSStringFromClass(CDArticle.self)

      var properties: [NSPropertyDescription] = []

      // ID
      let idAttr = NSAttributeDescription()
      idAttr.name = "id"
      idAttr.attributeType = .UUIDAttributeType
      idAttr.isOptional = true
      properties.append(idAttr)

      // isRead
      let isReadAttr = NSAttributeDescription()
      isReadAttr.name = "isRead"
      isReadAttr.attributeType = .booleanAttributeType
      isReadAttr.defaultValue = false
      properties.append(isReadAttr)

      entity.properties = properties
      return entity
    }

    /// Reset the test store by deleting all data
    func reset() {
      let context = viewContext
      let entities = persistentContainer.managedObjectModel.entities

      for entity in entities {
        guard let entityName = entity.name else { continue }
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
          try context.execute(deleteRequest)
          try context.save()
        } catch {
          print("Failed to reset entity \(entityName): \(error)")
        }
      }
    }
  }
#endif
