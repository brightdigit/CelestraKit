// TopicSelectionStepView.swift
// CelestraKit
//
// Created for Celestra on 2025-10-27.

#if canImport(SwiftUI) && canImport(FoundationModels)
  import SwiftUI

  /// Topic selection step with AI-generated tag cloud
  struct TopicSelectionStepView: View {
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

          Text("Select as many as you like")
            .font(.subheadline)
            .foregroundStyle(.tertiary)
        }

        if conversation.state.isGeneratingTags {
          // Loading state
          VStack(spacing: 16) {
            ProgressView()
              .controlSize(.large)

            Text("Generating personalized topics...")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .frame(maxHeight: .infinity)
        } else {
          // Adaptive topic list with pagination
          ViewportAwareChoiceLayout(
            items: conversation.state.suggestedTags.map { TopicItem(tag: $0) },
            itemHeight: OnboardingLayoutMetrics.topicTagHeight,
            spacing: OnboardingLayoutMetrics.topicTagSpacing,
            onRequestMore: {
              // Request more AI-generated topics
              Task {
                do {
                  if let role = conversation.state.selectedRole {
                    try await conversation.generateTopicTags(for: role)
                  }
                } catch {
                  conversation.state.errorMessage = error.localizedDescription
                }
              }
            },
            content: { item in
              TagButtonView(
                text: item.tag,
                isSelected: conversation.state.selectedTopics.contains(item.tag)
              ) {
                if conversation.state.selectedTopics.contains(item.tag) {
                  conversation.state.selectedTopics.remove(item.tag)
                } else {
                  conversation.state.selectedTopics.insert(item.tag)
                }
              }
            }
          )

          // AI indicator
          HStack(spacing: 8) {
            Image(systemName: "sparkles")
              .font(.caption)
            Text("AI-generated based on your role")
              .font(.caption)
          }
          .foregroundStyle(.secondary)
          .padding(.top, 8)
        }
      }
    }
  }

  /// Wrapper to make strings Identifiable for ViewportAwareChoiceLayout
  private struct TopicItem: Identifiable {
    let id = UUID()
    let tag: String
  }

  /// Full-width tag button with selection state
  struct TagButtonView: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
      Button(action: action) {
        HStack {
          Text(text)
            .font(.subheadline)
            .fontWeight(.medium)

          Spacer()

          if isSelected {
            Image(systemName: "checkmark.circle.fill")
              .font(.title3)
          } else {
            Image(systemName: "circle")
              .font(.title3)
              .foregroundStyle(.tertiary)
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
          RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
        }
        .overlay {
          RoundedRectangle(cornerRadius: 12)
            .strokeBorder(
              isSelected ? Color.blue : Color.clear,
              lineWidth: 2
            )
        }
        .foregroundStyle(isSelected ? .blue : .primary)
      }
      .buttonStyle(.plain)
    }
  }

  #Preview {
    TopicSelectionStepView()
      .padding()
  }
#endif
