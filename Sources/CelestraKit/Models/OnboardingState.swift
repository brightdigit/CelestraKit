// OnboardingState.swift
// CelestraKit
//
// Created for Celestra on 2025-10-27.

import Foundation
public import Observation

/// State tracking for the onboarding conversation flow
@MainActor
@Observable
public final class OnboardingState {
  /// Current step in the onboarding flow
  public var currentStep: OnboardingStep = .welcome

  /// AI-generated or fallback persona options
  public var availableRoles: [OnboardingRole] = []

  /// Selected user role
  public var selectedRole: OnboardingRole?

  /// Custom persona description (when "Other" is selected)
  public var customPersonaDescription: String?

  /// Whether personas are currently being generated
  public var isGeneratingPersonas = false

  /// Topics selected in step 2
  public var selectedTopics: Set<String> = []

  /// Refined topics selected in step 3
  public var refinedTopics: Set<String> = []

  /// AI-generated tag suggestions for current step
  public var suggestedTags: [String] = []

  /// Whether tags are currently being generated
  public var isGeneratingTags = false

  /// Feed recommendations from AI
  #if canImport(FoundationModels)
    public var feedRecommendations: [FeedRecommendation] = []
  #endif

  /// Whether feed recommendations are being generated
  public var isGeneratingRecommendations = false

  /// Error message if generation fails
  public var errorMessage: String?

  public init() {}

  /// Move to the next step
  public func advance() {
    guard let next = currentStep.next else { return }
    currentStep = next
  }

  /// Move to the previous step
  public func goBack() {
    guard let previous = currentStep.previous else { return }
    currentStep = previous
  }

  /// Whether the current step can proceed
  public var canProceed: Bool {
    switch currentStep {
    case .welcome:
      return true
    case .roleSelection:
      guard let role = selectedRole else { return false }
      // If "Other" is selected, custom description is optional but encouraged
      // We allow proceeding without it
      return true
    case .topicSelection:
      return !selectedTopics.isEmpty
    case .refinement:
      return !refinedTopics.isEmpty
    case .feedSelection:
      return false  // Final step
    }
  }

  /// Reset all state
  public func reset() {
    currentStep = .welcome
    availableRoles.removeAll()
    selectedRole = nil
    customPersonaDescription = nil
    selectedTopics.removeAll()
    refinedTopics.removeAll()
    suggestedTags.removeAll()
    #if canImport(FoundationModels)
      feedRecommendations.removeAll()
    #endif
    errorMessage = nil
  }

  /// All selected interests combined
  public var allInterests: [String] {
    Array(selectedTopics.union(refinedTopics))
  }
}
