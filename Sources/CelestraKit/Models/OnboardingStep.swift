// OnboardingStep.swift
// CelestraKit
//
// Created for Celestra on 2025-10-27.

import Foundation

/// Steps in the onboarding conversation flow
///
/// - TODO: Localization - All user-facing strings should be moved to Localizable.strings
///   - title property (lines 24-36)
///   - question property (lines 41-53)
///   - stepLabel property (lines 58-67)
public enum OnboardingStep: Int, CaseIterable, Sendable {
  case welcome = 0
  case roleSelection = 1
  case topicSelection = 2
  case refinement = 3
  case feedSelection = 4

  /// Progress as a percentage
  public var progress: Double {
    Double(rawValue) / Double(OnboardingStep.allCases.count - 1)
  }

  /// Title for the step
  /// - TODO: Localization - Move to Localizable.strings with keys like "onboarding.step.welcome.title"
  public var title: String {
    switch self {
    case .welcome:
      return "Welcome"
    case .roleSelection:
      return "About You"
    case .topicSelection:
      return "Your Interests"
    case .refinement:
      return "Get Specific"
    case .feedSelection:
      return "Your Feeds"
    }
  }

  /// Question text for the step
  /// - TODO: Localization - Move to Localizable.strings with keys like "onboarding.step.welcome.question"
  public var question: String {
    switch self {
    case .welcome:
      return "Let's find great content for you"
    case .roleSelection:
      return "What describes you best?"
    case .topicSelection:
      return "What topics interest you?"
    case .refinement:
      return "Any specific interests?"
    case .feedSelection:
      return "Here are your personalized feed recommendations"
    }
  }

  /// Step count label (e.g., "1 of 3")
  /// - TODO: Localization - Move to Localizable.strings with format strings
  public var stepLabel: String? {
    switch self {
    case .welcome, .feedSelection:
      return nil
    case .roleSelection:
      return "1 of 3"
    case .topicSelection:
      return "2 of 3"
    case .refinement:
      return "3 of 3"
    }
  }

  /// Next step in the flow
  public var next: OnboardingStep? {
    guard let index = OnboardingStep.allCases.firstIndex(of: self),
      index < OnboardingStep.allCases.count - 1
    else {
      return nil
    }
    return OnboardingStep.allCases[index + 1]
  }

  /// Previous step in the flow
  public var previous: OnboardingStep? {
    guard let index = OnboardingStep.allCases.firstIndex(of: self),
      index > 0
    else {
      return nil
    }
    return OnboardingStep.allCases[index - 1]
  }
}
