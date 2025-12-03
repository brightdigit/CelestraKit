//
//  DiscoveredFeed.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

public import Foundation

/// Represents a discovered feed with metadata
public struct DiscoveredFeed: Sendable, Codable, Equatable {
  public let url: URL
  public let title: String?
  public let type: String?
  public let format: FeedFormat?

  public init(url: URL, title: String? = nil, type: String? = nil, format: FeedFormat? = nil) {
    self.url = url
    self.title = title
    self.type = type
    self.format = format
  }
}
