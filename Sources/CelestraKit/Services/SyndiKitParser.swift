//
//  SyndiKitParser.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

public import Foundation
@preconcurrency import SyndiKit

/// SyndiKit-based implementation of FeedParserProtocol
/// Provides unified parsing interface with caching and network abstraction
public final class SyndiKitParser: @unchecked Sendable {
  private let httpClient: HTTPClientProtocol
  private let cache: FeedCacheProtocol
  private let synDecoder: SynDecoder
  private let cacheConfig: FeedCacheConfig

  public init(
    httpClient: HTTPClientProtocol = URLSessionHTTPClient(),
    cache: FeedCacheProtocol = InMemoryFeedCache(),
    cacheConfig: FeedCacheConfig = FeedCacheConfig()
  ) {
    self.httpClient = httpClient
    self.cache = cache
    self.synDecoder = SynDecoder()
    self.cacheConfig = cacheConfig
  }

  public func parse(url: URL) async throws -> ParsedFeed {
    // Try cache first
    if let cachedFeed = try? await cache.get(for: url) {
      return cachedFeed
    }

    // Fetch and parse
    let data = try await httpClient.fetch(url: url)
    let feedable = try synDecoder.decode(data)

    // Map to ParsedFeed
    let parsedFeed = try mapToParsedfeed(feedable, url: url)

    // Cache the result
    let expirationDate = Date().addingTimeInterval(cacheConfig.defaultExpirationInterval)
    try? await cache.set(parsedFeed, for: url, expirationDate: expirationDate)

    return parsedFeed
  }
}

// MARK: - Private Mapping Methods

extension SyndiKitParser {
  fileprivate func mapToParsedfeed(_ feedable: Feedable, url: URL) throws -> ParsedFeed {
    // Use URL as the feed ID
    let feedID = url
    let articles = try feedable.children.map { entryable in
      try mapToArticle(entryable, feedID: feedID)
    }

    let authors = feedable.authors.map { author in
      ParsedAuthor(
        name: author.name,
        email: author.email,
        url: author.uri
      )
    }

    let syndicationUpdate = feedable.syndication.map { syndication in
      ParsedSyndicationUpdate(
        period: syndication.period.rawValue,
        frequency: syndication.frequency,
        base: syndication.base
      )
    }

    let feedFormat = detectFeedFormat(feedable)

    return ParsedFeed(
      title: feedable.title,
      subtitle: feedable.summary,
      url: url,
      siteURL: feedable.siteURL,
      imageURL: feedable.image,
      lastUpdated: feedable.updated,
      authors: authors,
      copyright: feedable.copyright,
      articles: articles,
      youtubeChannelID: feedable.youtubeChannelID,
      syndicationUpdate: syndicationUpdate,
      feedFormat: feedFormat
    )
  }

  fileprivate func mapToArticle(_ entryable: Entryable, feedID: URL) throws -> Article {
    // Combine authors into a single string for the existing Article model
    let authorString = entryable.authors.map(\.name).joined(separator: ", ")

    // Use URL from entry, or create a placeholder if nil
    guard let url = entryable.url else {
      // Create a placeholder URL using the entry ID if URL is missing
      guard let placeholderURL = URL(string: "https://example.com/\(entryable.id)") else {
        throw FeedParserError.invalidArticleURL
      }
      return createArticle(
        feedID: feedID,
        title: entryable.title,
        excerpt: entryable.summary,
        content: entryable.contentHtml,
        author: authorString.isEmpty ? nil : authorString,
        url: placeholderURL,
        imageURL: entryable.imageURL,
        publishedDate: entryable.published ?? Date()
      )
    }

    return createArticle(
      feedID: feedID,
      title: entryable.title,
      excerpt: entryable.summary,
      content: entryable.contentHtml,
      author: authorString.isEmpty ? nil : authorString,
      url: url,
      imageURL: entryable.imageURL,
      publishedDate: entryable.published ?? Date()
    )
  }

  private func createArticle(
    feedID: URL,
    title: String,
    excerpt: String?,
    content: String?,
    author: String?,
    url: URL,
    imageURL: URL?,
    publishedDate: Date
  ) -> Article {
    Article(
      feedID: feedID,
      title: title,
      excerpt: excerpt,
      content: content,
      author: author,
      url: url,
      imageURL: imageURL,
      publishedDate: publishedDate
    )
  }

  fileprivate func detectFeedFormat(_ feedable: Feedable) -> FeedFormat {
    // Check if it's a YouTube channel
    if feedable.youtubeChannelID != nil {
      return .youTube
    }

    // Check if it's a podcast (has media content in children)
    let hasPodcastContent = feedable.children.contains { entry in
      entry.media != nil
    }
    if hasPodcastContent {
      return .podcast
    }

    // Determine format based on type
    switch String(describing: type(of: feedable)) {
    case let name where name.contains("RSS"):
      return .rss
    case let name where name.contains("Atom"):
      return .atom
    case let name where name.contains("JSON"):
      return .jsonFeed
    default:
      return .unknown
    }
  }
}
