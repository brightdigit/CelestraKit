// CoreDataStack+ModelCreation.swift
// CelestraKit
//
// Created for Celestra on 2025-12-03.
//

#if canImport(CoreData)
  import CoreData
  import Foundation

  #if canImport(CloudKit)
    import CloudKit
  #endif

  // MARK: - Data Model Creation
  extension CoreDataStack {
    internal func createDataModel() -> NSManagedObjectModel {
      let model = NSManagedObjectModel()

      // Set version identifiers for future migration support
      model.versionIdentifiers = Set([
        CoreDataStack.modelVersionIdentifier,
        CoreDataStack.currentModelVersion,
      ])

      let feedEntity = createFeedEntity()
      let articleEntity = createArticleEntity()
      let userPreferencesEntity = createUserPreferencesEntity()

      // Create relationships
      setupRelationships(feedEntity: feedEntity, articleEntity: articleEntity)

      model.entities = [feedEntity, articleEntity, userPreferencesEntity]
      return model
    }

    internal func setupRelationships(feedEntity: NSEntityDescription, articleEntity: NSEntityDescription) {
      // Feed -> Articles (One to Many)
      let feedToArticles = NSRelationshipDescription()
      feedToArticles.name = "articles"
      feedToArticles.destinationEntity = articleEntity
      feedToArticles.deleteRule = .cascadeDeleteRule
      feedToArticles.isOptional = true  // Required for CloudKit
      feedEntity.properties.append(feedToArticles)

      // Article -> Feed (Many to One)
      let articleToFeed = NSRelationshipDescription()
      articleToFeed.name = "feed"
      articleToFeed.destinationEntity = feedEntity
      articleToFeed.deleteRule = .nullifyDeleteRule
      articleToFeed.isOptional = true  // Required for CloudKit
      articleToFeed.maxCount = 1
      articleEntity.properties.append(articleToFeed)

      // Set inverse relationships
      feedToArticles.inverseRelationship = articleToFeed
      articleToFeed.inverseRelationship = feedToArticles
    }

    internal func createFeedEntity() -> NSEntityDescription {
      let entity = NSEntityDescription()
      entity.name = "CDFeed"
      entity.managedObjectClassName = "CDFeed"

      // Attributes
      var properties: [NSPropertyDescription] = [
        // Core properties (optional for CloudKit, initialized in awakeFromInsert)
        createAttribute(name: "id", type: .UUIDAttributeType, isOptional: true),
        createAttribute(name: "title", type: .stringAttributeType, isOptional: true),
        createAttribute(name: "subtitle", type: .stringAttributeType, isOptional: true),
        createAttribute(name: "url", type: .URIAttributeType, isOptional: true),
        createAttribute(name: "imageURL", type: .URIAttributeType, isOptional: true),
        createAttribute(name: "lastUpdated", type: .dateAttributeType, isOptional: true),
        createAttribute(name: "lastFetched", type: .dateAttributeType, isOptional: true),
        createAttribute(name: "category", type: .stringAttributeType, isOptional: true),
        createAttribute(name: "isActive", type: .booleanAttributeType, defaultValue: true),
        createAttribute(name: "sortOrder", type: .integer32AttributeType, defaultValue: 0),
        createAttribute(name: "updateFrequency", type: .doubleAttributeType, defaultValue: 3600),
        createAttribute(name: "etag", type: .stringAttributeType, isOptional: true),
      ]

      #if canImport(CloudKit)
        // CloudKit support
        properties.append(
          createTransformableAttribute(
            name: "ckRecordID",
            valueTransformerName: "NSSecureUnarchiveFromData",
            customClassName: "CKRecord.ID"
          ))
        properties.append(
          createAttribute(name: "ckRecordSystemFields", type: .binaryDataAttributeType, isOptional: true))
      #endif

      entity.properties = properties

      return entity
    }

    internal func createArticleEntity() -> NSEntityDescription {
      let entity = NSEntityDescription()
      entity.name = "CDArticle"
      entity.managedObjectClassName = "CDArticle"

      // Attributes
      var properties: [NSPropertyDescription] = [
        // Core properties (optional for CloudKit, initialized in awakeFromInsert or at creation)
        createAttribute(name: "guid", type: .stringAttributeType, isOptional: true),
        createAttribute(name: "title", type: .stringAttributeType, isOptional: true),
        createAttribute(name: "excerpt", type: .stringAttributeType, isOptional: true),
        createAttribute(name: "content", type: .stringAttributeType, isOptional: true),
        createAttribute(name: "author", type: .stringAttributeType, isOptional: true),
        createAttribute(name: "url", type: .URIAttributeType, isOptional: true),
        createAttribute(name: "imageURL", type: .URIAttributeType, isOptional: true),
        createAttribute(name: "publishedDate", type: .dateAttributeType, isOptional: true),
        createAttribute(name: "readDate", type: .dateAttributeType, isOptional: true),
        createAttribute(name: "isRead", type: .booleanAttributeType, defaultValue: false),
        createAttribute(name: "isStarred", type: .booleanAttributeType, defaultValue: false),
        createAttribute(name: "estimatedReadingTime", type: .integer32AttributeType, defaultValue: 5),
        createAttribute(name: "cachedContentHash", type: .stringAttributeType, isOptional: true),
      ]

      #if canImport(CloudKit)
        // CloudKit support
        properties.append(
          createTransformableAttribute(
            name: "ckRecordID",
            valueTransformerName: "NSSecureUnarchiveFromData",
            customClassName: "CKRecord.ID"
          ))
        properties.append(
          createAttribute(name: "ckRecordSystemFields", type: .binaryDataAttributeType, isOptional: true))
      #endif

      entity.properties = properties

      // Create relationships after entities are fully configured
      return entity
    }

    internal func createUserPreferencesEntity() -> NSEntityDescription {
      let entity = NSEntityDescription()
      entity.name = "CDUserPreferences"
      entity.managedObjectClassName = "CDUserPreferences"

      // Attributes
      var properties: [NSPropertyDescription] = [
        // Core properties
        createAttribute(name: "id", type: .UUIDAttributeType, isOptional: true),
        createAttribute(name: "syncEnabled", type: .booleanAttributeType, defaultValue: true),
        createAttribute(name: "lastSyncDate", type: .dateAttributeType, isOptional: true),
      ]

      #if canImport(CloudKit)
        // CloudKit support
        properties.append(
          createTransformableAttribute(
            name: "ckRecordID",
            valueTransformerName: "NSSecureUnarchiveFromData",
            customClassName: "CKRecord.ID"
          ))
        properties.append(
          createAttribute(name: "ckRecordSystemFields", type: .binaryDataAttributeType, isOptional: true))
      #endif

      entity.properties = properties

      return entity
    }

    internal func createAttribute(
      name: String,
      type: NSAttributeType,
      isOptional: Bool = false,
      defaultValue: Any? = nil
    ) -> NSAttributeDescription {
      let attribute = NSAttributeDescription()
      attribute.name = name
      attribute.attributeType = type
      attribute.isOptional = isOptional
      if let defaultValue = defaultValue {
        attribute.defaultValue = defaultValue
      }
      return attribute
    }

    #if canImport(CloudKit)
      internal func createTransformableAttribute(
        name: String,
        valueTransformerName: String,
        customClassName: String
      ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = .transformableAttributeType
        attribute.isOptional = true
        attribute.valueTransformerName = valueTransformerName
        attribute.attributeValueClassName = customClassName
        return attribute
      }
    #endif
  }
#endif
