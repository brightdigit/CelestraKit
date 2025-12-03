// TagSuggestions.swift
// CelestraKit
//
// Created for Celestra on 2025-10-27.

#if canImport(FoundationModels)
  public import FoundationModels
  public import Foundation

  /// AI-generated persona/role suggestions for onboarding
  @Generable
  public struct PersonaSuggestions: Sendable {
    /// List of suggested personas
    @Guide(description: "8-10 diverse user personas/roles", .count(8...10))
    public let personas: [PersonaSuggestion]

    public init(personas: [PersonaSuggestion]) {
      self.personas = personas
    }
  }

  /// Individual persona suggestion from AI
  @Generable
  public struct PersonaSuggestion: Sendable {
    /// Persona title (e.g., "Developer", "Content Creator")
    @Guide(description: "Short persona title, 1-3 words")
    public let title: String

    /// SF Symbol icon name (without "sf-symbol-" prefix)
    @Guide(description: "Relevant SF Symbol icon name like 'person.crop.circle' or 'briefcase'")
    public let iconName: String

    /// Short description of the persona
    @Guide(description: "Brief description in 3-5 words")
    public let description: String

    public init(title: String, iconName: String, description: String) {
      self.title = title
      self.iconName = iconName
      self.description = description
    }
  }

  /// AI-generated tag suggestions for onboarding
  @Generable
  public struct TagSuggestions: Sendable {
    /// List of suggested topic tags
    @Guide(description: "8-12 relevant topic tags for the user's interests", .count(8...12))
    public let tags: [String]

    /// Brief explanation of why these tags were suggested
    @Guide(description: "One sentence explaining the tag selection reasoning")
    public let reasoning: String

    public init(tags: [String], reasoning: String) {
      self.tags = tags
      self.reasoning = reasoning
    }
  }

  /// Feed recommendation with relevance scoring
  @Generable
  public struct FeedRecommendation: Sendable, Identifiable {
    /// Unique identifier
    public let id: String

    /// Feed title
    @Guide(description: "The feed's title")
    public let title: String

    /// Feed URL
    @Guide(description: "The RSS/Atom feed URL")
    public let feedURL: String

    /// Why this feed matches the user's interests
    @Guide(description: "One sentence explaining why this feed is recommended")
    public let reason: String

    /// Relevance score (0.0 to 1.0)
    @Guide(description: "Relevance score from 0.0 to 1.0", .range(0.0...1.0))
    public let relevanceScore: Double

    /// Feed category
    @Guide(description: "Primary category like Technology, Design, Business")
    public let category: String

    public init(
      id: String,
      title: String,
      feedURL: String,
      reason: String,
      relevanceScore: Double,
      category: String
    ) {
      self.id = id
      self.title = title
      self.feedURL = feedURL
      self.reason = reason
      self.relevanceScore = relevanceScore
      self.category = category
    }
  }
#endif
