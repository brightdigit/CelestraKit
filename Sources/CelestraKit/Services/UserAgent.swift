//
//  UserAgent.swift
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

public import Foundation

public struct UserAgent: Sendable {
  private enum Names {
    static let cloud = "CelestraCloud"
    static let app = "Celestra"
  }

  private init(name: String, build: Int, url: URL) {
    self.name = name
    self.build = build
    self.url = url
  }

  public let name: String
  let build: Int
  let url: URL

  public static func cloud(build: Int) -> UserAgent {
    .init(name: Names.cloud, build: build, url: .Agent.cloud)
  }

  public static func app(build: Int) -> UserAgent {
    .init(name: Names.app, build: build, url: .Agent.app)
  }

  public var string: String {
    "\(name)/\(build) (\(url))"
  }
}

extension URL {
  fileprivate enum Agent {
    static let cloud: URL = {
      guard let url = URL(string: "https://github.com/brightdigit/CelestraCloud") else {
        preconditionFailure("Invalid URL for cloud agent")
      }
      return url
    }()

    static let app: URL = {
      guard let url = URL(string: "https://celestr.app") else {
        preconditionFailure("Invalid URL for app agent")
      }
      return url
    }()
  }
}
