// CoreDataErrors.swift
// CelestraKit
//
// Created for Celestra on 2025-10-15.
//

#if canImport(CoreData)
  import Foundation

  /// Errors that can occur during Core Data operations
  public enum CoreDataError: Error, LocalizedError {
    case saveFailed(underlying: any Error)
    case fetchFailed(underlying: any Error)
    case deleteFailed(underlying: any Error)
    case migrationFailed(underlying: any Error)
    case invalidManagedObject
    case contextNotAvailable
    case duplicateEntry(String)
    case operationCancelled

    public var errorDescription: String? {
      switch self {
      case .saveFailed(let error):
        return "Failed to save changes: \(error.localizedDescription)"
      case .fetchFailed(let error):
        return "Failed to fetch data: \(error.localizedDescription)"
      case .deleteFailed(let error):
        return "Failed to delete data: \(error.localizedDescription)"
      case .migrationFailed(let error):
        return "Failed to migrate data model: \(error.localizedDescription)"
      case .invalidManagedObject:
        return "The managed object is invalid or has been deleted"
      case .contextNotAvailable:
        return "Core Data context is not available"
      case .duplicateEntry(let identifier):
        return "An entry with identifier '\(identifier)' already exists"
      case .operationCancelled:
        return "The operation was cancelled"
      }
    }

    public var failureReason: String? {
      switch self {
      case .saveFailed:
        return "The Core Data context could not be saved"
      case .fetchFailed:
        return "The Core Data fetch request failed"
      case .deleteFailed:
        return "The object could not be deleted from Core Data"
      case .migrationFailed:
        return "The data model could not be migrated to a new version"
      case .invalidManagedObject:
        return "The object does not exist in the current context"
      case .contextNotAvailable:
        return "The managed object context is not initialized"
      case .duplicateEntry:
        return "An object with the same unique identifier already exists"
      case .operationCancelled:
        return "The user or system cancelled the operation"
      }
    }

    public var recoverySuggestion: String? {
      switch self {
      case .saveFailed, .deleteFailed:
        return "Try the operation again. If the problem persists, restart the app."
      case .fetchFailed:
        return "Check your network connection and try again."
      case .migrationFailed:
        return "The app may need to be reinstalled to migrate your data."
      case .invalidManagedObject:
        return "Refresh the data and try again."
      case .contextNotAvailable:
        return "Restart the app to reinitialize the data store."
      case .duplicateEntry:
        return "Use the existing entry or choose a different identifier."
      case .operationCancelled:
        return "Try the operation again if needed."
      }
    }
  }
#endif
