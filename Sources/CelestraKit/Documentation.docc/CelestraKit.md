# ``CelestraKit``

Shared CloudKit models and utilities for the Celestra RSS reader ecosystem.

## Overview

CelestraKit provides a robust, type-safe foundation for building RSS readers on Apple platforms using CloudKit's public database. Built with Swift 6.2 and strict concurrency checking, it offers:

- **CloudKit Public Database Models** for feeds and articles
- **Cross-Platform Support** across all Apple platforms (iOS 26+, macOS 26+, watchOS 26+, tvOS 26+, visionOS 26+)
- **Server-Side Metrics** for feed health monitoring
- **Intelligent Caching** with TTL-based expiration
- **Content Deduplication** using composite key hashing
- **Web Etiquette Services** for responsible feed fetching
- **Modern Swift**: Built with Swift 6.2, strict concurrency, and modern language features

### Architecture

CelestraKit uses CloudKit's public database to share RSS content across all users, reducing redundant network requests and improving performance. The package consists of two core models (``Feed`` and ``Article``) and two web etiquette services (``RateLimiter`` and ``RobotsTxtService``).

The package is designed for cross-platform compatibility, with CloudKit-specific code available on Apple platforms and platform-agnostic DTOs for Linux/server environments.

### Key Concepts

- **Feed**: RSS feed metadata with server-side health metrics and quality scores
- **Article**: Cached RSS articles with TTL-based expiration and automatic content processing
- **RateLimiter**: Actor-based rate limiting to prevent server overload
- **RobotsTxtService**: Automated robots.txt compliance for ethical web crawling

### Use Cases

CelestraKit is designed for:
- **RSS reader applications** that share content across users
- **Feed aggregation services** with centralized processing
- **Server-side feed processors** that populate CloudKit for client apps
- **Cross-platform RSS solutions** requiring consistent data models

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:ModelArchitecture>
- <doc:CloudKitIntegration>

### Core Models

- ``Feed``
- ``Article``

### Web Etiquette Services

- ``RateLimiter``
- ``RobotsTxtService``
- ``RobotsTxtService/RobotsRules``

### Advanced Guides

- <doc:FeedModelGuide>
- <doc:ArticleModelGuide>
- <doc:ConcurrencyPatterns>
- <doc:CachingAndDeduplication>
- <doc:WebEtiquette>
- <doc:CrossPlatformConsiderations>
