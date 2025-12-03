//
//  FeedDiscoveryService.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

public import Foundation

/// Protocol for feed discovery operations
public protocol FeedDiscoveryProtocol: Sendable {
  /// Discovers feeds from a given URL (website or direct feed URL)
  /// - Parameter url: The URL to discover feeds from
  /// - Returns: Array of discovered feed URLs with their metadata
  /// - Throws: FeedDiscoveryError for discovery failures
  func discoverFeeds(from url: URL) async throws -> [DiscoveredFeed]

  /// Validates if a URL is a valid feed URL
  /// - Parameter url: The URL to validate
  /// - Returns: True if the URL appears to be a valid feed
  func validateFeedURL(_ url: URL) async throws -> Bool

  /// Detects feed format without full parsing
  /// - Parameter url: The feed URL to analyze
  /// - Returns: The detected feed format
  func detectFormat(for url: URL) async throws -> FeedFormat
}

/// Intelligent feed discovery service that can auto-detect feeds from websites
public final class FeedDiscoveryService: FeedDiscoveryProtocol, @unchecked Sendable {
  private let httpClient: any HTTPClientProtocol
  private let config: FeedDiscoveryConfig

  public init(
    httpClient: any HTTPClientProtocol = URLSessionHTTPClient(),
    config: FeedDiscoveryConfig = FeedDiscoveryConfig()
  ) {
    self.httpClient = httpClient
    self.config = config
  }

  public func discoverFeeds(from url: URL) async throws -> [DiscoveredFeed] {
    // First, check if the URL itself is a feed
    if let directFeed = try await checkDirectFeed(url: url) {
      return [directFeed]
    }

    // If not a direct feed, parse HTML to discover feeds
    return try await discoverFeedsFromHTML(url: url)
  }

  public func validateFeedURL(_ url: URL) async throws -> Bool {
    do {
      let data = try await httpClient.fetch(url: url)
      return isLikelyFeedContent(data)
    } catch {
      throw FeedDiscoveryError.networkError(underlying: error)
    }
  }

  public func detectFormat(for url: URL) async throws -> FeedFormat {
    let data = try await httpClient.fetch(url: url)
    return detectFormatFromData(data) ?? .unknown
  }
}

// MARK: - Private Implementation

extension FeedDiscoveryService {
  private func checkDirectFeed(url: URL) async throws -> DiscoveredFeed? {
    do {
      let data = try await httpClient.fetch(url: url)

      if isLikelyFeedContent(data) {
        let format = detectFormatFromData(data)
        let title = extractTitleFromFeedData(data)
        return DiscoveredFeed(url: url, title: title, format: format)
      }

      return nil
    } catch {
      return nil  // Not a feed, continue with HTML discovery
    }
  }

  private func discoverFeedsFromHTML(url: URL) async throws -> [DiscoveredFeed] {
    let data = try await httpClient.fetch(url: url)
    guard let htmlString = String(data: data, encoding: .utf8) else {
      throw FeedDiscoveryError.htmlParsingFailed
    }
    var discoveredFeeds: [DiscoveredFeed] = []
    // Parse HTML for feed links
    discoveredFeeds.append(contentsOf: parseFeedLinksFromHTML(htmlString, baseURL: url))
    // Try common feed URL patterns
    discoveredFeeds.append(contentsOf: await tryCommonFeedPatterns(baseURL: url))
    // Remove duplicates and validate
    let uniqueFeeds = Array(Set(discoveredFeeds.map(\.url)))
      .compactMap { feedURL in
        discoveredFeeds.first { $0.url == feedURL }
      }

    if uniqueFeeds.isEmpty {
      throw FeedDiscoveryError.noFeedsFound
    }

    return uniqueFeeds
  }

  private func parseFeedLinksFromHTML(_ html: String, baseURL: URL) -> [DiscoveredFeed] {
    var feeds: [DiscoveredFeed] = []
    // Use NSRegularExpression for HTML parsing
    do {
      let pattern = """
        <link[^>]*(?:type=["']application/(?:rss\\+xml|atom\\+xml)|rel=["']alternate)[^>]*href=["']([^"']+)["'][^>]*>
        """
      let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
      let range = NSRange(location: 0, length: html.utf16.count)
      let matches = regex.matches(in: html, options: [], range: range)

      for match in matches {
        guard match.numberOfRanges > 1,
          let hrefRange = Range(match.range(at: 1), in: html)
        else {
          continue
        }

        let hrefString = String(html[hrefRange])
        guard let feedURL = URL(string: hrefString, relativeTo: baseURL) else {
          continue
        }

        // Extract the full link tag for title and type extraction
        let fullMatch = Range(match.range(at: 0), in: html)
        let linkTag = fullMatch.map { String(html[$0]) } ?? ""

        let title = extractTitleFromLinkTag(linkTag)
        let type = extractTypeFromLinkTag(linkTag)
        let format = typeToFeedFormat(type)

        feeds.append(DiscoveredFeed(url: feedURL, title: title, type: type, format: format))
      }
    } catch {
      // If regex fails, fall back to simple string parsing
      return []
    }

    return feeds
  }

  private func tryCommonFeedPatterns(baseURL: URL) async -> [DiscoveredFeed] {
    let commonPatterns = [
      "/feed",
      "/rss",
      "/atom",
      "/feed.xml",
      "/rss.xml",
      "/atom.xml",
      "/index.xml",
      "/feeds/all.atom.xml",
      "/.rss",
    ]

    var discoveredFeeds: [DiscoveredFeed] = []

    for pattern in commonPatterns {
      guard let potentialFeedURL = URL(string: pattern, relativeTo: baseURL) else {
        continue
      }

      do {
        if try await validateFeedURL(potentialFeedURL) {
          let format = try? await detectFormat(for: potentialFeedURL)
          discoveredFeeds.append(DiscoveredFeed(url: potentialFeedURL, format: format))
        }
      } catch {
        // Continue trying other patterns
        continue
      }
    }

    return discoveredFeeds
  }

  private func isLikelyFeedContent(_ data: Data) -> Bool {
    guard let content = String(data: data.prefix(1024), encoding: .utf8) else {
      return false
    }

    let feedIndicators = [
      "<?xml",
      "<rss",
      "<feed",
      "\"version\":",  // JSON Feed
      "\"feed_url\":",  // JSON Feed
    ]

    return feedIndicators.contains { content.localizedCaseInsensitiveContains($0) }
  }

  private func detectFormatFromData(_ data: Data) -> FeedFormat? {
    guard let content = String(data: data.prefix(2048), encoding: .utf8) else {
      return nil
    }

    // Check for JSON Feed
    if content.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{")
      && (content.contains("\"version\":") || content.contains("\"feed_url\":")) {
      return .jsonFeed
    }

    // Check for Atom
    if content.contains("<feed") && content.contains("xmlns=\"http://www.w3.org/2005/Atom\"") {
      return .atom
    }

    // Check for RSS
    if content.contains("<rss") || content.contains("<channel>") {
      // Check if it's a podcast
      if content.contains("itunes:") || content.contains("podcast:") {
        return .podcast
      }
      return .rss
    }

    return .unknown
  }

  private func extractTitleFromFeedData(_ data: Data) -> String? {
    guard let content = String(data: data.prefix(4096), encoding: .utf8) else {
      return nil
    }

    // Try to extract title from feed content using NSRegularExpression
    do {
      let pattern = "<title[^>]*>([^<]*)</title>"
      let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
      let range = NSRange(location: 0, length: content.utf16.count)
      if let match = regex.firstMatch(in: content, options: [], range: range),
        match.numberOfRanges > 1,
        let titleRange = Range(match.range(at: 1), in: content) {
        return String(content[titleRange]).trimmingCharacters(in: .whitespacesAndNewlines)
      }
    } catch {
      // Fall back to simple string search if regex fails
    }

    return nil
  }

  private func extractTitleFromLinkTag(_ linkTag: String) -> String? {
    do {
      let pattern = "title=[\"']([^\"']*)[\"']"
      let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
      let range = NSRange(location: 0, length: linkTag.utf16.count)
      if let match = regex.firstMatch(in: linkTag, options: [], range: range),
        match.numberOfRanges > 1,
        let titleRange = Range(match.range(at: 1), in: linkTag) {
        return String(linkTag[titleRange])
      }
    } catch {
      // Fall back to simple search if regex fails
    }
    return nil
  }

  private func extractTypeFromLinkTag(_ linkTag: String) -> String? {
    do {
      let pattern = "type=[\"']([^\"']*)[\"']"
      let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
      let range = NSRange(location: 0, length: linkTag.utf16.count)
      if let match = regex.firstMatch(in: linkTag, options: [], range: range),
        match.numberOfRanges > 1,
        let typeRange = Range(match.range(at: 1), in: linkTag) {
        return String(linkTag[typeRange])
      }
    } catch {
      // Fall back to simple search if regex fails
    }
    return nil
  }

  private func typeToFeedFormat(_ type: String?) -> FeedFormat? {
    guard let type = type?.lowercased() else { return nil }

    if type.contains("rss") {
      return .rss
    } else if type.contains("atom") {
      return .atom
    } else if type.contains("json") {
      return .jsonFeed
    }

    return nil
  }
}
