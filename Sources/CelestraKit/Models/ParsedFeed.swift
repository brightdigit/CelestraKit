//
//  ParsedFeed.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

public import Foundation

/// Unified feed model that represents parsed feed data from any format (RSS, Atom, JSON Feed)
/// This model normalizes data from SyndiKit's Feedable protocol
public struct ParsedFeed: Identifiable, Sendable, Codable {
  public let id: URL
  public let title: String
  public let subtitle: String?
  public let url: URL
  public let siteURL: URL?
  public let imageURL: URL?
  public let lastUpdated: Date?
  public let authors: [ParsedAuthor]
  public let copyright: String?
  public let articles: [Article]

  // Specialized properties
  public let youtubeChannelID: String?
  public let syndicationUpdate: ParsedSyndicationUpdate?

  // Metadata
  public let parsedAt: Date
  public let feedFormat: FeedFormat

  public init(
    id: URL? = nil,
    title: String,
    subtitle: String? = nil,
    url: URL,
    siteURL: URL? = nil,
    imageURL: URL? = nil,
    lastUpdated: Date? = nil,
    authors: [ParsedAuthor] = [],
    copyright: String? = nil,
    articles: [Article] = [],
    youtubeChannelID: String? = nil,
    syndicationUpdate: ParsedSyndicationUpdate? = nil,
    parsedAt: Date = Date(),
    feedFormat: FeedFormat = .unknown
  ) {
    self.id = id ?? url
    self.title = title
    self.subtitle = subtitle
    self.url = url
    self.siteURL = siteURL
    self.imageURL = imageURL
    self.lastUpdated = lastUpdated
    self.authors = authors
    self.copyright = copyright
    self.articles = articles
    self.youtubeChannelID = youtubeChannelID
    self.syndicationUpdate = syndicationUpdate
    self.parsedAt = parsedAt
    self.feedFormat = feedFormat
  }
}
