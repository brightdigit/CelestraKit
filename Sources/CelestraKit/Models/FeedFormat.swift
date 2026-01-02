//
//  FeedFormat.swift
//  CelestraKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
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
