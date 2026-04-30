//
//  WidgetPreferences.swift
//  Allot
//
//  Per-widget customization options. Lives in the App Group UserDefaults
//  alongside WidgetSnapshot — main app writes via Settings UI, widget
//  extension reads on every timeline build.
//
//  Pro feature: customization is intended to be paywalled in v2 when StoreKit
//  integration ships. For v1.1 all options are freely accessible.

import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

struct WidgetPreferences: Codable, Equatable {

    static let appGroup = "group.com.EL.fire.Allot1"
    static let userDefaultsKey = "widgetPreferences.v1"

    // MARK: - Enums

    enum AllottedRange: String, Codable, CaseIterable {
        case today
        case week

        var displayName: String {
            switch self {
            case .today: return "Today"
            case .week:  return "This week"
            }
        }
    }

    enum AllottedView: String, Codable, CaseIterable {
        case byTag
        case byTask

        var displayName: String {
            switch self {
            case .byTag:  return "By tag"
            case .byTask: return "By task"
            }
        }
    }

    enum CircularCenter: String, Codable, CaseIterable {
        case totalTime         // "4h" / "23m"
        case topTagPercentage  // "44%"
        case topTagEmoji       // "💼"

        var displayName: String {
            switch self {
            case .totalTime:        return "Total time"
            case .topTagPercentage: return "Top tag %"
            case .topTagEmoji:      return "Top tag emoji"
            }
        }
    }

    enum InlineFormat: String, Codable, CaseIterable {
        case compact    // "▶ 1h 23m · X"
        case verbose    // "Focusing 1h 23m on X"
        case timerOnly  // "▶ 1h 23m"

        var displayName: String {
            switch self {
            case .compact:   return "Compact"
            case .verbose:   return "Verbose"
            case .timerOnly: return "Timer only"
            }
        }
    }

    enum QuickStartSource: String, Codable, CaseIterable {
        case autoRecent   // 4 most recent tasks
        case pinned       // user-selected up to 4

        var displayName: String {
            switch self {
            case .autoRecent: return "Most recent"
            case .pinned:     return "Pinned tasks"
            }
        }
    }

    // MARK: - Per-widget prefs

    struct LiveFocusPrefs: Codable, Equatable {
        var hideWhenIdle: Bool = false
    }

    struct TodayAllottedPrefs: Codable, Equatable {
        var range: AllottedRange = .today
        var view: AllottedView = .byTag
        /// Number of buckets to display before merging into "Others". 3-5.
        var bucketCount: Int = 4
    }

    struct TodayCircularPrefs: Codable, Equatable {
        var center: CircularCenter = .totalTime
    }

    struct FocusInlinePrefs: Codable, Equatable {
        var format: InlineFormat = .compact
    }

    struct QuickStartPrefs: Codable, Equatable {
        var source: QuickStartSource = .autoRecent
        /// Up to 4 task IDs the user has pinned. Only used when source == .pinned.
        var pinnedTaskIds: [UUID] = []
    }

    // MARK: - Aggregated

    var liveFocus: LiveFocusPrefs = .init()
    var todayAllotted: TodayAllottedPrefs = .init()
    var todayCircular: TodayCircularPrefs = .init()
    var focusInline: FocusInlinePrefs = .init()
    var quickStart: QuickStartPrefs = .init()

    // MARK: - Persistence

    static let `default` = WidgetPreferences()

    static func load() -> WidgetPreferences {
        guard
            let defaults = UserDefaults(suiteName: appGroup),
            let data = defaults.data(forKey: userDefaultsKey),
            let prefs = try? JSONDecoder().decode(WidgetPreferences.self, from: data)
        else { return .default }
        return prefs
    }

    func save() {
        guard let defaults = UserDefaults(suiteName: WidgetPreferences.appGroup) else { return }
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: WidgetPreferences.userDefaultsKey)
    }

    /// Save and reload widget timelines. Use after a Settings change.
    func publish() {
        save()
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
