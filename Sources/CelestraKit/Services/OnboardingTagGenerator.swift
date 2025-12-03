// OnboardingTagGenerator.swift
// CelestraKit
//
// Created for Celestra on 2025-12-03.

#if canImport(FoundationModels)
  public import Foundation
  public import FoundationModels

  /// Generates topic tags for onboarding interest selection
  struct OnboardingTagGenerator {
    private let session: LanguageModelSession
    private let state: OnboardingState

    init(session: LanguageModelSession, state: OnboardingState) {
      self.session = session
      self.state = state
    }

    /// Generate topic tags based on selected role
    func generateTopicTags(for role: OnboardingRole) async throws {
      await MainActor.run {
        state.isGeneratingTags = true
        state.errorMessage = nil
      }

      defer {
        Task { @MainActor in
          state.isGeneratingTags = false
        }
      }

      // Include custom description if "Other" was selected
      let roleContext = await MainActor.run {
        if let customDescription = state.customPersonaDescription, !customDescription.isEmpty {
          "The user describes themselves as: \(customDescription)"
        } else {
          "The user is a \(role.title): \(role.description)."
        }
      }

      let prompt = """
        \(roleContext)

        Generate 10-12 specific topic tags they would be interested in reading about.
        Focus on:
        - Professional development topics
        - Industry news and trends
        - Technical skills and tools
        - Related fields and interests

        Make tags specific but not too narrow (e.g., "iOS Development" not "UIKit Delegate Methods").
        """

      do {
        let response = try await session.respond(
          to: Prompt(prompt),
          generating: TagSuggestions.self
        )

        await MainActor.run {
          state.suggestedTags = response.content.tags
        }
      } catch let error as LanguageModelSession.GenerationError {
        await handleGenerationError(error)
      } catch {
        await MainActor.run {
          state.errorMessage = "Failed to generate suggestions. Please try again."
        }
        throw error
      }
    }

    /// Generate refined tags based on selected topics
    func generateRefinedTags(for topics: Set<String>) async throws {
      await MainActor.run {
        state.isGeneratingTags = true
        state.errorMessage = nil
      }

      defer {
        Task { @MainActor in
          state.isGeneratingTags = false
        }
      }

      let topicList = topics.sorted().joined(separator: ", ")

      let prompt = """
        The user is interested in: \(topicList)

        Generate 8-10 more specific subtopics or related areas they might want to follow.
        These should be:
        - More specific than the original topics
        - Related fields or adjacent interests
        - Emerging trends in these areas
        - Practical applications

        Keep tags focused and relevant to RSS feed content.
        """

      do {
        let response = try await session.respond(
          to: Prompt(prompt),
          generating: TagSuggestions.self
        )

        await MainActor.run {
          state.suggestedTags = response.content.tags
        }
      } catch let error as LanguageModelSession.GenerationError {
        await handleGenerationError(error)
      } catch {
        await MainActor.run {
          state.errorMessage = "Failed to generate suggestions. Please try again."
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
