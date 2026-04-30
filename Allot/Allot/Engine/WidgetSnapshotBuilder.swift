//
//  WidgetSnapshotBuilder.swift
//  Allot
//
//  Pulls fresh data out of SwiftData + TimerService and pushes a
//  WidgetSnapshot to the App Group. Call after lifecycle changes:
//  start / pause / resume / stop, plus any time today's session list
//  changes materially (post-quick-log, post-completion).
//
//  Two axes precomputed: by-tag and by-task. Two ranges precomputed: today
//  and this week. Widgets pick which axis/range based on user preferences
//  without paying a SwiftData round-trip on every timeline build.

import Foundation
import SwiftData

@MainActor
enum WidgetSnapshotBuilder {

    static func publish(in context: ModelContext, timerService: TimerService) {
        let todayByTag  = todayBuckets(in: context, axis: .byTag)
        let todayByTask = todayBuckets(in: context, axis: .byTask)
        let weekByTag   = weekBuckets(in: context, axis: .byTag)
        let weekByTask  = weekBuckets(in: context, axis: .byTask)

        let todayTotal = todayByTag.reduce(0) { $0 + $1.seconds }
        let weekTotal  = weekByTag.reduce(0)  { $0 + $1.seconds }

        let snapshot = WidgetSnapshot(
            activeSession: activeSessionSnapshot(timerService),
            recentTasks: recentTasks(in: context),
            todayTotalSeconds: todayTotal,
            todayBucketsByTag: todayByTag,
            todayBucketsByTask: todayByTask,
            weekTotalSeconds: weekTotal,
            weekBucketsByTag: weekByTag,
            weekBucketsByTask: weekByTask,
            todayBuckets: todayByTag,   // legacy mirror
            updatedAt: Date()
        )
        snapshot.publish()
    }

    // MARK: Active session

    private static func activeSessionSnapshot(_ ts: TimerService) -> WidgetSnapshot.ActiveSession? {
        guard ts.isRunning, let session = ts.activeSession else { return nil }
        let task = session.workTask
        let anchored = (session.startAt).addingTimeInterval(TimeInterval(session.totalPausedSeconds))
        return WidgetSnapshot.ActiveSession(
            taskTitle: task?.title ?? "Untagged",
            tagEmoji: task?.tag?.emoji,
            tagColorToken: task?.tag?.colorToken ?? "gray",
            anchoredStart: anchored,
            isPaused: ts.isPaused,
            countdownSeconds: ts.countdownTarget
        )
    }

    // MARK: Recent tasks

    private static func recentTasks(in context: ModelContext) -> [WidgetSnapshot.RecentTask] {
        var descriptor = FetchDescriptor<TimeSession>(
            sortBy: [SortDescriptor(\.startAt, order: .reverse)]
        )
        descriptor.fetchLimit = 40
        let sessions = (try? context.fetch(descriptor)) ?? []
        var seen = Set<UUID>()
        var out: [WidgetSnapshot.RecentTask] = []
        for s in sessions {
            guard let task = s.workTask else { continue }
            guard !seen.contains(task.id) else { continue }
            seen.insert(task.id)
            out.append(WidgetSnapshot.RecentTask(
                id: task.id,
                title: task.title,
                tagEmoji: task.tag?.emoji,
                tagColorToken: task.tag?.colorToken ?? "gray"
            ))
            if out.count == 4 { break }
        }
        return out
    }

    // MARK: Bucket aggregation

    private enum Axis {
        case byTag
        case byTask
    }

    private static func todayBounds() -> (Date, Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return (start, end)
    }

    private static func weekBounds() -> (Date, Date) {
        // Match Allotted view: week runs Mon → next Mon.
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        let now = Date()
        let start = cal.dateInterval(of: .weekOfYear, for: now)?.start ?? cal.startOfDay(for: now)
        let end = cal.date(byAdding: .weekOfYear, value: 1, to: start) ?? start.addingTimeInterval(7 * 86_400)
        return (start, end)
    }

    private static func todayBuckets(in context: ModelContext, axis: Axis) -> [WidgetSnapshot.TodayBucket] {
        let (start, end) = todayBounds()
        return aggregateBuckets(in: context, start: start, end: end, axis: axis)
    }

    private static func weekBuckets(in context: ModelContext, axis: Axis) -> [WidgetSnapshot.TodayBucket] {
        let (start, end) = weekBounds()
        return aggregateBuckets(in: context, start: start, end: end, axis: axis)
    }

    private static func aggregateBuckets(
        in context: ModelContext,
        start: Date,
        end: Date,
        axis: Axis
    ) -> [WidgetSnapshot.TodayBucket] {
        let descriptor = FetchDescriptor<TimeSession>(
            predicate: #Predicate { $0.startAt >= start && $0.startAt < end }
        )
        let sessions = (try? context.fetch(descriptor)) ?? []

        struct Accum {
            var label: String
            var colorToken: String
            var seconds: Int
        }
        var grouped: [String: Accum] = [:]

        for s in sessions {
            let dur = max(0, sessionDurationSeconds(s))
            let key: String
            let label: String
            let colorToken: String

            switch axis {
            case .byTag:
                let tag = s.workTask?.tag
                key = tag?.id.uuidString ?? "untagged"
                label = tag?.name ?? "Untagged"
                colorToken = tag?.colorToken ?? "gray"
            case .byTask:
                if let task = s.workTask {
                    key = task.id.uuidString
                    label = task.title
                    // For by-task we still color by tag so the visual stays
                    // consistent with the rest of Allotted.
                    colorToken = task.tag?.colorToken ?? "gray"
                } else {
                    key = "unbound"
                    label = "Unbound"
                    colorToken = "gray"
                }
            }
            grouped[key, default: Accum(label: label, colorToken: colorToken, seconds: 0)].seconds += dur
        }

        let buckets = grouped
            .map { (id, acc) in
                WidgetSnapshot.TodayBucket(
                    id: id,
                    label: acc.label,
                    colorToken: acc.colorToken,
                    seconds: acc.seconds
                )
            }
            .sorted { $0.seconds > $1.seconds }

        // Cap to top 5 + Others. Widgets that want fewer will trim further on read.
        guard buckets.count > 5 else { return buckets }
        let top = Array(buckets.prefix(5))
        let othersSeconds = buckets.dropFirst(5).reduce(0) { $0 + $1.seconds }
        return top + [
            WidgetSnapshot.TodayBucket(id: "others", label: "Others", colorToken: "gray", seconds: othersSeconds)
        ]
    }

    private static func sessionDurationSeconds(_ s: TimeSession) -> Int {
        let endAt = s.endAt ?? Date()
        let raw = endAt.timeIntervalSince(s.startAt)
        return max(0, Int(raw) - s.totalPausedSeconds)
    }
}
