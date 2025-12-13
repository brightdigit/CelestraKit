# Cross-Platform Considerations

Platform-specific patterns and considerations across Apple's ecosystem.

## Overview

CelestraKit supports iOS 26+, macOS 26+, watchOS 26+, tvOS 26+, and visionOS 26+. While the core models work identically across platforms, each has unique considerations.

## Platform Support Matrix

| Feature | iOS | macOS | watchOS | tvOS | visionOS |
|---------|-----|-------|---------|------|----------|
| CloudKit Public DB | ✓ | ✓ | ✓ | ✓ | ✓ |
| Full UI | ✓ | ✓ | Limited | Limited | ✓ |
| Background Fetch | ✓ | ✓ | ✓ | ✗ | ✓ |
| Network Access | ✓ | ✓ | Paired | ✓ | ✓ |

## iOS Considerations

### Background Fetch

```swift
import BackgroundTasks

func registerBackgroundTasks() {
    BGTaskScheduler.shared.register(
        forTaskWithIdentifier: "com.example.feed-refresh",
        using: nil
    ) { task in
        handleFeedRefresh(task: task as! BGProcessingTask)
    }
}

func handleFeedRefresh(task: BGProcessingTask) {
    Task {
        do {
            // Fetch feeds
            let feeds = try await fetchAllFeeds()

            // Update articles
            for feed in feeds {
                let articles = try await fetchArticles(for: feed)
                // Process...
            }

            task.setTaskCompleted(success: true)
        } catch {
            task.setTaskCompleted(success: false)
        }
    }
}
```

### Widget Support

```swift
import WidgetKit

struct FeedWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "FeedWidget",
            provider: FeedTimelineProvider()
        ) { entry in
            FeedWidgetView(entry: entry)
        }
    }
}

struct FeedTimelineProvider: TimelineProvider {
    func timeline(for configuration: ConfigurationIntent, in context: Context) async -> Timeline<FeedEntry> {
        // Fetch latest articles
        let articles = try? await fetchLatestArticles()

        let entry = FeedEntry(
            date: Date(),
            articles: articles ?? []
        )

        return Timeline(entries: [entry], policy: .atEnd)
    }
}
```

## macOS Considerations

### Menu Bar App

```swift
import AppKit

class FeedMenuBarController {
    private var statusItem: NSStatusItem?

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength
        )

        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "newspaper",
                accessibilityDescription: "Feeds"
            )
        }

        setupMenu()
    }

    func setupMenu() {
        let menu = NSMenu()

        Task {
            let feeds = try? await fetchFeeds()

            for feed in feeds ?? [] {
                let item = NSMenuItem(
                    title: feed.title,
                    action: #selector(openFeed(_:)),
                    keyEquivalent: ""
                )
                menu.addItem(item)
            }

            statusItem?.menu = menu
        }
    }
}
```

## watchOS Considerations

### Complications

```swift
import ClockKit

class ComplicationController: CLKComplicationDataSource {
    func getCurrentTimelineEntry(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void
    ) {
        Task {
            let articles = try? await fetchLatestArticles(limit: 1)

            guard let article = articles?.first else {
                handler(nil)
                return
            }

            let template = CLKComplicationTemplateGraphicCircularStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: "RSS")
            template.line2TextProvider = CLKSimpleTextProvider(text: article.title)

            let entry = CLKComplicationTimelineEntry(
                date: Date(),
                complicationTemplate: template
            )

            handler(entry)
        }
    }
}
```

## tvOS Considerations

### Focus Engine

```swift
import UIKit

class FeedCell: UICollectionViewCell {
    override func didUpdateFocus(
        in context: UIFocusUpdateContext,
        with coordinator: UIFocusAnimationCoordinator
    ) {
        coordinator.addCoordinatedAnimations {
            if self.isFocused {
                self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            } else {
                self.transform = .identity
            }
        }
    }
}
```

## visionOS Considerations

### Spatial UI

```swift
import SwiftUI
import RealityKit

struct FeedSpatialView: View {
    let feeds: [Feed]

    var body: some View {
        ForEach(feeds) { feed in
            FeedCard(feed: feed)
                .frame(depth: 100)
                .hoverEffect()
        }
        .padding3D()
    }
}
```

## Memory Considerations

### watchOS Memory Limits

```swift
actor FeedCache {
    private var cache: [String: Feed] = [:]
    private let maxCacheSize = 50 // Smaller for watchOS

    func addFeed(_ feed: Feed) {
        // Evict oldest if needed
        if cache.count >= maxCacheSize {
            let oldestKey = cache.keys.first!
            cache.removeValue(forKey: oldestKey)
        }

        cache[feed.id] = feed
    }
}
```

## Network Considerations

### Cellular vs. Wi-Fi

```swift
import Network

func shouldFetch(using path: NWPath) -> Bool {
    // watchOS on cellular: fetch minimal data
    #if os(watchOS)
    if path.usesInterfaceType(.cellular) {
        return false // Wait for Wi-Fi
    }
    #endif

    return true
}
```

## See Also

- <doc:CloudKitIntegration>
- <doc:ConcurrencyPatterns>
- ``Feed``
- ``Article``
