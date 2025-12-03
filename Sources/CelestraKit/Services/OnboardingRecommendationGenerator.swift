// OnboardingRecommendationGenerator.swift
// CelestraKit
//
// Created for Celestra on 2025-12-03.

#if canImport(FoundationModels)
  public import Foundation
  public import FoundationModels

  /// Generates feed recommendations for onboarding
  struct OnboardingRecommendationGenerator {
    private let session: LanguageModelSession
    private let state: OnboardingState

    init(session: LanguageModelSession, state: OnboardingState) {
      self.session = session
      self.state = state
    }

    /// Generate feed recommendations based on all selections
    func generate() async throws {
      let (allInterests, roleContext) = try await MainActor.run {
        guard state.selectedRole != nil else {
          throw OnboardingError.missingRole
        }

        state.isGeneratingRecommendations = true
        state.errorMessage = nil

        let allInterests = state.allInterests.joined(separator: ", ")

        // Include custom description if "Other" was selected
        let roleContext: String
        if let customDescription = state.customPersonaDescription, !customDescription.isEmpty {
          roleContext = "The user describes themselves as: \(customDescription)"
        } else if let role = state.selectedRole {
          roleContext = "The user is a \(role.title)"
        } else {
          roleContext = "The user"
        }

        return (allInterests, roleContext)
      }

      defer {
        Task { @MainActor in
          state.isGeneratingRecommendations = false
        }
      }

      let prompt = """
        \(roleContext). They are interested in: \(allInterests)

        Generate 15-20 RSS feed recommendations that would be perfect for them.
        Focus on:
        - High-quality, regularly updated feeds
        - Mix of news, tutorials, and thought leadership
        - Variety of content types (blogs, newsletters, podcasts)
        - Both popular and niche sources

        For each feed, provide:
        - A clear title
        - The feed URL
        - A brief reason why it matches their interests
        - A relevance score
        - The primary category
        """

      do {
        // Note: This is a simplified version. In production, you'd want to use
        // a Tool that searches an actual feed directory
        let response = try await session.respond(
          to: Prompt(prompt),
          generating: [FeedRecommendation].self
        )

        await MainActor.run {
          state.feedRecommendations = response.content.sorted { $0.relevanceScore > $1.relevanceScore }
        }
      } catch let error as LanguageModelSession.GenerationError {
        await handleGenerationError(error)
      } catch {
        await MainActor.run {
          state.errorMessage = "Failed to generate recommendations. Please try again."
        }
        throw error
      }
    }

    private func handleGenerationError(_ error: LanguageModelSession.GenerationError) async {
      let message: String
      switch error {
      case .guardrailViolation:
        message = "Your request contains content we can't process. Please try different topics."
      case .refusal:
        message = "We can't help with that topic. Please try different interests."
      case .exceededContextWindowSize:
        message = "Too much information to process. Try selecting fewer topics."
      default:
        message = "Something went wrong. Please try again."
      }

      await MainActor.run {
        state.errorMessage = message
      }
    }
  }
#endif
