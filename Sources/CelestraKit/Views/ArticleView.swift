// ArticleCard.swift
// CelestraKit
//
// Created for Celestra on 2025-08-07.

#if canImport(SwiftUI)
  import SwiftUI

  /// Article card component with glass effect
  struct ArticleView: View {
    let article: Article
    @State private var isHovered = false

    var content: some View {
      VStack(alignment: .leading, spacing: 12) {
        // Header with feed info and date
        HStack {
          if let feed = MockDataService.shared.feeds.first(where: { $0.url == article.feedID }) {
            Label(feed.title, systemImage: feed.category.icon)
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          Spacer()

          Text(article.publishedDate, style: .relative)
            .font(.caption)
            .foregroundStyle(.tertiary)
        }

        // Article content
        VStack(alignment: .leading, spacing: 8) {
          Text(article.title)
            .font(.headline)
            .foregroundStyle(.primary)
            .lineLimit(2)

          if let excerpt = article.excerpt {
            Text(excerpt)
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .lineLimit(3)
          }

          // Footer with author and reading time
          HStack {
            if let author = article.author {
              Text(author)
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 16) {
              if article.isStarred {
                Image(systemName: "star.fill")
                  .font(.caption)
                  .foregroundStyle(.yellow)
              }

              Label("\(article.estimatedReadingTime) min", systemImage: "clock")
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
          }
        }
      }
      .padding()
      .background {
        RoundedRectangle(cornerRadius: 16)
          .fill(.ultraThinMaterial)
      }
      .shadow(
        color: .black.opacity(0.1),
        radius: isHovered ? 12 : 8,
        y: isHovered ? 6 : 4
      )
      .scaleEffect(isHovered ? 1.02 : 1.0)
      .opacity(article.isRead ? 0.7 : 1.0)
    }

    var body: some View {
      #if os(watchOS)
        content
      #else
        content
          .animation(.easeInOut(duration: 0.2), value: isHovered)
          .onHover { hovering in
            isHovered = hovering
          }

      #endif
    }
  }

#endif
