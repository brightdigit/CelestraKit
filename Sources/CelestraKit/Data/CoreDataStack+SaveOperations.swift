// CoreDataStack+SaveOperations.swift
// CelestraKit
//
// Created for Celestra on 2025-12-03.
//

#if canImport(CoreData)
  public import CoreData
  import Foundation

  // MARK: - Save Operations
  extension CoreDataStack {
    /// Saves changes in the view context with error handling
    public func save() throws {
      let context = viewContext

      guard context.hasChanges else { return }

      do {
        try context.save()
        logger.info("Core Data context saved successfully")
      } catch {
        logger.error("Failed to save context: \(error.localizedDescription)")
        throw CoreDataError.saveFailed(underlying: error)
      }
    }

    /// Saves changes in the view context without throwing
    public func saveIgnoringErrors() {
      do {
        try save()
      } catch {
        logger.error("Save failed but was ignored: \(error.localizedDescription)")
      }
    }

    /// Performs a background task with automatic save and error handling
    public func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
      let context = backgroundContext
      return try await withCheckedThrowingContinuation { continuation in
        context.perform {
          do {
            let result = try block(context)
            if context.hasChanges {
              try context.save()
            }
            continuation.resume(returning: result)
          } catch let error as CoreDataError {
            continuation.resume(throwing: error)
          } catch {
            continuation.resume(throwing: CoreDataError.saveFailed(underlying: error))
          }
        }
      }
    }

    /// Performs a background task without automatic save
    public func performBackgroundTaskWithoutSave<T>(
      _ block: @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T {
      let context = backgroundContext
      return try await withCheckedThrowingContinuation { continuation in
        context.perform {
          do {
            let result = try block(context)
            continuation.resume(returning: result)
          } catch let error as CoreDataError {
            continuation.resume(throwing: error)
          } catch {
            continuation.resume(throwing: CoreDataError.fetchFailed(underlying: error))
          }
        }
      }
    }

    /// Batch deletes all objects of a given entity type
    public func batchDelete(entityName: String, predicate: NSPredicate? = nil) async throws {
      try await performBackgroundTask { context in
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate

        let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDelete.resultType = .resultTypeCount

        do {
          let result = try context.execute(batchDelete) as? NSBatchDeleteResult
          let deletedCount = result?.result as? Int ?? 0
          self.logger.info("Batch deleted \(deletedCount) \(entityName) objects")
        } catch {
          throw CoreDataError.deleteFailed(underlying: error)
        }
      }
    }
  }
#endif
