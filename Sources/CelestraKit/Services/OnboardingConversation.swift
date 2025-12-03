// OnboardingConversation.swift
// CelestraKit
//
// Created for Celestra on 2025-10-27.

#if canImport(FoundationModels)
  public import Foundation
  public import FoundationModels

  /// Manages the conversational onboarding flow using FoundationModels
  @MainActor
  @Observable
  public final class OnboardingConversation {
    /// Shared instance
    public static let shared = OnboardingConversation()

    /// Current onboarding state
    public let state = OnboardingState()

    /// Language model session for multi-turn conversation
    private var session: LanguageModelSession?

    /// System language model
    private let model = SystemLanguageModel.default

    /// Whether Apple Intelligence is available
    public var isAvailable: Bool {
      model.availability == .available
    }

    private init() {}

    /// Start a new onboarding session
    public func startSession() throws {
      guard isAvailable else {
        throw OnboardingError.modelUnavailable
      }

      let instructions = """
        You are a helpful assistant for Celestra, a premium RSS reader app.
        Your role is to help users discover RSS feeds that match their interests.

        Guidelines:
        - Generate relevant, specific topic tags based on user's role and interests
        - Keep suggestions focused on content types available in RSS feeds
        - Consider technical depth appropriate to their role
        - Prioritize quality content sources
        - Be encouraging and helpful
        - Keep responses concise and actionable
        """

      session = LanguageModelSession(instructions: Instructions(instructions))
      state.reset()
    }

    /// Generate diverse persona options for role selection
    public func generatePersonas() async throws {
      guard let session = session else {
        throw OnboardingError.sessionNotInitialized
      }

      let generator = OnboardingPersonaGenerator(session: session, state: state)
      try await generator.generate()
    }

    /// Generate topic tags for step 2 based on selected role
    public func generateTopicTags(for role: OnboardingRole) async throws {
      guard let session = session else {
        throw OnboardingError.sessionNotInitialized
      }

      let generator = OnboardingTagGenerator(session: session, state: state)
      try await generator.generateTopicTags(for: role)
    }

    /// Generate refined tags for step 3 based on selected topics
    public func generateRefinedTags(for topics: Set<String>) async throws {
      guard let session = session else {
        throw OnboardingError.sessionNotInitialized
      }

      let generator = OnboardingTagGenerator(session: session, state: state)
      try await generator.generateRefinedTags(for: topics)
    }

    /// Generate feed recommendations based on all selections
    public func generateFeedRecommendations() async throws {
      guard let session = session else {
        throw OnboardingError.sessionNotInitialized
      }

      let generator = OnboardingRecommendationGenerator(session: session, state: state)
      try await generator.generate()
    }

    /// End the current session
    public func endSession() {
      session = nil
    }
  }

  /// Errors that can occur during onboarding
  public enum OnboardingError: LocalizedError {
    case modelUnavailable
    case sessionNotInitialized
    case missingRole

    public var errorDescription: String? {
      switch self {
      case .modelUnavailable:
        return "Apple Intelligence is not available on this device."
      case .sessionNotInitialized:
        return "Onboarding session not initialized."
      case .missingRole:
        return "Please select a role first."
      }
    }
  }
#endif
