// TimelineFilter.swift
// CelestraKit
//
// Created for Celestra on 2025-08-07.

#if canImport(SwiftUI)

  /// Filter options for the timeline
  public enum TimelineFilter: String, CaseIterable {
    case all = "All Articles"
    case unread = "Unread"
    case starred = "Starred"

    var icon: String {
      switch self {
      case .all: return "tray.full"
      case .unread: return "circle"
      case .starred: return "star"
      }
    }
  }

#endif
