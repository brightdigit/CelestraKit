#if canImport(SwiftUI)
  public import SwiftUI

  /// Simple scrollable choice layout for onboarding
  /// Replaces 217 lines of viewport-aware pagination complexity
  public struct SimpleChoiceLayout<Item: Identifiable, Content: View>: View {
    private let items: [Item]
    private let content: (Item) -> Content

    public init(
      items: [Item],
      @ViewBuilder content: @escaping (Item) -> Content
    ) {
      self.items = items
      self.content = content
    }

    public var body: some View {
      ScrollView {
        VStack(spacing: 12) {
          ForEach(items) { item in
            content(item)
          }
        }
        .padding()
      }
    }
  }
#endif
