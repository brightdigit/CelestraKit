// OnboardingPersonaGenerator.swift
// CelestraKit
//
// Created for Celestra on 2025-12-03.

#if canImport(FoundationModels)
  public import Foundation
  public import FoundationModels

  /// Generates persona options for onboarding role selection
  struct OnboardingPersonaGenerator {
    private let session: LanguageModelSession
    private let state: OnboardingState

    init(session: LanguageModelSession, state: OnboardingState) {
      self.session = session
      self.state = state
    }

    /// Generate diverse persona options for role selection
    func generate() async throws {
      await MainActor.run {
        state.isGeneratingPersonas = true
        state.errorMessage = nil
      }

      defer {
        Task { @MainActor in
          state.isGeneratingPersonas = false
        }
      }

      let prompt = """
        Generate 8-10 diverse user personas who would use an RSS reader app.

        Include a variety of:
        - Professional roles (e.g., Developer, Designer, Business Professional)
        - Creative roles (e.g., Writer, Content Creator, Podcaster)
        - Academic roles (e.g., Student, Researcher, Educator)
        - Hobbyist roles (e.g., Tech Enthusiast, News Junkie, Learner)

        For each persona:
        - Use a clear, concise title (1-3 words)
        - Choose an appropriate SF Symbol icon name
        - Provide a brief description (3-5 words describing their focus)

        Make personas specific and relatable. Cover different industries and interests.
        """

      do {
        let response = try await session.respond(
          to: Prompt(prompt),
          generating: PersonaSuggestions.self
        )

        // Convert AI suggestions to OnboardingRole objects
        var roles = response.content.personas.map { suggestion in
          OnboardingRole(
            title: suggestion.title,
            icon: suggestion.iconName,
            description: suggestion.description
          )
        }

        // Always add the "Other" option at the end
        roles.append(OnboardingRole.otherRole)

        await MainActor.run {
          state.availableRoles = roles
        }
      } catch let error as LanguageModelSession.GenerationError {
        await handleGenerationError(error)
        #if DEBUG
          print("⚠️ AI persona generation failed (GenerationError): \(error)")
        #endif
        await MainActor.run {
          state.availableRoles = OnboardingRole.fallbackRoles
        }
      } catch {
        await MainActor.run {
          state.errorMessage = "Failed to generate personas. Using default options."
          state.availableRoles = OnboardingRole.fallbackRoles
        }
        #if DEBUG
          print("⚠️ AI persona generation failed (unexpected error): \(error)")
        #endif
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
