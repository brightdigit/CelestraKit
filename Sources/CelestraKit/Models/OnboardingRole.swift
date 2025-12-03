// OnboardingRole.swift
// CelestraKit
//
// Created for Celestra on 2025-10-27.

import Foundation

/// User role/persona for onboarding personalization
/// Can be AI-generated or manually created
public struct OnboardingRole: Identifiable, Hashable, Sendable, Codable {
  /// Unique identifier
  public let id: String

  /// Display name of the role (e.g., "Developer", "Designer")
  public let title: String

  /// SF Symbol icon name for the role
  public let icon: String

  /// Short description of the role
  public let description: String

  /// Whether this is the "Other" option that allows custom input
  public let isOther: Bool

  public init(
    id: String = UUID().uuidString,
    title: String,
    icon: String,
    description: String,
    isOther: Bool = false
  ) {
    self.id = id
    self.title = title
    self.icon = icon
    self.description = description
    self.isOther = isOther
  }
}

// MARK: - Fallback Roles

extension OnboardingRole {
  /// Fallback hardcoded roles used if AI generation fails
  public static var fallbackRoles: [OnboardingRole] {
    [
      OnboardingRole(
        title: "Developer",
        icon: "chevron.left.forwardslash.chevron.right",
        description: "Building apps and software"
      ),
      OnboardingRole(
        title: "Designer",
        icon: "paintbrush.pointed",
        description: "Crafting beautiful experiences"
      ),
      OnboardingRole(
        title: "Business Professional",
        icon: "briefcase",
        description: "Strategy and leadership"
      ),
      OnboardingRole(
        title: "Student",
        icon: "graduationcap",
        description: "Learning and exploring"
      ),
      OnboardingRole(
        title: "Creative Professional",
        icon: "sparkles",
        description: "Creating and innovating"
      ),
      OnboardingRole(
        title: "Researcher",
        icon: "book.closed",
        description: "Discovering and analyzing"
      ),
      OnboardingRole(
        title: "Other",
        icon: "ellipsis.circle",
        description: "Tell us about yourself",
        isOther: true
      ),
    ]
  }

  /// The "Other" option for custom persona input
  public static var otherRole: OnboardingRole {
    OnboardingRole(
      title: "Other",
      icon: "ellipsis.circle",
      description: "Tell us about yourself",
      isOther: true
    )
  }
}
