//
//  ViewportAwareChoiceLayout.swift
//  CelestraKit
//
//  Created by Claude Code on 2025-10-27.
//

#if canImport(SwiftUI)
  public import SwiftUI

  /// A layout component that automatically calculates how many choice items can fit
  /// in the available viewport space and handles pagination accordingly.
  ///
  /// This ensures onboarding screens never require scrolling by adapting to device size.
  public struct ViewportAwareChoiceLayout<Item: Identifiable, Content: View>: View {
    // MARK: - Properties

    /// All items to display (will be paginated if needed)
    private let items: [Item]

    /// Height of each individual item
    private let itemHeight: CGFloat

    /// Vertical spacing between items
    private let spacing: CGFloat

    /// Current page index (0-based)
    @State private var currentPage: Int = 0

    /// Content builder for each visible item
    private let content: (Item) -> Content

    /// Optional callback when user requests more items (for AI generation)
    private let onRequestMore: (() -> Void)?

    // MARK: - Initialization

    /// Creates a viewport-aware choice layout
    /// - Parameters:
    ///   - items: All items to display
    ///   - itemHeight: Height of each item in points
    ///   - spacing: Vertical spacing between items
    ///   - onRequestMore: Optional callback for "Show different options" (AI regeneration)
    ///   - content: View builder for each item
    public init(
      items: [Item],
      itemHeight: CGFloat,
      spacing: CGFloat,
      onRequestMore: (() -> Void)? = nil,
      @ViewBuilder content: @escaping (Item) -> Content
    ) {
      self.items = items
      self.itemHeight = itemHeight
      self.spacing = spacing
      self.onRequestMore = onRequestMore
      self.content = content
    }

    // MARK: - Body

    public var body: some View {
      GeometryReader { geometry in
        VStack(spacing: 0) {
          // Main content area
          itemsView(availableHeight: geometry.size.height)
            .frame(maxHeight: .infinity)

          // Pagination controls (if needed)
          if totalPages > 1 {
            paginationControls
              .padding(.top, 16)
          }
        }
      }
    }

    // MARK: - Private Views

    private func itemsView(availableHeight: CGFloat) -> some View {
      let maxItems = calculateMaxVisibleItems(
        availableHeight: availableHeight, reserveSpaceForPagination: totalPages > 1)
      let visibleItems = getVisibleItems(maxItems: maxItems)

      return VStack(spacing: spacing) {
        ForEach(visibleItems) { item in
          content(item)
            .frame(height: itemHeight)
        }

        // Optional "Show different options" button for AI regeneration
        if onRequestMore != nil && currentPage == totalPages - 1 {
          Button {
            onRequestMore?()
          } label: {
            HStack {
              Image(systemName: "sparkles")
              Text("Show Different Options")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
          }
          .buttonStyle(.bordered)
          .padding(.top, 12)
        }
      }
    }

    private var paginationControls: some View {
      HStack(spacing: 20) {
        // Previous page button
        Button {
          withAnimation(.spring(response: 0.3)) {
            currentPage = max(0, currentPage - 1)
          }
        } label: {
          HStack(spacing: 6) {
            Image(systemName: "chevron.left")
              .font(.caption.weight(.semibold))
            Text("Previous")
          }
          .font(.subheadline)
          .foregroundStyle(.secondary)
        }
        .disabled(currentPage == 0)
        .opacity(currentPage == 0 ? 0.4 : 1.0)

        // Page indicator
        Text("Page \(currentPage + 1) of \(totalPages)")
          .font(.caption)
          .foregroundStyle(.secondary)

        // Next page button
        Button {
          withAnimation(.spring(response: 0.3)) {
            currentPage = min(totalPages - 1, currentPage + 1)
          }
        } label: {
          HStack(spacing: 6) {
            Text("More Options")
            Image(systemName: "chevron.right")
              .font(.caption.weight(.semibold))
          }
          .font(.subheadline)
          .foregroundStyle(.secondary)
        }
        .disabled(currentPage == totalPages - 1)
        .opacity(currentPage == totalPages - 1 ? 0.4 : 1.0)
      }
    }

    // MARK: - Helper Methods

    /// Calculates maximum number of items that fit in available height
    /// - Parameters:
    ///   - availableHeight: Total height available for content
    ///   - reserveSpaceForPagination: Whether to reserve space for pagination controls
    private func calculateMaxVisibleItems(availableHeight: CGFloat, reserveSpaceForPagination: Bool = false) -> Int {
      // Reserve space for pagination controls if requested
      let reservedSpace: CGFloat = reserveSpaceForPagination ? 60 : 0
      let usableHeight = availableHeight - reservedSpace

      // Calculate: (height + spacing) per item, but last item has no spacing
      let itemWithSpacing = itemHeight + spacing
      let maxItems = Int(floor((usableHeight + spacing) / itemWithSpacing))

      return max(1, maxItems)  // Always show at least 1 item
    }

    /// Gets items visible on current page
    private func getVisibleItems(maxItems: Int) -> [Item] {
      let startIndex = currentPage * maxItems
      let endIndex = min(startIndex + maxItems, items.count)

      guard startIndex < items.count else { return [] }
      return Array(items[startIndex..<endIndex])
    }

    /// Total number of pages needed
    private var totalPages: Int {
      // Need to calculate this with a representative available height
      // Use a conservative estimate (smaller screen size)
      let conservativeHeight: CGFloat = 500  // Approximate content area on smaller devices
      // Calculate max items WITHOUT reserving space to avoid circular dependency
      let maxItems = calculateMaxVisibleItems(availableHeight: conservativeHeight, reserveSpaceForPagination: false)
      return max(1, Int(ceil(Double(items.count) / Double(maxItems))))
    }
  }

  // MARK: - Preview Helper

  #if DEBUG
    struct ViewportAwareChoiceLayout_Previews: PreviewProvider {
      struct SampleItem: Identifiable {
        let id = UUID()
        let title: String
      }

      static var previews: some View {
        let items = (1...15).map { SampleItem(title: "Option \($0)") }

        ViewportAwareChoiceLayout(
          items: items,
          itemHeight: 60,
          spacing: 12,
          onRequestMore: {
            print("Request more options")
          },
          content: { item in
            RoundedRectangle(cornerRadius: 12)
              .fill(.blue.opacity(0.2))
              .overlay {
                Text(item.title)
              }
          }
        )
        .padding()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Viewport Aware Layout")
      }
    }
  #endif
#endif
