// OnboardingView.swift
// CelestraKit
//
// Created for Celestra on 2025-10-27.

#if canImport(SwiftUI) && canImport(FoundationModels)
  public import SwiftUI

  /// Main onboarding flow view
  public struct OnboardingView: View {
    @State private var showError = false

    @Environment(\.dismiss)
    private var dismiss

    private let conversation = OnboardingConversation.shared

    public init() {}

    public var body: some View {
      NavigationStack {
        GeometryReader { _ in
          ZStack {
            // Background gradient with Liquid Glass aesthetic
            LinearGradient(
              colors: [
                Color(white: 0.98),
                Color(white: 0.95),
                Color(white: 0.92),
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Fixed layout structure (no scrolling)
            VStack(spacing: 0) {
              // Progress indicator (fixed height)
              progressIndicator
                .frame(height: OnboardingLayoutMetrics.progressIndicatorHeight)
                .padding(.horizontal, OnboardingLayoutMetrics.contentPadding)

              // Step content (flexible, fills available space)
              stepContent
                .frame(maxHeight: .infinity)
                .padding(.horizontal, OnboardingLayoutMetrics.contentPadding)

              // Navigation buttons (fixed height)
              navigationButtons
                .frame(height: OnboardingLayoutMetrics.navigationButtonsHeight)
                .padding(.horizontal, OnboardingLayoutMetrics.contentPadding)
            }
          }
        }
        #if os(iOS)
          .navigationBarTitleDisplayMode(.inline)
        #endif
        .alert(
          "Error",
          isPresented: $showError,
          actions: {
            Button("OK") {
              conversation.state.errorMessage = nil
            }
          },
          message: {
            if let error = conversation.state.errorMessage {
              Text(error)
            }
          }
        )
      }
      .task {
        do {
          try conversation.startSession()
          // Generate personas after session starts
          try await conversation.generatePersonas()
        } catch {
          conversation.state.errorMessage = error.localizedDescription
          showError = true
        }
      }
    }

    // MARK: - View Components

    private var progressIndicator: some View {
      Group {
        if let stepLabel = conversation.state.currentStep.stepLabel {
          VStack(spacing: 4) {
            Text(stepLabel)
              .font(.caption)
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, alignment: .leading)

            // Optional: Add progress dots or bar here
          }
        } else {
          Spacer()
        }
      }
    }

    @ViewBuilder private var stepContent: some View {
      switch conversation.state.currentStep {
      case .welcome:
        WelcomeStepView()
      case .roleSelection:
        RoleSelectionStepView()
      case .topicSelection:
        TopicSelectionStepView()
      case .refinement:
        RefinementStepView()
      case .feedSelection:
        FeedSelectionStepView()
      }
    }

    private var navigationButtons: some View {
      HStack(spacing: 16) {
        if conversation.state.currentStep != .welcome {
          Button(
            action: { conversation.state.goBack() },
            label: {
              Label("Back", systemImage: "chevron.left")
                .frame(maxWidth: .infinity)
            }
          )
          .buttonStyle(.bordered)
        }

        if conversation.state.currentStep != .feedSelection {
          Button(
            action: { handleNext() },
            label: {
              Text(conversation.state.currentStep == .welcome ? "Get Started" : "Continue")
                .frame(maxWidth: .infinity)
            }
          )
          .buttonStyle(.borderedProminent)
          .disabled(!conversation.state.canProceed)
        }
      }
    }

    private func handleNext() {
      Task {
        do {
          // Generate tags for the next step if needed
          switch conversation.state.currentStep {
          case .roleSelection:
            if let role = conversation.state.selectedRole {
              try await conversation.generateTopicTags(for: role)
            }
          case .topicSelection:
            try await conversation.generateRefinedTags(for: conversation.state.selectedTopics)
          case .refinement:
            try await conversation.generateFeedRecommendations()
          default:
            break
          }

          conversation.state.advance()
        } catch {
          conversation.state.errorMessage = error.localizedDescription
          showError = true
        }
      }
    }
  }

  #Preview {
    OnboardingView()
  }
#endif
