//
//  ParsedSyndicationUpdate.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

public import Foundation

/// Syndication update information
public struct ParsedSyndicationUpdate: Sendable, Codable {
  public let period: String?
  public let frequency: Int?
  public let base: Date?

  public init(period: String? = nil, frequency: Int? = nil, base: Date? = nil) {
    self.period = period
    self.frequency = frequency
    self.base = base
  }
}
