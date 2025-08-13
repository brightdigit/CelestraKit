//
//  ParsingResult.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

public import Foundation

/// Metrics collected during parsing operations
public struct ParsingMetrics: Sendable, Codable {
  public let duration: TimeInterval
  public let bytesProcessed: Int
  public let articlesFound: Int
  public let cacheHit: Bool
  public let networkLatency: TimeInterval?
  public let memoryUsed: Int?
  public let cpuTime: TimeInterval?
  
  public init(
    duration: TimeInterval,
    bytesProcessed: Int,
    articlesFound: Int,
    cacheHit: Bool = false,
    networkLatency: TimeInterval? = nil,
    memoryUsed: Int? = nil,
    cpuTime: TimeInterval? = nil
  ) {
    self.duration = duration
    self.bytesProcessed = bytesProcessed
    self.articlesFound = articlesFound
    self.cacheHit = cacheHit
    self.networkLatency = networkLatency
    self.memoryUsed = memoryUsed
    self.cpuTime = cpuTime
  }
  
  /// Create metrics from successful parsing operation
  public static func success(
    startTime: Date,
    endTime: Date = Date(),
    feed: ParsedFeed,
    bytesProcessed: Int,
    cacheHit: Bool = false,
    networkLatency: TimeInterval? = nil
  ) -> ParsingMetrics {
    ParsingMetrics(
      duration: endTime.timeIntervalSince(startTime),
      bytesProcessed: bytesProcessed,
      articlesFound: feed.articles.count,
      cacheHit: cacheHit,
      networkLatency: networkLatency
    )
  }
  
  /// Create metrics from failed parsing operation
  public static func failure(
    startTime: Date,
    endTime: Date = Date(),
    bytesProcessed: Int = 0,
    networkLatency: TimeInterval? = nil
  ) -> ParsingMetrics {
    ParsingMetrics(
      duration: endTime.timeIntervalSince(startTime),
      bytesProcessed: bytesProcessed,
      articlesFound: 0,
      cacheHit: false,
      networkLatency: networkLatency
    )
  }
}

/// Result of a parsing operation with detailed outcome and metrics
public enum ParsingResult: Sendable {
  case success(ParsedFeed, metrics: ParsingMetrics)
  case failure(Error, metrics: ParsingMetrics)
  case cancelled(metrics: ParsingMetrics?)
  
  public var metrics: ParsingMetrics? {
    switch self {
    case .success(_, let metrics), .failure(_, let metrics):
      return metrics
    case .cancelled(let metrics):
      return metrics
    }
  }
  
  public var isSuccess: Bool {
    if case .success = self { return true }
    return false
  }
  
  public var feed: ParsedFeed? {
    guard case .success(let feed, _) = self else { return nil }
    return feed
  }
  
  public var error: Error? {
    guard case .failure(let error, _) = self else { return nil }
    return error
  }
  
  /// Duration of the parsing operation
  public var duration: TimeInterval? {
    metrics?.duration
  }
  
  /// Number of bytes processed during parsing
  public var bytesProcessed: Int? {
    metrics?.bytesProcessed
  }
  
  /// Whether this result came from cache
  public var wasCacheHit: Bool {
    metrics?.cacheHit ?? false
  }
}

/// Progress update during parsing operations
public struct ParsingProgress: Sendable {
  public let taskId: UUID
  public let url: URL
  public let phase: ParsingPhase
  public let progress: Double  // 0.0 to 1.0
  public let message: String?
  
  public init(
    taskId: UUID,
    url: URL,
    phase: ParsingPhase,
    progress: Double = 0.0,
    message: String? = nil
  ) {
    self.taskId = taskId
    self.url = url
    self.phase = phase
    self.progress = max(0.0, min(1.0, progress))
    self.message = message
  }
}

/// Phases of parsing operation for progress tracking
public enum ParsingPhase: String, Sendable, CaseIterable {
  case queued = "queued"
  case fetching = "fetching"
  case parsing = "parsing"
  case caching = "caching"
  case completed = "completed"
  case failed = "failed"
  case cancelled = "cancelled"
  
  public var displayName: String {
    switch self {
    case .queued: return "Queued"
    case .fetching: return "Fetching"
    case .parsing: return "Parsing"
    case .caching: return "Caching"
    case .completed: return "Completed"
    case .failed: return "Failed"
    case .cancelled: return "Cancelled"
    }
  }
  
  public var isTerminal: Bool {
    switch self {
    case .completed, .failed, .cancelled:
      return true
    case .queued, .fetching, .parsing, .caching:
      return false
    }
  }
  
  public var progressWeight: Double {
    switch self {
    case .queued: return 0.0
    case .fetching: return 0.3
    case .parsing: return 0.8
    case .caching: return 0.95
    case .completed: return 1.0
    case .failed, .cancelled: return 0.0
    }
  }
}

/// Batch result for multiple parsing operations
public struct BatchParsingResult: Sendable {
  public let results: [URL: ParsingResult]
  public let totalDuration: TimeInterval
  public let startTime: Date
  public let endTime: Date
  public let batchId: UUID
  
  public init(
    results: [URL: ParsingResult],
    startTime: Date,
    endTime: Date = Date(),
    batchId: UUID = UUID()
  ) {
    self.results = results
    self.totalDuration = endTime.timeIntervalSince(startTime)
    self.startTime = startTime
    self.endTime = endTime
    self.batchId = batchId
  }
  
  public var successCount: Int {
    results.values.filter(\.isSuccess).count
  }
  
  public var failureCount: Int {
    results.count - successCount
  }
  
  public var totalBytesProcessed: Int {
    results.values.compactMap { $0.bytesProcessed }.reduce(0, +)
  }
  
  public var averageDuration: TimeInterval? {
    let durations = results.values.compactMap { $0.duration }
    guard !durations.isEmpty else { return nil }
    return durations.reduce(0, +) / Double(durations.count)
  }
  
  public var cacheHitRate: Double {
    let totalResults = results.count
    guard totalResults > 0 else { return 0.0 }
    let cacheHits = results.values.filter(\.wasCacheHit).count
    return Double(cacheHits) / Double(totalResults)
  }
}