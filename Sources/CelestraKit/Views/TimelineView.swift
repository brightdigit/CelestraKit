// TimelineView.swift
// CelestraKit
//
// Created for Celestra on 2025-08-07.

#if canImport(SwiftUI)
  public import SwiftUI

  /// Main timeline view displaying articles in a chronological feed
  public struct TimelineView: View {
    @State private var articles: [Article] = []
    @State private var selectedArticle: Article?
    @State private var isLoading = true
    @State private var selectedFilter: TimelineFilter = .all

    private let mockData = MockDataService.shared

    public init() {}

    public var body: some View {
      NavigationStack {
        ZStack {
          // Background gradient
          LinearGradient(
            colors: [
              Color(white: 0.98),
              Color(white: 0.95),
            ],
            startPoint: .top,
            endPoint: .bottom
          )
          .ignoresSafeArea()

          if isLoading {
            ProgressView()
              .controlSize(.large)
          } else {
            ScrollView {
              LazyVStack(spacing: 16) {
                ForEach(filteredArticles) { article in
                  ArticleView(article: article)
                    .onTapGesture {
                      selectedArticle = article
                    }
                }
              }
              .padding()
            }
          }
        }
        .navigationTitle("Timeline")
        #if os(iOS)
          .navigationBarTitleDisplayMode(.large)
        #endif
        #if !os(watchOS)
          .toolbar {
            ToolbarItem(placement: .automatic) {
              Menu {
                ForEach(TimelineFilter.allCases, id: \.self) { filter in
                  Button(
                    action: {
                      selectedFilter = filter
                    },
                    label: {
                      Label(filter.rawValue, systemImage: filter.icon)
                    }
                  )
                }
              } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                .symbolRenderingMode(.hierarchical)
              }
            }
          }
        #endif
        .sheet(item: $selectedArticle) { article in
          ArticleDetailView(article: article)
        }
      }
      .task {
        await loadArticles()
      }
    }

    private var filteredArticles: [Article] {
      switch selectedFilter {
      case .all:
        return articles
      case .unread:
        return articles.filter { !$0.isRead }
      case .starred:
        return articles.filter { $0.isStarred }
      }
    }

    private func loadArticles() async {
      // Simulate network delay
      try? await Task.sleep(nanoseconds: 500_000_000)
      articles = mockData.articles()
      isLoading = false
    }
  }

  #Preview {
    TimelineView()
  }
#endif
