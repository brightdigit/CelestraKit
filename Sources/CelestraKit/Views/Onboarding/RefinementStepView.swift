// RefinementStepView.swift
// CelestraKit
//
// Created for Celestra on 2025-10-27.

#if canImport(SwiftUI) && canImport(FoundationModels)
  import SwiftUI

  /// Refinement step with AI-generated subtopic tags
  struct RefinementStepView: View {
    private let conversation = OnboardingConversation.shared

    var body: some View {
      VStack(spacing: 16) {
        // Header
        VStack(spacing: 8) {
          Text(conversation.state.currentStep.title)
            .font(.title)
            .fontWeight(.bold)

          Text(conversation.state.currentStep.question)
            .font(.title3)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

          // Show what they selected before
          if !conversation.state.selectedTopics.isEmpty {
            let topics = Array(conversation.state.selectedTopics).prefix(3)
            Text("Based on: \(topics.joined(separator: ", "))")
              .font(.subheadline)
              .foregroundStyle(.tertiary)
              .padding(.top, 4)
          }
        }

        if conversation.state.isGeneratingTags {
          // Loading state
          VStack(spacing: 16) {
            ProgressView()
              .controlSize(.large)

            Text("Refining your interests...")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .frame(maxHeight: .infinity)
        } else {
          // Adaptive refined topic list with pagination
          ViewportAwareChoiceLayout(
            items: conversation.state.suggestedTags.map { RefinedTopicItem(tag: $0) },
            itemHeight: OnboardingLayoutMetrics.topicTagHeight,
            spacing: OnboardingLayoutMetrics.topicTagSpacing,
            onRequestMore: {
              // Request more AI-generated refined topics
              Task {
                do {
                  try await conversation.generateRefinedTags(
                    for: conversation.state.selectedTopics
                  )
                } catch {
                  conversation.state.errorMessage = error.localizedDescription
                }
              }
            },
            content: { item in
              TagButtonView(
                text: item.tag,
                isSelected: conversation.state.refinedTopics.contains(item.tag)
              ) {
                if conversation.state.refinedTopics.contains(item.tag) {
                  conversation.state.refinedTopics.remove(item.tag)
                } else {
                  conversation.state.refinedTopics.insert(item.tag)
                }
              }
            }
          )

          // AI indicator
          HStack(spacing: 8) {
            Image(systemName: "sparkles")
              .font(.caption)
            Text("More specific topics based on your selections")
              .font(.caption)
          }
          .foregroundStyle(.secondary)
          .padding(.top, 8)
        }
      }
    }
  }

  /// Wrapper to make strings Identifiable for ViewportAwareChoiceLayout
  private struct RefinedTopicItem: Identifiable {
    let id = UUID()
    let tag: String
  }

  #Preview {
    RefinementStepView()
      .padding()
  }
#endif
