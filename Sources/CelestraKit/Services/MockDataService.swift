// MockDataService.swift
// CelestraKit
//
// Created for Celestra on 2025-08-07.

#if canImport(CoreData)
  public import Foundation
  import Observation

  /// Service providing data with Core Data backend, maintaining the same API for UI compatibility
  @Observable
  public final class MockDataService {
    @MainActor public static let shared = MockDataService()

    private let feedRepository: FeedRepository
    private let articleRepository: ArticleRepository
    private var hasInitializedData = false

    private init() {
      self.feedRepository = FeedRepository()
      self.articleRepository = ArticleRepository()
    }

    // MARK: - Public API (maintains original interface)

    public var feeds: [Feed] {
      // Initialize data if needed
      if !hasInitializedData {
        initializeMockData()
        hasInitializedData = true
      }

      return feedRepository.getActiveFeeds().compactMap(Feed.init)
    }

    public func articles(for feedID: UUID? = nil) -> [Article] {
      // Initialize data if needed
      if !hasInitializedData {
        initializeMockData()
        hasInitializedData = true
      }

      if let feedID = feedID, let cdFeed = feedRepository.getFeed(by: feedID) {
        return articleRepository.getArticles(for: cdFeed).compactMap(Article.init)
      }
      return articleRepository.getAllArticles().compactMap(Article.init)
    }

    // MARK: - Core Data Management

    private func initializeMockData() {
      // Check if we already have data
      if feedRepository.getFeedCount() > 0 {
        return
      }

      // Add mock feeds
      let mockFeeds = createMockFeeds()

      for (feedData, sortOrder) in zip(mockFeeds, 0..<mockFeeds.count) {
        let feed = feedRepository.addFeed(
          title: feedData.title,
          url: feedData.url,
          category: feedData.category,
          subtitle: feedData.subtitle
        )
        feed.sortOrder = Int32(sortOrder)
        if let imageURL = feedData.imageURL {
          feed.imageURL = imageURL
        }

        // Add mock articles for this feed
        let mockArticles = generateMockArticles(for: feed, count: feedData.unreadCount + Int.random(in: 3...8))
        for (articleData, _) in zip(mockArticles, 0..<mockArticles.count) {
          _ = try? articleRepository.addArticle(
            guid: articleData.id,
            title: articleData.title,
            url: articleData.url,
            feed: feed,
            content: articleData.content,
            excerpt: articleData.excerpt,
            author: articleData.author,
            publishedDate: articleData.publishedDate,
            estimatedReadingTime: articleData.estimatedReadingTime
          )
        }
      }
    }

    private struct MockFeedData {
      let title: String
      let subtitle: String?
      let url: URL
      let imageURL: URL?
      let category: FeedCategory
      let unreadCount: Int
    }

    private func createMockFeeds() -> [MockFeedData] {
      // swiftlint:disable force_unwrapping
      [
        MockFeedData(
          title: "The Verge",
          subtitle: "Technology news and media",
          url: URL(string: "https://www.theverge.com/rss/index.xml")!,
          imageURL: URL(string: "https://cdn.vox-cdn.com/uploads/chorus_asset/file/7396113/verge.0.png")!,
          category: .technology,
          unreadCount: 12
        ),
        MockFeedData(
          title: "Daring Fireball",
          subtitle: "By John Gruber",
          url: URL(string: "https://daringfireball.net/feeds/main")!,
          imageURL: nil,
          category: .technology,
          unreadCount: 3
        ),
        MockFeedData(
          title: "Designer News",
          subtitle: "Where the design community meets",
          url: URL(string: "https://www.designernews.co/feed")!,
          imageURL: nil,
          category: .design,
          unreadCount: 7
        ),
        MockFeedData(
          title: "Stratechery",
          subtitle: "Ben Thompson on the business of technology",
          url: URL(string: "https://stratechery.com/feed/")!,
          imageURL: nil,
          category: .business,
          unreadCount: 2
        ),
        MockFeedData(
          title: "MacStories",
          subtitle: "iOS, iPad, and Mac news",
          url: URL(string: "https://www.macstories.net/feed/")!,
          imageURL: URL(string: "https://www.macstories.net/images/macstories-avatar.png")!,
          category: .technology,
          unreadCount: 5
        ),
      ]
      // swiftlint:enable force_unwrapping
    }

    private func generateMockArticles(for feed: CDFeed, count: Int) -> [Article] {
      var articles: [Article] = []

      for i in 0..<count {
        let hoursAgo = Double(i * 2)
        let isRead = i >= feed.unreadCount

        guard let feedID = feed.id else { continue }

        articles.append(
          Article(
            id: UUID().uuidString,
            feedID: feedID,
            title: mockTitles[i % mockTitles.count],
            excerpt: mockExcerpts[i % mockExcerpts.count],
            content: mockContent,
            author: mockAuthors[i % mockAuthors.count],
            // swiftlint:disable:next force_unwrapping
            url: URL(string: "https://example.com/article-\(i)")!,
            imageURL: i % 3 == 0 ? mockImageURL(for: i) : nil,
            publishedDate: Date().addingTimeInterval(-hoursAgo * 3600),
            isRead: isRead,
            isStarred: i % 7 == 0,
            estimatedReadingTime: Int.random(in: 3...15)
          )
        )
      }

      return articles.sorted { $0.publishedDate > $1.publishedDate }
    }

    // MARK: - Mock Data

    private let mockTitles = [
      "Apple Announces Revolutionary AR Glasses at WWDC 2025",
      "The Future of Swift: What's Coming in Swift 7",
      "Design Trends That Will Define 2025",
      "How AI is Transforming User Experience Design",
      "Breaking: Major Security Update for iOS 26",
      "The Rise of Spatial Computing in Everyday Apps",
      "SwiftUI 6: Everything You Need to Know",
      "Why Privacy-First Design Matters More Than Ever",
      "The Economics of the App Store in 2025",
      "Building Accessible Apps: A Complete Guide",
    ]

    // swiftlint:disable line_length
    private let mockExcerpts = [
      "In a groundbreaking announcement today, Apple revealed its long-awaited AR glasses, featuring revolutionary display technology and seamless iOS integration...",
      "Swift 7 brings major improvements to concurrency, type inference, and compile times. Here's what developers need to know about the upcoming release...",
      "From neo-morphism to liquid glass effects, 2025 is shaping up to be an exciting year for digital design. We explore the trends that will dominate...",
      "Artificial intelligence is no longer just a buzzword. It's fundamentally changing how we approach user experience design, from personalization to accessibility...",
      "Apple has released iOS 26.1 with critical security patches addressing multiple vulnerabilities. All users are advised to update immediately...",
      "Spatial computing is moving beyond VR headsets into everyday applications. Here's how developers are adapting their apps for this new paradigm...",
      "SwiftUI 6 introduces powerful new features including enhanced navigation APIs, improved performance, and better integration with UIKit...",
      "As data breaches become more common, privacy-first design is no longer optional. We examine best practices for protecting user data...",
      "The App Store economy continues to evolve with new monetization models and changing user expectations. Here's what developers need to know...",
      "Creating truly accessible apps goes beyond meeting minimum requirements. This comprehensive guide covers everything from VoiceOver to Dynamic Type...",
    ]
    // swiftlint:enable line_length

    private let mockAuthors = [
      "Sarah Chen",
      "Marcus Johnson",
      "Elena Rodriguez",
      "David Park",
      "Lisa Thompson",
    ]

    // swiftlint:disable line_length
    private let mockContent = """
      <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.</p>

      <h2>Key Points</h2>

      <p>Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>

      <h3>Technical Details</h3>

      <p>Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>

      <blockquote>"This is a revolutionary step forward in the industry." - Industry Expert</blockquote>

      <p>Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.</p>

      <h2>Conclusion</h2>

      <p>At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident.</p>
      """
    // swiftlint:enable line_length

    private func mockImageURL(for index: Int) -> URL? {
      let imageURLs = [
        "https://picsum.photos/800/600?random=\(index)",
        "https://source.unsplash.com/random/800x600?technology&sig=\(index)",
        "https://loremflickr.com/800/600/technology?random=\(index)",
      ]
      return URL(string: imageURLs[index % imageURLs.count])
    }
  }
#endif
