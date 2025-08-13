//
//  ParsedAuthor.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

public import Foundation

/// Author information normalized from feed data
public struct ParsedAuthor: Sendable, Codable {
  public let name: String
  public let email: String?
  public let url: URL?

  public init(name: String, email: String? = nil, url: URL? = nil) {
    self.name = name
    self.email = email
    self.url = url
  }
}
