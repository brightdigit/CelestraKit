// RoleSelectionStepView.swift
// CelestraKit
//
// Created for Celestra on 2025-10-27.

#if canImport(SwiftUI) && canImport(FoundationModels)
  import SwiftUI

  /// Role selection step of onboarding
  struct RoleSelectionStepView: View {
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
        }

        // Show loading state or role list
        if conversation.state.isGeneratingPersonas {
          VStack(spacing: 16) {
            ProgressView()
              .controlSize(.large)
            Text("Generating personalized options...")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .frame(maxHeight: .infinity)
        } else if conversation.state.availableRoles.isEmpty {
          Text("No personas available. Please restart onboarding.")
            .foregroundStyle(.secondary)
            .frame(maxHeight: .infinity)
        } else {
          // Role selection with adaptive layout
          ViewportAwareChoiceLayout(
            items: conversation.state.availableRoles,
            itemHeight: OnboardingLayoutMetrics.personaCardHeight,
            spacing: OnboardingLayoutMetrics.personaCardSpacing
          ) { role in
            RoleCardView(
              role: role,
              isSelected: conversation.state.selectedRole == role
            ) {
              conversation.state.selectedRole = role
            }
          }

          // Custom input field if "Other" is selected
          if let selectedRole = conversation.state.selectedRole, selectedRole.isOther {
            VStack(alignment: .leading, spacing: 8) {
              Text("Tell us about yourself")
                .font(.caption)
                .foregroundStyle(.secondary)

              TextField(
                "Describe your role or interests...",
                text: Binding(
                  get: { conversation.state.customPersonaDescription ?? "" },
                  set: { conversation.state.customPersonaDescription = $0 }
                ), axis: .vertical
              )
              .textFieldStyle(.roundedBorder)
              .lineLimit(3...5)
            }
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(response: 0.3), value: selectedRole.isOther)
          }
        }
      }
    }
  }

  struct RoleCardView: View {
    let role: OnboardingRole
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
      Button(action: action) {
        VStack(spacing: 12) {
          Image(systemName: role.icon)
            .font(.system(size: 40))
            .foregroundStyle(isSelected ? .blue : .primary)

          VStack(spacing: 4) {
            Text(role.title)
              .font(.headline)
              .foregroundStyle(.primary)

            Text(role.description)
              .font(.caption)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
              .lineLimit(2)
          }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background {
          RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
        }
        .overlay {
          RoundedRectangle(cornerRadius: 16)
            .strokeBorder(
              isSelected ? Color.blue : Color.clear,
              lineWidth: 2
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
      }
      .buttonStyle(.plain)
      .pressAction {
        isPressed = true
      } onRelease: {
        isPressed = false
      }
    }
  }

  // Helper for press actions
  extension View {
    func pressAction(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
      self.simultaneousGesture(
        DragGesture(minimumDistance: 0)
          .onChanged { _ in onPress() }
          .onEnded { _ in onRelease() }
      )
    }
  }

  #Preview {
    RoleSelectionStepView()
      .padding()
  }
#endif
