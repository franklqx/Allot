//
//  WidgetSnapshot.swift
//  Allot
//
//  Cross-process snapshot of timer state + today's distribution. Written by
//  the main app to App Group UserDefaults, read by the Widget Extension.
//
//  Why not let widgets read SwiftData directly? Two reasons:
//   1. ModelContainer is per-process; widget would need its own. Concurrent
//      writes from main app + widget cause conflicts.
//   2. Widget timeline reload budget is tight; reading SwiftData on every
//      timeline tick is wasteful when a small JSON snapshot covers all
//      widget surfaces.

import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

struct WidgetSnapshot: Codable, Equatable {

    static let appGroup       = "group.com.EL.fire.Allot1"
    static let userDefaultsKey = "widgetSnapshot.v1"

    struct ActiveSession: Codable, Equatable {
        var taskTitle: String
        var tagEmoji: String?
        var tagColorToken: String
        /// Wall-clock start adjusted by paused seconds; widget computes elapsed
        /// as Date.now - startAt without needing per-tick refreshes.
        var anchoredStart: Date
        var isPaused: Bool
        /// Optional countdown target for live progress rendering.
        var countdownSeconds: Int?
    }

    struct RecentTask: Codable, Equatable, Identifiable {
        var id: UUID
        var title: String
        var tagEmoji: String?
        var tagColorToken: String
    }

    struct TodayBucket: Codable, Equatable, Identifiable {
        var id: String   // tag id or "others"
        var label: String
        var colorToken: String
        var seconds: Int
    }

    var activeSession: ActiveSession?
    var recentTasks: [RecentTask]

    // Today (start-of-day → start-of-tomorrow) — both axes precomputed so
    // widgets can switch between them without a SwiftData fetch.
    var todayTotalSeconds: Int
    var todayBucketsByTag: [TodayBucket] = []
    var todayBucketsByTask: [TodayBucket] = []

    // This week (Mon → next Mon, matching Allotted view).
    var weekTotalSeconds: Int = 0
    var weekBucketsByTag: [TodayBucket] = []
    var weekBucketsByTask: [TodayBucket] = []

    /// Legacy field kept for back-compat with widgets that haven't been
    /// updated to consume the new dual-axis fields yet. Mirrors `todayBucketsByTag`.
    var todayBuckets: [TodayBucket]

    var updatedAt: Date

    static let empty = WidgetSnapshot(
        activeSession: nil,
        recentTasks: [],
        todayTotalSeconds: 0,
        todayBuckets: [],
        updatedAt: .distantPast
    )

    /// Sample data for placeholder/preview rendering. Used by both the widget
    /// extension's TimelineProvider AND the main app's Settings preview, so
    /// it lives here in the shared file (visible to both targets).
    static let placeholder: WidgetSnapshot = {
        let byTagToday: [TodayBucket] = [
            TodayBucket(id: "1", label: "Work",   colorToken: "sky",      seconds: 2 * 3600),
            TodayBucket(id: "2", label: "Health", colorToken: "lime",     seconds: 60 * 60),
            TodayBucket(id: "3", label: "Learn",  colorToken: "lilac",    seconds: 45 * 60),
            TodayBucket(id: "4", label: "Life",   colorToken: "marigold", seconds: 38 * 60),
        ]
        let byTaskToday: [TodayBucket] = [
            TodayBucket(id: "t1", label: "Main job",     colorToken: "sky",      seconds: 80 * 60),
            TodayBucket(id: "t2", label: "Side project", colorToken: "sky",      seconds: 50 * 60),
            TodayBucket(id: "t3", label: "Strength",     colorToken: "lime",     seconds: 60 * 60),
            TodayBucket(id: "t4", label: "Reading",      colorToken: "lilac",    seconds: 45 * 60),
        ]
        let byTagWeek: [TodayBucket] = [
            TodayBucket(id: "1", label: "Work",   colorToken: "sky",      seconds: 18 * 3600),
            TodayBucket(id: "2", label: "Health", colorToken: "lime",     seconds: 9 * 3600),
            TodayBucket(id: "3", label: "Learn",  colorToken: "lilac",    seconds: 6 * 3600),
            TodayBucket(id: "4", label: "Life",   colorToken: "marigold", seconds: 4 * 3600),
        ]
        let byTaskWeek: [TodayBucket] = [
            TodayBucket(id: "t1", label: "Main job",     colorToken: "sky",      seconds: 14 * 3600),
            TodayBucket(id: "t2", label: "Side project", colorToken: "sky",      seconds: 4 * 3600),
            TodayBucket(id: "t3", label: "Strength",     colorToken: "lime",     seconds: 7 * 3600),
            TodayBucket(id: "t4", label: "Reading",      colorToken: "lilac",    seconds: 5 * 3600),
        ]

        return WidgetSnapshot(
            activeSession: ActiveSession(
                taskTitle: "Side project",
                tagEmoji: "💼",
                tagColorToken: "sky",
                anchoredStart: Date().addingTimeInterval(-23 * 60),
                isPaused: false,
                countdownSeconds: nil
            ),
            recentTasks: [
                RecentTask(id: UUID(), title: "Side project", tagEmoji: "💼", tagColorToken: "sky"),
                RecentTask(id: UUID(), title: "Strength",     tagEmoji: "💪", tagColorToken: "lime"),
                RecentTask(id: UUID(), title: "Reading",      tagEmoji: "📚", tagColorToken: "lilac"),
                RecentTask(id: UUID(), title: "Walk",         tagEmoji: "🏠", tagColorToken: "marigold"),
            ],
            todayTotalSeconds: 4 * 3600 + 23 * 60,
            todayBucketsByTag: byTagToday,
            todayBucketsByTask: byTaskToday,
            weekTotalSeconds: 37 * 3600,
            weekBucketsByTag: byTagWeek,
            weekBucketsByTask: byTaskWeek,
            todayBuckets: byTagToday,
            updatedAt: Date()
        )
    }()

    // MARK: Persistence

    static func load() -> WidgetSnapshot {
        guard
            let defaults = UserDefaults(suiteName: appGroup),
            let data = defaults.data(forKey: userDefaultsKey),
            let snap = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return .empty }
        return snap
    }

    func save() {
        guard let defaults = UserDefaults(suiteName: WidgetSnapshot.appGroup) else { return }
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: WidgetSnapshot.userDefaultsKey)
    }

    /// Save and reload widget timelines. Use after a state change in the main app.
    func publish() {
        save()
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
