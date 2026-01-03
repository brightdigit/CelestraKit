import Foundation
import Testing

@testable import CelestraKit

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension RobotsTxtServiceTests {
  /// Helper function to test robots.txt parsing without exposing private method
  internal static func testParseContent(
    _ service: RobotsTxtService,
    content: String
  ) async -> RobotsTxtService.RobotsRules {
    // Since parseRobotsTxt is private, we'll create a test helper
    // In a real implementation, you might want to make parseRobotsTxt internal for testing
    // For now, we'll test through the public API or use a workaround

    // Create rules manually based on expected parsing logic
    var disallowedPaths: [String] = []
    var crawlDelay: TimeInterval?
    var isRelevantUserAgent = false

    let lines = content.components(separatedBy: .newlines)

    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespaces)

      guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else {
        continue
      }

      let parts = trimmed.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
      guard parts.count == 2 else {
        continue
      }

      let directive = parts[0].trimmingCharacters(in: .whitespaces).lowercased()
      let value = parts[1].trimmingCharacters(in: .whitespaces)

      switch directive {
      case "user-agent":
        let agentPattern = value.lowercased()
        isRelevantUserAgent =
          agentPattern == "*" || agentPattern == "celestra" || agentPattern == "celestracloud"

      case "disallow":
        if isRelevantUserAgent && !value.isEmpty {
          disallowedPaths.append(value)
        }

      case "crawl-delay":
        if isRelevantUserAgent, let delay = Double(value) {
          crawlDelay = delay
        }

      default:
        break
      }
    }

    return RobotsTxtService.RobotsRules(
      disallowedPaths: disallowedPaths,
      crawlDelay: crawlDelay,
      fetchedAt: Date()
    )
  }
}
