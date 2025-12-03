// Logger.swift
// CelestraKit
//
// Created for Celestra on 2025-08-13.
//

#if canImport(OSLog)
  import OSLog

  /// Wrapper around OSLog's Logger for consistent logging across the app
  public struct CelestraLogger: Sendable {
    private let logger: Logger

    public init(subsystem: String, category: String) {
      self.logger = Logger(subsystem: subsystem, category: category)
    }

    public func info(_ message: String) {
      logger.info("\(message, privacy: .public)")
    }

    public func error(_ message: String) {
      logger.error("\(message, privacy: .public)")
    }

    public func warning(_ message: String) {
      logger.warning("\(message, privacy: .public)")
    }

    public func debug(_ message: String) {
      logger.debug("\(message, privacy: .public)")
    }
  }

  /// Factory function for creating loggers with subsystem and category
  public func createLogger(subsystem: String, category: String) -> CelestraLogger {
    CelestraLogger(subsystem: subsystem, category: category)
  }
#else
  // Fallback for platforms without OSLog (e.g., Linux) - uses swift-log
  import Logging

  /// Wrapper around swift-log's Logger for consistent logging across platforms
  public struct CelestraLogger: Sendable {
    private let logger: Logging.Logger

    public init(subsystem: String, category: String) {
      self.logger = Logging.Logger(label: "\(subsystem).\(category)")
    }

    public func info(_ message: String) {
      logger.info("\(message)")
    }

    public func error(_ message: String) {
      logger.error("\(message)")
    }

    public func warning(_ message: String) {
      logger.warning("\(message)")
    }

    public func debug(_ message: String) {
      logger.debug("\(message)")
    }
  }

  /// Factory function for creating loggers with subsystem and category
  public func createLogger(subsystem: String, category: String) -> CelestraLogger {
    CelestraLogger(subsystem: subsystem, category: category)
  }
#endif
