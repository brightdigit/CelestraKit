//
//  FeedFormat.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

public import Foundation

/// Feed format detection results
public enum FeedFormat: Sendable, Codable, CaseIterable {
  case rss
  case atom
  case jsonFeed
  case podcast
  case youTube
  case unknown
}
