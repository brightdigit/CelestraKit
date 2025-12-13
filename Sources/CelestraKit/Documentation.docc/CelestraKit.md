# ``CelestraKit``

Shared CloudKit models and utilities for the Celestra RSS reader ecosystem.

## Overview

CelestraKit is a Swift package that provides shared CloudKit data models for the Celestra RSS reader platform. It defines the public database schema used by both the iOS application and server-side feed processing tools, enabling seamless data synchronization and sharing across the Celestra ecosystem.

The package is designed for cross-platform compatibility, with CloudKit-specific code available on Apple platforms and platform-agnostic DTOs for Linux/server environments.

### Key Features

- **CloudKit Public Database Models**: Shared data structures for feeds and articles
- **Cross-Platform Compatibility**: Works on all Apple platforms with CloudKit support
- **Server-Side Metrics**: Track feed health, success rates, and fetch statistics
- **Content Deduplication**: SHA-256 hashing for intelligent article deduplication
- **TTL-Based Caching**: Automatic expiration tracking for article freshness
- **Quality Indicators**: Feed quality scoring and health monitoring
- **Reading Time Estimation**: Automatic word count and reading time calculation
- **Web Etiquette Services**: Rate limiting and robots.txt compliance
- **Modern Swift**: Built with Swift 6.2, strict concurrency, and modern language features

## Topics

### Getting Started

- <doc:GettingStarted>
- <doc:CloudKitIntegration>

### Data Models

- ``Feed``
- ``Article``

### Services

- ``RateLimiter``
- ``RobotsTxtService``
- ``RobotsTxtService/RobotsRules``

### Guides

- <doc:RateLimiting>
- <doc:WebEtiquette>

## Platform Support

CelestraKit requires:
- iOS 26.0+
- macOS 26.0+
- visionOS 26.0+
- watchOS 26.0+
- tvOS 26.0+
- macCatalyst 26.0+

## See Also

- [GitHub Repository](https://github.com/brightdigit/CelestraKit)
- [SyndiKit RSS Parser](https://github.com/brightdigit/SyndiKit)
