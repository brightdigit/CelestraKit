//
//  FeedParserError.swift
//  CelestraKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

/// Errors that can occur during feed parsing operations
public enum FeedParserError: Error, Sendable {
  case invalidURL
  case invalidArticleURL
  case missingRequiredData
  case parsingFailed(underlying: any Error)
  case networkError(underlying: any Error)
  case cacheError(underlying: any Error)

  public var localizedDescription: String {
    switch self {
    case .invalidURL:
      return "Invalid or missing feed URL"
    case .invalidArticleURL:
      return "Invalid or missing article URL"
    case .missingRequiredData:
      return "Required data is missing from the feed"
    case .parsingFailed(let underlying):
      return "Feed parsing failed: \(underlying.localizedDescription)"
    case .networkError(let underlying):
      return "Network error: \(underlying.localizedDescription)"
    case .cacheError(let underlying):
      return "Cache error: \(underlying.localizedDescription)"
    }
  }
}
