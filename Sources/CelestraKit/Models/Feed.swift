// Feed.swift
// CelestraKit
//
// Created for Celestra on 2025-08-07.

public import Foundation

// public import SwiftUI

/// Mock Feed model for UI prototyping
public struct Feed: Identifiable, Sendable {
  public let id: UUID
  public let title: String
  public let subtitle: String?
  public let url: URL
  public let imageURL: URL?
  public let lastUpdated: Date
  public let unreadCount: Int
  public let category: FeedCategory

  public init(
    id: UUID = UUID(),
    title: String,
    subtitle: String? = nil,
    url: URL,
    imageURL: URL? = nil,
    lastUpdated: Date = Date(),
    unreadCount: Int = 0,
    category: FeedCategory = .general
  ) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
    self.url = url
    self.imageURL = imageURL
    self.lastUpdated = lastUpdated
    self.unreadCount = unreadCount
    self.category = category
  }
}

public enum FeedCategory: String, CaseIterable, Sendable {
  case general = "General"
  case technology = "Technology"
  case design = "Design"
  case business = "Business"
  case news = "News"
  case entertainment = "Entertainment"
  case science = "Science"
  case health = "Health"

  // public var color: Color {
  //     switch self {
  //     case .general: return .gray
  //     case .technology: return .blue
  //     case .design: return .purple
  //     case .business: return .green
  //     case .news: return .red
  //     case .entertainment: return .orange
  //     case .science: return .cyan
  //     case .health: return .mint
  //     }
  // }

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
