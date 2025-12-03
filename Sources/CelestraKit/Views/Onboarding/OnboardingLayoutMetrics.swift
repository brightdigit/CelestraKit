//
//  OnboardingLayoutMetrics.swift
//  CelestraKit
//
//  Created by Claude Code on 2025-10-27.
//

#if canImport(SwiftUI)
  import SwiftUI

  /// Centralized layout measurements for onboarding screens to ensure consistency
  /// and proper viewport calculations across all device sizes.
  public enum OnboardingLayoutMetrics {
    // MARK: - Fixed Component Heights

    /// Height reserved for progress indicator at top of screen
    public static let progressIndicatorHeight: CGFloat = 60

    /// Height reserved for navigation buttons (Back/Continue) at bottom
    public static let navigationButtonsHeight: CGFloat = 80

    /// Total fixed height consumed by chrome (progress + buttons)
    public static var fixedChromeHeight: CGFloat {
      progressIndicatorHeight + navigationButtonsHeight
    }

    // MARK: - Item Heights

    /// Height of persona/role selection cards
    public static let personaCardHeight: CGFloat = 60

    /// Height of topic tag buttons
    public static let topicTagHeight: CGFloat = 44

    /// Height of feed recommendation rows
    public static let feedRowHeight: CGFloat = 80

    /// Height of custom text input field (when "Other" is selected)
    public static let customInputHeight: CGFloat = 100

    // MARK: - Spacing

    /// Vertical spacing between persona cards
    public static let personaCardSpacing: CGFloat = 12

    /// Vertical spacing between topic tags
    public static let topicTagSpacing: CGFloat = 8

    /// Vertical spacing between feed rows
    public static let feedRowSpacing: CGFloat = 12

    /// Padding around main content area
    public static let contentPadding: CGFloat = 20

    // MARK: - Calculated Available Space

    /// Calculates available content height for given screen geometry
    /// - Parameters:
    ///   - screenHeight: Total screen height from GeometryReader
    ///   - top: Safe area top inset
    ///   - bottom: Safe area bottom inset
    /// - Returns: Available height for scrollable/paginated content
    public static func availableContentHeight(
      screenHeight: CGFloat,
      top: CGFloat,
      bottom: CGFloat
    ) -> CGFloat {
      let totalSafeArea = top + bottom
      let usableHeight = screenHeight - totalSafeArea - fixedChromeHeight - (contentPadding * 2)
      return max(200, usableHeight)  // Minimum 200pt for safety
    }

    // MARK: - Maximum Visible Items

    /// Calculates maximum number of persona cards that fit in available space
    /// - Parameter availableHeight: Height available for content
    /// - Returns: Maximum number of cards that fit without scrolling
    public static func maxVisiblePersonaCards(availableHeight: CGFloat) -> Int {
      let itemWithSpacing = personaCardHeight + personaCardSpacing
      let maxItems = Int(floor((availableHeight + personaCardSpacing) / itemWithSpacing))
      return max(1, maxItems)
    }

    /// Calculates maximum number of topic tags that fit in available space
    /// - Parameter availableHeight: Height available for content
    /// - Returns: Maximum number of tags that fit without scrolling
    public static func maxVisibleTopicTags(availableHeight: CGFloat) -> Int {
      let itemWithSpacing = topicTagHeight + topicTagSpacing
      let maxItems = Int(floor((availableHeight + topicTagSpacing) / itemWithSpacing))
      return max(1, maxItems)
    }

    /// Calculates maximum number of feed rows that fit in available space
    /// - Parameter availableHeight: Height available for content
    /// - Returns: Maximum number of feeds that fit without scrolling
    public static func maxVisibleFeedRows(availableHeight: CGFloat) -> Int {
      let itemWithSpacing = feedRowHeight + feedRowSpacing
      let maxItems = Int(floor((availableHeight + feedRowSpacing) / itemWithSpacing))
      return max(1, maxItems)
    }

    // MARK: - Animation

    /// Standard animation duration for screen transitions
    public static let transitionDuration: CGFloat = 0.3
  }
#endif
