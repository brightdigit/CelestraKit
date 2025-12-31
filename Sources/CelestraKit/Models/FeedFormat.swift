//
//  FeedFormat.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

import Foundation

/// Feed format detection results
public enum FeedFormat: Sendable, Codable, CaseIterable {
  case rss
  case atom
  case jsonFeed
  case podcast
  case youTube
  case unknown
}

/// Feed categories for organization
public enum FeedCategory: String, CaseIterable, Sendable {
  case general = "General"
  case technology = "Technology"
  case design = "Design"
  case business = "Business"
  case news = "News"
  case entertainment = "Entertainment"
  case science = "Science"
  case health = "Health"

  public var icon: String {
    switch self {
    case .general: return "folder"
    case .technology: return "cpu"
    case .design: return "paintpalette"
    case .business: return "chart.line.uptrend.xyaxis"
    case .news: return "newspaper"
    case .entertainment: return "tv"
    case .science: return "atom"
    case .health: return "heart"
    }
  }
}
