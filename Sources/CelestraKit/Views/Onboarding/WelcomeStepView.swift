// WelcomeStepView.swift
// CelestraKit
//
// Created for Celestra on 2025-10-27.

#if canImport(SwiftUI)
  import SwiftUI

  /// Welcome step of onboarding
  struct WelcomeStepView: View {
    var body: some View {
      VStack(spacing: 24) {
        // Hero icon
        Image(systemName: "sparkles")
          .font(.system(size: 80))
          .foregroundStyle(
            .linearGradient(
              colors: [.blue, .purple],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .padding(.top, 40)

        VStack(spacing: 12) {
          Text("Welcome to Celestra")
            .font(.largeTitle)
            .fontWeight(.bold)

          Text("Your personal RSS reader with AI-powered feed discovery")
            .font(.title3)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }

        // Feature highlights
        VStack(alignment: .leading, spacing: 16) {
          FeatureRowView(
            icon: "brain",
            title: "AI-Powered Discovery",
            description: "Find feeds tailored to your interests"
          )

          FeatureRowView(
            icon: "eye",
            title: "Beautiful Design",
            description: "Liquid Glass interface built for iOS 26"
          )

          FeatureRowView(
            icon: "lock.shield",
            title: "Privacy First",
            description: "All processing happens on your device"
          )
        }
        .padding(.top)
      }
      .frame(maxWidth: .infinity)
    }
  }

  struct FeatureRowView: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
      HStack(alignment: .top, spacing: 16) {
        Image(systemName: icon)
          .font(.title2)
          .foregroundStyle(.blue)
          .frame(width: 32)

        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(.headline)
          Text(description)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  #Preview {
    WelcomeStepView()
      .padding()
  }
#endif
