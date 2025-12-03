// FeedSelectionStepView.swift
// CelestraKit
//
// Created for Celestra on 2025-10-27.

#if canImport(SwiftUI) && canImport(FoundationModels)
  import SwiftUI

  /// Final step showing AI-generated feed recommendations
  struct FeedSelectionStepView: View {
    @Environment(\.dismiss)
    private var dismiss

    @State private var subscribedFeeds: Set<String> = []
    @State private var preferences = UserPreferencesService.shared

    private let conversation = OnboardingConversation.shared
    private let recommendedMinimum = 12

    var body: some View {
      VStack(spacing: 16) {
        // Header with counter
        VStack(spacing: 8) {
          HStack(spacing: 12) {
            Text("Your Personalized Feeds")
              .font(.title)
              .fontWeight(.bold)

            // Feed counter badge
            if !subscribedFeeds.isEmpty {
              feedCounterBadge
            }
          }

          if conversation.state.isGeneratingRecommendations {
            Text("Finding the perfect feeds for you...")
              .font(.title3)
              .foregroundStyle(.secondary)
          } else {
            Text("We found \(conversation.state.feedRecommendations.count) feeds for you")
              .font(.title3)
              .foregroundStyle(.secondary)
          }
        }

        if conversation.state.isGeneratingRecommendations {
          // Loading state
          VStack(spacing: 16) {
            ProgressView()
              .controlSize(.large)

            Text("Analyzing your interests...")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .frame(maxHeight: .infinity)
        } else {
          // Adaptive feed list with pagination
          ViewportAwareChoiceLayout(
            items: conversation.state.feedRecommendations,
            itemHeight: OnboardingLayoutMetrics.feedRowHeight,
            spacing: OnboardingLayoutMetrics.feedRowSpacing
          ) { feed in
            FeedRecommendationCardView(
              feed: feed,
              isSubscribed: subscribedFeeds.contains(feed.id)
            ) {
              if subscribedFeeds.contains(feed.id) {
                subscribedFeeds.remove(feed.id)
              } else {
                subscribedFeeds.insert(feed.id)
              }
            }
          }

          // Guidance message if below recommended minimum
          if !subscribedFeeds.isEmpty && subscribedFeeds.count < recommendedMinimum {
            HStack(spacing: 8) {
              Image(systemName: "info.circle")
              Text("We recommend at least 12 feeds for the best experience")
                .font(.caption)
            }
            .foregroundStyle(.secondary)
            .padding(.top, 4)
          }

          // Action buttons
          VStack(spacing: 12) {
            Button(
              action: { subscribeToAll() },
              label: {
                Text("Subscribe to All \(conversation.state.feedRecommendations.count)")
                  .frame(maxWidth: .infinity)
              }
            )
            .buttonStyle(.borderedProminent)

            if !subscribedFeeds.isEmpty {
              Button(
                action: { finishOnboarding() },
                label: {
                  continueButtonLabel
                    .frame(maxWidth: .infinity)
                }
              )
              .buttonStyle(.bordered)
            }
          }
          .padding(.top, 8)
        }
      }
    }

    // MARK: - View Components

    private var feedCounterBadge: some View {
      let meetsRecommendation = subscribedFeeds.count >= recommendedMinimum
      let badgeColor: Color = meetsRecommendation ? .green : .orange

      return HStack(spacing: 4) {
        Text("\(subscribedFeeds.count)")
          .fontWeight(.bold)
        Text("/")
        Text("\(recommendedMinimum)")
      }
      .font(.caption)
      .foregroundStyle(.white)
      .padding(.horizontal, 10)
      .padding(.vertical, 5)
      .background {
        Capsule()
          .fill(badgeColor)
      }
    }

    @ViewBuilder private var continueButtonLabel: some View {
      if subscribedFeeds.count >= recommendedMinimum {
        HStack(spacing: 6) {
          Image(systemName: "checkmark.circle.fill")
          Text("Continue with \(subscribedFeeds.count) Feeds")
        }
      } else {
        Text("Continue with \(subscribedFeeds.count) Feeds (12+ recommended)")
      }
    }

    private func subscribeToAll() {
      subscribedFeeds = Set(conversation.state.feedRecommendations.map(\.id))
    }

    private func finishOnboarding() {
      // TODO: Actually subscribe to the selected feeds
      // This would integrate with FeedManager to add the feeds

      // Mark onboarding as completed
      preferences.completeOnboarding()

      // End the conversation session
      conversation.endSession()

      // Dismiss the onboarding view
      dismiss()
    }
  }

  /// Card showing a single feed recommendation
  struct FeedRecommendationCardView: View {
    let feed: FeedRecommendation
    let isSubscribed: Bool
    let action: () -> Void

    var body: some View {
      Button(action: action) {
        VStack(alignment: .leading, spacing: 12) {
          // Header with category and score
          HStack {
            Text(feed.category)
              .font(.caption)
              .fontWeight(.medium)
              .foregroundStyle(.blue)
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background {
                Capsule()
                  .fill(.blue.opacity(0.1))
              }

            Spacer()

            // Relevance indicator
            HStack(spacing: 4) {
              ForEach(0..<5) { index in
                Image(systemName: index < Int(feed.relevanceScore * 5) ? "star.fill" : "star")
                  .font(.caption2)
                  .foregroundStyle(.yellow)
              }
            }
          }

          // Feed title
          Text(feed.title)
            .font(.headline)
            .foregroundStyle(.primary)
            .multilineTextAlignment(.leading)

          // Reason
          Text(feed.reason)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)

          // Subscribe button
          HStack {
            Spacer()
            Image(systemName: isSubscribed ? "checkmark.circle.fill" : "plus.circle")
              .font(.title3)
              .foregroundStyle(isSubscribed ? .green : .blue)
          }
        }
        .padding()
        .background {
          RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
        }
        .overlay {
          RoundedRectangle(cornerRadius: 16)
            .strokeBorder(
              isSubscribed ? Color.green.opacity(0.3) : Color.clear,
              lineWidth: 2
            )
        }
      }
      .buttonStyle(.plain)
    }
  }

  #Preview {
    FeedSelectionStepView()
      .padding()
  }
#endif
