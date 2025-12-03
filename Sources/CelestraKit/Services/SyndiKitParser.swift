//
//  SyndiKitParser.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

public import Foundation
@preconcurrency import SyndiKit

#if canImport(CryptoKit)
  import CryptoKit
#else
  import Crypto
#endif

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Simplified SyndiKit parser using URLSession directly
/// Replaces 332 lines of HTTP/cache abstraction complexity
public final class SyndiKitParser: @unchecked Sendable {
  private let synDecoder: SynDecoder
  #if canImport(FoundationNetworking)
    private let session: URLSession

    public init() {
      self.synDecoder = SynDecoder()

      // Configure URLSession with built-in caching
      let config = URLSessionConfiguration.default
      config.requestCachePolicy = .returnCacheDataElseLoad
      config.urlCache = URLCache(
        memoryCapacity: 20 * 1024 * 1024,  // 20 MB memory cache
        diskCapacity: 100 * 1024 * 1024,  // 100 MB disk cache
        diskPath: nil
      )
      self.session = URLSession(configuration: config)
    }

    public func parse(url: URL) async throws -> ParsedFeed {
      // Fetch data using URLSession (with built-in caching)
      let (data, _) = try await session.data(from: url)

      // Decode using SyndiKit
      let feedable = try synDecoder.decode(data)

      // Map to ParsedFeed
      return try mapToParsedfeed(feedable, url: url)
    }
  #else
    // Fallback for platforms without FoundationNetworking
    public init() {
      self.synDecoder = SynDecoder()
    }

    public func parse(url: URL) async throws -> ParsedFeed {
      throw FeedParserError.networkError(underlying: URLError(.unsupportedURL))
    }
  #endif
}

// MARK: - Private Mapping Methods

extension SyndiKitParser {
  /// Create a deterministic UUID from a URL using SHA256
  private func uuid(from url: URL) -> UUID {
    // Use SHA256 for deterministic hashing (consistent across app launches)
    let urlString = url.absoluteString
    let hash = SHA256.hash(data: Data(urlString.utf8))

    // Take first 16 bytes of hash for UUID
    let hashBytes = Array(hash.prefix(16))

    // Create UUID from deterministic hash bytes
    let uuid = UUID(
      uuid: (
        hashBytes[0], hashBytes[1], hashBytes[2], hashBytes[3],
        hashBytes[4], hashBytes[5], hashBytes[6], hashBytes[7],
        hashBytes[8], hashBytes[9], hashBytes[10], hashBytes[11],
        hashBytes[12], hashBytes[13], hashBytes[14], hashBytes[15]
      ))

    return uuid
  }

  fileprivate func mapToParsedfeed(_ feedable: any Feedable, url: URL) throws -> ParsedFeed {
    // Create a deterministic UUID from the feed URL
    let feedID = uuid(from: url)
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

  fileprivate func mapToArticle(_ entryable: any Entryable, feedID: UUID) throws -> Article {
    // Combine authors into a single string for the existing Article model
    let authorString = entryable.authors.map(\.name).joined(separator: ", ")

    // Use URL from entry, or create a placeholder if nil
    guard let url = entryable.url else {
      // Create a placeholder URL using the entry ID if URL is missing
      guard let placeholderURL = URL(string: "https://example.com/\(entryable.id)") else {
        throw FeedParserError.invalidArticleURL
      }
      let articleBuilder = createArticle(
        feedID: feedID,
        title: entryable.title,
        excerpt: entryable.summary,
        content: entryable.contentHtml,
        author: authorString.isEmpty ? nil : authorString
      )
      return articleBuilder(placeholderURL, entryable.imageURL, entryable.published ?? Date())
    }

    let articleBuilder = createArticle(
      feedID: feedID,
      title: entryable.title,
      excerpt: entryable.summary,
      content: entryable.contentHtml,
      author: authorString.isEmpty ? nil : authorString
    )
    return articleBuilder(url, entryable.imageURL, entryable.published ?? Date())
  }

  private func createArticle(
    feedID: UUID,
    title: String,
    excerpt: String?,
    content: String?,
    author: String?
  ) -> (URL, URL?, Date) -> Article {
    { url, imageURL, publishedDate in
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
  }

  fileprivate func detectFeedFormat(_ feedable: any Feedable) -> FeedFormat {
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
