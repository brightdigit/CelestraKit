import Foundation

#if canImport(CoreData)
  public import CoreData
  public import Observation

  private let kLogger = createLogger(subsystem: "com.celestra.app", category: "SimpleFeedUpdater")

  /// Simple sequential feed updater for MVP
  /// Replaces 900+ lines of complex queue/circuit breaker infrastructure
  @MainActor
  @Observable
  public final class SimpleFeedUpdater {
    private let parser: SyndiKitParser
    private let articleRepo: ArticleRepository
    private let feedRepo: FeedRepository
    private let rateLimitDelay: TimeInterval

    public private(set) var isUpdating = false
    public private(set) var progress: Double = 0
    public private(set) var currentFeedTitle: String?

    public init(
      parser: SyndiKitParser,
      articleRepo: ArticleRepository,
      feedRepo: FeedRepository,
      rateLimitDelay: TimeInterval = 0.2  // Default: 200ms between feeds
    ) {
      self.parser = parser
      self.articleRepo = articleRepo
      self.feedRepo = feedRepo
      self.rateLimitDelay = rateLimitDelay
    }

    /// Update all active feeds sequentially
    public func updateAllFeeds() async {
      isUpdating = true
      defer { cleanupAfterUpdate() }

      let feeds = feedRepo.getActiveFeeds()
      guard !feeds.isEmpty else {
        kLogger.info("No feeds to update")
        return
      }

      kLogger.info("Starting update of \(feeds.count) feeds")

      for (index, feed) in feeds.enumerated() {
        updateProgress(index: index, total: feeds.count, feedTitle: feed.title)
        await updateSingleFeedInBatch(feed)
        try? await Task.sleep(for: .seconds(rateLimitDelay))
      }

      kLogger.info("Completed update of all feeds")
    }

    /// Update a single feed
    public func updateFeed(_ feed: CDFeed) async throws {
      guard let feedURL = feed.url else {
        throw FeedParserError.invalidURL
      }

      kLogger.info("Updating single feed: \(feed.title ?? "Unknown")")

      let parsedFeed = try await parser.parse(url: feedURL)
      let newArticleCount = try await saveArticles(from: parsedFeed, to: feed)
      try feedRepo.save()

      kLogger.info("Updated feed '\(feed.title ?? "Unknown")': \(newArticleCount) new articles")
    }

    // MARK: - Private Helper Methods

    private func cleanupAfterUpdate() {
      isUpdating = false
      currentFeedTitle = nil
      progress = 1.0
    }

    private func updateProgress(index: Int, total: Int, feedTitle: String?) {
      currentFeedTitle = feedTitle
      progress = Double(index) / Double(total)
    }

    private func updateSingleFeedInBatch(_ feed: CDFeed) async {
      guard let feedURL = feed.url else {
        kLogger.warning("Feed '\(feed.title ?? "Unknown")' has no URL, skipping")
        return
      }

      do {
        let parsedFeed = try await parser.parse(url: feedURL)
        let newArticleCount = try await saveArticles(from: parsedFeed, to: feed)
        try feedRepo.save()
        kLogger.info("Updated feed '\(feed.title ?? "Unknown")': \(newArticleCount) new articles")
      } catch {
        kLogger.error("Failed to update feed '\(feed.title ?? "Unknown")': \(error.localizedDescription)")
      }
    }

    private func saveArticles(from parsedFeed: ParsedFeed, to feed: CDFeed) async throws -> Int {
      var newArticleCount = 0

      for article in parsedFeed.articles {
        do {
          _ = try articleRepo.addArticle(
            guid: article.id,
            title: article.title,
            url: article.url,
            feed: feed,
            content: article.content,
            excerpt: article.excerpt,
            author: article.author,
            publishedDate: article.publishedDate
          )
          newArticleCount += 1
        } catch CoreDataError.duplicateEntry {
          // Expected - article already exists, skip silently
          kLogger.debug("Skipping existing article: \(article.title)")
        } catch {
          // Unexpected error - log but continue processing other articles
          kLogger.error("Failed to add article '\(article.title)': \(error.localizedDescription)")
        }
      }

      // Update feed metadata
      feed.lastFetched = Date()
      feed.lastUpdated = parsedFeed.lastUpdated

      return newArticleCount
    }
  }
#endif
