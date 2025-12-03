// UserPreferencesService.swift
// CelestraKit
//
// Created for Celestra on 2025-10-27.

import Foundation
public import Observation

/// Service for managing user preferences and app state
@Observable
@MainActor
public final class UserPreferencesService {
  /// Shared instance
  public static let shared = UserPreferencesService()

  /// App group identifier for sharing UserDefaults with extensions
  private static let appGroupIdentifier = "group.com.brightdigit.Celestra"

  private let defaults: UserDefaults = {
    guard let groupDefaults = UserDefaults(suiteName: UserPreferencesService.appGroupIdentifier) else {
      assertionFailure("Failed to initialize app group UserDefaults. Using standard as fallback.")
      return .standard
    }
    return groupDefaults
  }()

  /// Keys for UserDefaults
  private enum Keys {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let onboardingVersion = "onboardingVersion"
  }

  /// Current onboarding version - increment this when onboarding changes
  private let currentOnboardingVersion = 1

  /// Whether the user has completed onboarding
  public var hasCompletedOnboarding: Bool {
    get {
      let completed = defaults.bool(forKey: Keys.hasCompletedOnboarding)
      let version = defaults.integer(forKey: Keys.onboardingVersion)
      return completed && version >= currentOnboardingVersion
    }
    set {
      defaults.set(newValue, forKey: Keys.hasCompletedOnboarding)
      if newValue {
        defaults.set(currentOnboardingVersion, forKey: Keys.onboardingVersion)
      }
    }
  }

  private init() {}

  /// Mark onboarding as completed
  public func completeOnboarding() {
    hasCompletedOnboarding = true
  }

  /// Reset onboarding (for testing/debugging)
  public func resetOnboarding() {
    hasCompletedOnboarding = false
    defaults.removeObject(forKey: Keys.onboardingVersion)
  }
}
