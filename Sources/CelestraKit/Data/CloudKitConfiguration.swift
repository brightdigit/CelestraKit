// CloudKitConfiguration.swift
// CelestraKit
//
// Created for Celestra on 2025-10-16.
//

#if canImport(CloudKit)
  public import CloudKit
  public import Foundation

  /// Manages CloudKit container configuration, custom zones, and subscriptions
  public final class CloudKitConfiguration: Sendable {
    public static let shared = CloudKitConfiguration()

    private let logger = createLogger(subsystem: "com.celestra.kit", category: "CloudKit")
    private let container: CKContainer
    private let privateDatabase: CKDatabase

    /// Custom zone names for organized data sync
    public enum ZoneName {
      public static let feeds = "CelestraFeedsZone"
      public static let articles = "CelestraArticlesZone"
      public static let preferences = "CelestraPreferencesZone"
    }

    private init() {
      let identifier = Self.containerIdentifier
      container = CKContainer(identifier: identifier)
      privateDatabase = container.privateCloudDatabase
    }

    // MARK: - Configuration

    /// CloudKit container identifier from Info.plist
    private static var containerIdentifier: String {
      guard let identifier = Bundle.main.object(forInfoDictionaryKey: "CKContainerIdentifier") as? String else {
        fatalError("CKContainerIdentifier not found in Info.plist. Ensure Project.swift defines this key.")
      }
      guard !identifier.isEmpty else {
        fatalError("CKContainerIdentifier in Info.plist is empty.")
      }
      return identifier
    }

    // MARK: - Zone Configuration

    /// Creates all custom CloudKit zones if they don't exist
    public func configureCustomZones() async throws {
      let zoneIDs = [
        CKRecordZone.ID(zoneName: ZoneName.feeds),
        CKRecordZone.ID(zoneName: ZoneName.articles),
        CKRecordZone.ID(zoneName: ZoneName.preferences),
      ]

      let zones = zoneIDs.map { CKRecordZone(zoneID: $0) }

      do {
        let result = try await privateDatabase.modifyRecordZones(saving: zones, deleting: [])
        logger.info("Successfully created \(result.saveResults.count) CloudKit zones")
      } catch let error as CKError where error.code == .partialFailure {
        // Zone may already exist, which is acceptable
        logger.info("Zones may already exist: \(error.localizedDescription)")
      } catch {
        logger.error("Failed to create CloudKit zones: \(error.localizedDescription)")
        throw CloudKitConfigurationError.zoneCreationFailed(underlying: error)
      }
    }

    /// Fetches existing zones to verify configuration
    public func verifyZones() async throws -> [CKRecordZone.ID] {
      do {
        let zones = try await privateDatabase.allRecordZones()
        let customZones = zones.filter { $0.zoneID.zoneName.hasPrefix("Celestra") }
        logger.info("Found \(customZones.count) Celestra zones")
        return customZones.map { $0.zoneID }
      } catch {
        logger.error("Failed to verify zones: \(error.localizedDescription)")
        throw CloudKitConfigurationError.zoneVerificationFailed(underlying: error)
      }
    }

    // MARK: - Subscriptions

    /// Sets up database subscriptions for change notifications
    public func configureSubscriptions() async throws {
      let subscriptionIDs = [
        "celestra-feeds-subscription",
        "celestra-articles-subscription",
        "celestra-preferences-subscription",
      ]

      let zoneIDs = [
        CKRecordZone.ID(zoneName: ZoneName.feeds),
        CKRecordZone.ID(zoneName: ZoneName.articles),
        CKRecordZone.ID(zoneName: ZoneName.preferences),
      ]

      var subscriptions: [CKSubscription] = []

      for (index, zoneID) in zoneIDs.enumerated() {
        let subscription = CKRecordZoneSubscription(
          zoneID: zoneID,
          subscriptionID: subscriptionIDs[index]
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo

        subscriptions.append(subscription)
      }

      do {
        let result = try await privateDatabase.modifySubscriptions(
          saving: subscriptions,
          deleting: []
        )
        logger.info("Successfully configured \(result.saveResults.count) subscriptions")
      } catch let error as CKError where error.code == .partialFailure {
        // Subscription may already exist
        logger.info("Subscriptions may already exist: \(error.localizedDescription)")
      } catch {
        logger.error("Failed to configure subscriptions: \(error.localizedDescription)")
        throw CloudKitConfigurationError.subscriptionFailed(underlying: error)
      }
    }

    // MARK: - Account Status

    /// Checks if iCloud account is available
    public func checkAccountStatus() async throws -> CKAccountStatus {
      do {
        let status = try await container.accountStatus()
        logger.info("CloudKit account status: \(String(describing: status))")
        return status
      } catch {
        logger.error("Failed to check account status: \(error.localizedDescription)")
        throw CloudKitConfigurationError.accountCheckFailed(underlying: error)
      }
    }

    // MARK: - Full Setup

    /// Performs complete CloudKit configuration (zones + subscriptions)
    public func performInitialSetup() async throws {
      logger.info("Starting CloudKit configuration...")

      // Check account status first
      let status = try await checkAccountStatus()
      guard status == .available else {
        throw CloudKitConfigurationError.accountNotAvailable(status: status)
      }

      // Create custom zones
      try await configureCustomZones()

      // Verify zones were created
      let zones = try await verifyZones()
      logger.info("Verified zones: \(zones.map { $0.zoneName }.joined(separator: ", "))")

      // Set up subscriptions
      try await configureSubscriptions()

      logger.info("CloudKit configuration completed successfully")
    }
  }

  // MARK: - Errors

  public enum CloudKitConfigurationError: Error, LocalizedError {
    case zoneCreationFailed(underlying: Error)
    case zoneVerificationFailed(underlying: Error)
    case subscriptionFailed(underlying: Error)
    case accountCheckFailed(underlying: Error)
    case accountNotAvailable(status: CKAccountStatus)

    public var errorDescription: String? {
      switch self {
      case .zoneCreationFailed(let error):
        return "Failed to create CloudKit zones: \(error.localizedDescription)"
      case .zoneVerificationFailed(let error):
        return "Failed to verify CloudKit zones: \(error.localizedDescription)"
      case .subscriptionFailed(let error):
        return "Failed to configure CloudKit subscriptions: \(error.localizedDescription)"
      case .accountCheckFailed(let error):
        return "Failed to check CloudKit account: \(error.localizedDescription)"
      case .accountNotAvailable(let status):
        return "iCloud account not available: \(status)"
      }
    }
  }

  // MARK: - CloudKit Zone Helpers

  extension CoreDataStack {
    /// Returns the appropriate CloudKit zone for a given entity
    public static func cloudKitZone(for entityName: String) -> CKRecordZone.ID {
      switch entityName {
      case "CDFeed":
        return CKRecordZone.ID(zoneName: CloudKitConfiguration.ZoneName.feeds)
      case "CDArticle":
        return CKRecordZone.ID(zoneName: CloudKitConfiguration.ZoneName.articles)
      case "CDUserPreferences":
        return CKRecordZone.ID(zoneName: CloudKitConfiguration.ZoneName.preferences)
      default:
        return CKRecordZone.ID(zoneName: CKRecordZone.ID.defaultZoneName)
      }
    }
  }
#endif
