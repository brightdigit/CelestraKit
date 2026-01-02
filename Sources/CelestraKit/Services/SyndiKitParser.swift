//
//  SyndiKitParser.swift
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
@preconcurrency import SyndiKit

#if canImport(CryptoKit)
  import CryptoKit
#else
  import Crypto
#endif

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Simplified SyndiKit parser using HTTPClientProtocol
/// Replaces 332 lines of HTTP/cache abstraction complexity
public final class SyndiKitParser: Sendable {
  private let synDecoder: SynDecoder
  private let httpClient: any HTTPClientProtocol

  /// Initialize with optional HTTP client (defaults to cached URLSession)
  /// - Parameter httpClient: HTTP client for fetching feeds (useful for testing)
  public init(httpClient: (any HTTPClientProtocol)? = nil) {
    self.synDecoder = SynDecoder()
    self.httpClient = httpClient ?? URLSessionHTTPClient.withCaching()
  }

  public func parse(url: URL) async throws -> ParsedFeed {
    // Fetch data using HTTP client (with built-in caching)
    let data = try await httpClient.fetch(url: url)

    // Decode using SyndiKit
    let feedable = try synDecoder.decode(data)

    // Map to ParsedFeed
    return try mapToParsedfeed(feedable, url: url)
  }
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
    // Combine authors into a single string
    let authorString = entryable.authors.map(\.name).joined(separator: ", ")

    // Use URL from entry, or create a placeholder if nil
    let urlString: String
    if let url = entryable.url {
      urlString = url.absoluteString
    } else {
      // Create a placeholder URL using the entry ID if URL is missing
      urlString = "https://example.com/\(entryable.id)"
    }

    // Convert feedID UUID to string for feedRecordName
    let feedRecordName = feedID.uuidString

    // Use entry ID as GUID (convert EntryID to String using description property)
    let guid = entryable.id.description

    return Article(
      feedRecordName: feedRecordName,
      guid: guid,
      title: entryable.title,
      excerpt: entryable.summary,
      content: entryable.contentHtml,
      author: authorString.isEmpty ? nil : authorString,
      url: urlString,
      imageURL: entryable.imageURL?.absoluteString,
      publishedDate: entryable.published ?? Date()
    )
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
