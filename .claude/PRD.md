# CelestraKit v0.0.1 - Product Requirements Document

**Status**: Planning
**Last Updated**: 2025-12-10
**Version**: 0.0.1

## Executive Summary

CelestraKit is a shared Swift package providing CloudKit models and utilities for the Celestra RSS reader ecosystem. Currently, the package has minimal infrastructure with only basic models (Feed, Article) and 2 simple tests. This PRD outlines the requirements for v0.0.1 - a production-ready release with comprehensive testing, CI/CD automation, quality tooling, and complete documentation.

**Success Criteria**: Passing tests across all platforms, automated CI/CD pipeline, 90%+ code coverage, published documentation, and production-ready dependency management.

---

## 1. Dependencies

### 1.1 Switch SyndiKit to Official Release
**Priority**: CRITICAL

**Current State**: Using local path dependency `../Syndikit`
**Target State**: Official GitHub release v0.6.1

**Tasks**:
- Update `Package.swift` line 65: change `.package(path: "../Syndikit")` to `.package(url: "https://github.com/brightdigit/SyndiKit.git", from: "0.6.1")`
- Run `swift build` to verify
- Commit updated `Package.resolved`

**Acceptance Criteria**:
- [ ] Package.swift points to GitHub URL with version 0.6.1
- [ ] `swift build` succeeds
- [ ] All existing tests pass

**Files**: `Package.swift`

---

## 2. Testing Infrastructure

### 2.1 Feed Model Tests
**Priority**: HIGH

Create comprehensive test suite for Feed model in new file `Tests/CelestraKitTests/Models/PublicDatabase/FeedTests.swift`

**Test Coverage**:
- Initialization with all parameters and defaults
- Computed properties: `id`, `successRate`, `isHealthy`
- Edge cases: zero attempts, 100% success/failure
- Codable, Hashable, Equatable conformances
- CloudKit fields (recordName, recordChangeTag)

**Acceptance Criteria**:
- [ ] 20+ test cases
- [ ] 90%+ coverage for Feed.swift
- [ ] All tests pass in CI

**Files**: `Tests/CelestraKitTests/Models/PublicDatabase/FeedTests.swift` (new)

### 2.2 Article Model Tests
**Priority**: HIGH

Create comprehensive test suite for Article model in new file `Tests/CelestraKitTests/Models/PublicDatabase/ArticleTests.swift`

**Test Coverage**:
- Initialization and TTL calculation
- Content hash generation (SHA-256)
- HTML to plain text extraction
- Word count and reading time calculation
- Expiration logic (`isExpired`)
- Duplicate detection
- Codable conformance
- Edge cases: empty content, special characters, very long content

**Acceptance Criteria**:
- [ ] 25+ test cases
- [ ] 90%+ coverage for Article.swift
- [ ] HTML entity handling validated
- [ ] All tests pass in CI

**Files**: `Tests/CelestraKitTests/Models/PublicDatabase/ArticleTests.swift` (new)

### 2.3 Package Integration Tests
**Priority**: MEDIUM

Expand existing `Tests/CelestraKitTests/CelestraKitTests.swift` with integration tests

**Test Coverage**:
- Version information accuracy
- Module exports (Feed, Article accessible)
- Public API surface validation

**Acceptance Criteria**:
- [ ] 5+ integration test cases
- [ ] All public types accessible

**Files**: `Tests/CelestraKitTests/CelestraKitTests.swift` (modify)

---

## 3. CI/CD Pipeline

### 3.1 Main Build Workflow
**Priority**: CRITICAL

Migrate MistKit's multi-platform build workflow to `.github/workflows/CelestraKit.yml`

**Platform Coverage**:
- **Ubuntu**: Swift 6.1, 6.2, 6.2-nightly on noble/jammy
- **Windows**: Windows 2022/2025 with Swift 6.1/6.2
- **macOS**: Xcode 16.3, 16.4, 26.0
- **iOS**: 18.4, 18.5, 26.0.1
- **watchOS, tvOS, visionOS**: 26.0

**Features**:
- Code coverage with Codecov integration
- Matrix testing across platforms
- Linting stage after builds

**Acceptance Criteria**:
- [ ] Workflow runs on all platforms
- [ ] Coverage uploaded to Codecov
- [ ] Completes in <30 minutes

**Files**: `.github/workflows/CelestraKit.yml` (new)
**Source**: `../MistKit/.github/workflows/MistKit.yml`

### 3.2 CodeQL Security Scanning
**Priority**: MEDIUM

Add GitHub CodeQL workflow for security analysis

**Files**: `.github/workflows/codeql.yml` (new)
**Source**: `../MistKit/.github/workflows/codeql.yml`

**Acceptance Criteria**:
- [ ] CodeQL runs successfully
- [ ] No critical security issues

### 3.3 Claude Code Integration
**Priority**: LOW

Add Claude Code workflows for AI-assisted development

**Files**:
- `.github/workflows/claude.yml` (new)
- `.github/workflows/claude-code-review.yml` (new)

**Source**: MistKit equivalent files

---

## 4. Code Quality Tools

### 4.1 SwiftLint Configuration
**Priority**: HIGH

Migrate comprehensive SwiftLint config from MistKit (134 lines, 90+ rules)

**Key Rules**:
- Cyclomatic complexity: 6 warning / 12 error
- Line length: 108 warning / 200 error
- File length: 225 warning / 300 error
- Analyzer rules: unused_import, unused_declaration

**Acceptance Criteria**:
- [ ] SwiftLint runs without errors in strict mode
- [ ] All source files pass linting

**Files**: `.swiftlint.yml` (new)
**Source**: `../MistKit/.swiftlint.yml`

### 4.2 swift-format Configuration
**Priority**: HIGH

Migrate swift-format config (70 lines, 65+ formatting rules)

**Key Settings**:
- 2-space indentation
- 100-character line length
- Documentation required for public APIs

**Acceptance Criteria**:
- [ ] swift-format runs without errors
- [ ] Public APIs documented

**Files**: `.swift-format` (new)
**Source**: `../MistKit/.swift-format`

### 4.3 Periphery Configuration
**Priority**: MEDIUM

Configure Periphery for dead code detection

**Files**: `.periphery.yml` (new)
**Source**: `../MistKit/.periphery.yml`

### 4.4 Codecov Configuration
**Priority**: MEDIUM

Configure code coverage reporting

**Files**: `codecov.yml` (new)
**Source**: `../MistKit/codecov.yml`

---

## 5. Build Automation

### 5.1 Lint Script
**Priority**: HIGH

Migrate comprehensive linting orchestration script (94 lines)

**Features**:
- Multi-mode: NONE, NORMAL, STRICT, INSTALL
- Cross-platform: macOS, Linux, CI
- Runs: SwiftLint, swift-format, Periphery
- Header validation
- Compilation checks

**Customizations**:
- Update package name: MistKit → CelestraKit
- Update copyright holder
- Remove OpenAPI-specific sections

**Acceptance Criteria**:
- [ ] Script runs on macOS and Linux
- [ ] All modes functional
- [ ] CI integration works

**Files**: `Scripts/lint.sh` (new)
**Source**: `../MistKit/Scripts/lint.sh`

### 5.2 Header Script
**Priority**: MEDIUM

Migrate MIT license header injection script (104 lines)

**Customizations**:
- Update creator name
- Update copyright holder
- Package name: CelestraKit

**Files**: `Scripts/header.sh` (new)
**Source**: `../MistKit/Scripts/header.sh`

### 5.3 Makefile
**Priority**: MEDIUM

Create Makefile for common development tasks

**Targets**:
- `help`, `build`, `test`, `lint`, `format`, `clean`, `docs`

**Files**: `Makefile` (new)
**Source**: Adapted from `../MistKit/Makefile`

### 5.4 Mintfile
**Priority**: HIGH

Define development tool dependencies

**Tools**:
- swiftlang/swift-format@602.0.0
- realm/SwiftLint@0.62.2
- peripheryapp/periphery@3.2.0

**Files**: `Mintfile` (new)
**Source**: `../MistKit/Mintfile` (excluding openapi-generator)

### 5.5 XcodeGen Project (Optional)
**Priority**: LOW

Add XcodeGen configuration for Xcode project generation

**Files**: `project.yml` (new)
**Source**: `../MistKit/project.yml`

---

## 6. Documentation

### 6.1 README with Badges
**Priority**: HIGH

Create comprehensive README with status badges

**Sections**:
- Project overview and purpose
- Installation instructions
- Quick start examples
- Platform support matrix
- Documentation links
- Contributing guidelines

**Badges**:
- Swift Package Manager
- Swift versions (6.1+, 6.2+)
- Platforms (iOS 26.0+, macOS 26.0+, etc.)
- GitHub Actions status
- Code coverage (Codecov)
- License
- Documentation

**Acceptance Criteria**:
- [ ] README clear and comprehensive
- [ ] All badges link correctly
- [ ] Examples tested and accurate

**Files**: `README.md` (new)
**Source**: Adapted from `../MistKit/README.md`

### 6.2 DocC Documentation Catalog
**Priority**: HIGH

Create DocC documentation catalog

**Structure**:
- Getting Started guide
- Model architecture overview
- Feed model guide
- Article model guide
- CloudKit integration guide
- Cross-platform considerations

**Acceptance Criteria**:
- [ ] DocC builds without errors
- [ ] All public APIs documented
- [ ] Examples compile

**Files**:
- `Sources/CelestraKit/Documentation.docc/CelestraKit.md` (new)
- `Sources/CelestraKit/Documentation.docc/Resources/` (new directory)

### 6.3 Swift Package Index Configuration
**Priority**: MEDIUM

Configure SPI for documentation hosting

**Files**: `.spi.yml` (new)
**Source**: `../MistKit/.spi.yml`

**Acceptance Criteria**:
- [ ] SPI builds documentation
- [ ] Documentation visible online

### 6.4 LICENSE File
**Priority**: HIGH

Add MIT license file

**Files**: `LICENSE` (new)

### 6.5 Contributing Guidelines
**Priority**: MEDIUM

Document contribution process

**Sections**:
- Development setup
- Running tests
- Code style requirements
- PR process

**Files**: `CONTRIBUTING.md` (new)

---

## 7. Development Environment (Optional)

### 7.1 DevContainer Configuration
**Priority**: LOW

Add VSCode DevContainer setup

**Variants**:
- Swift 6.1
- Swift 6.2
- Swift 6.2 nightly

**Files**: `.devcontainer/devcontainer.json` (new)
**Source**: `../MistKit/.devcontainer/`

### 7.2 MCP Configuration
**Priority**: LOW

Add Model Context Protocol configuration

**Files**: `.mcp.json` (new)
**Source**: `../MistKit/.mcp.json`

---

## 8. File Organization

### 8.1 .gitignore Enhancement
**Priority**: LOW

Ensure comprehensive .gitignore

**Patterns**:
- .build/, .swiftpm/, DerivedData/
- .DS_Store, xcuserdata/
- .mint/, IDE files

**Files**: `.gitignore` (modify)

### 8.2 Scripts Directory
**Priority**: HIGH

Create Scripts directory with proper permissions

**Files**: `Scripts/` (new directory)

---

## Implementation Phases

### Phase 1: Foundation (4 hours)
1. Switch to SyndiKit v0.6.1
2. Add SwiftLint, swift-format, Periphery, Codecov configs
3. Create Mintfile
4. Create Scripts directory

### Phase 2: Testing (6 hours)
5. Feed model tests (20+ cases)
6. Article model tests (25+ cases)
7. Integration tests

### Phase 3: Automation (4 hours)
8. Header script
9. Lint script
10. Makefile
11. CodeQL + Claude workflows

### Phase 4: CI/CD (2 hours)
12. Main build workflow
13. Verify all platforms

### Phase 5: Documentation (6 hours)
14. DocC catalog
15. SPI configuration
16. LICENSE
17. Contributing guidelines
18. README with badges

### Phase 6: Polish (2 hours)
19. Optional: XcodeGen, DevContainer, MCP
20. .gitignore enhancement
21. Final verification

**Total Estimated Effort**: 24 hours

---

## Success Metrics

- [ ] Test coverage ≥90% for model files
- [ ] Zero linting errors in strict mode
- [ ] CI/CD passes on all platforms
- [ ] DocC documentation published
- [ ] README with 10+ green badges
- [ ] All public APIs documented

---

## Critical Files

**Must Create/Modify**:
1. `.github/workflows/CelestraKit.yml` - Core CI/CD
2. `Tests/CelestraKitTests/Models/PublicDatabase/ArticleTests.swift` - Article tests
3. `Scripts/lint.sh` - Quality automation
4. `Package.swift` - Fix SyndiKit dependency
5. `README.md` - Project documentation

**Removed from Original PRD**:
- ❌ "change name of package to appropiate name" - Package name is correct
- ❌ "migration existing Root Markdown file to appropaite folder" - Clarified as DocC organization

**Fixed Typos**:
- ~~"appropaite"~~ → "appropriate"
- ~~"configugration"~~ → "configuration"
