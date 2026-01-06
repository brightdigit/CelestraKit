//
//  RobotsRules.swift
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

public import Foundation

/// Represents parsed robots.txt rules for a domain
public struct RobotsRules: Sendable {
  public let disallowedPaths: [String]
  public let crawlDelay: TimeInterval?
  public let fetchedAt: Date

  /// Check if a given path is allowed
  public func isAllowed(_ path: String) -> Bool {
    // If no disallow rules, everything is allowed
    guard !disallowedPaths.isEmpty else {
      return true
    }

    // Check if path matches any disallow rule
    for disallowedPath in disallowedPaths where path.hasPrefix(disallowedPath) {
      return false
    }

    return true
  }

  public init(disallowedPaths: [String], crawlDelay: TimeInterval?, fetchedAt: Date) {
    self.disallowedPaths = disallowedPaths
    self.crawlDelay = crawlDelay
    self.fetchedAt = fetchedAt
  }
}
