//
//  WorkTask.swift
//  Allot
//
//  Swift reserves "Task" for concurrency, so the model is named WorkTask.

import Foundation
import SwiftData

@Model final class WorkTask {
    var id: UUID
    var title: String
    var createdAt: Date

    // ── Type & timer ─────────────────────────────────
    var type: TaskType              // .once / .recurring / .longTerm
    var timerMode: TimerMode        // .stopwatch / .countdown
    /// Countdown target in seconds. Only used when timerMode == .countdown. Default 1500 (25 min).
    var countdownDuration: Int

    // ── Schedule ─────────────────────────────────────
    /// Calendar date for once tasks. nil for recurring/longTerm.
    var scheduledDate: Date?
    /// Scheduled start time as minutes from midnight (0–1439). nil = no fixed time.
    var startTime: Int?

    // ── Recurrence ───────────────────────────────────
    /// Required when type == .recurring.
    var repeatRule: RepeatRule?
    /// Day indices for .weekly (1=Mon…7=Sun), .monthly (1–31), or .custom.
    var repeatCustomDays: [Int]

    // ── Completion ───────────────────────────────────
    /// Per-day completion dates. Once tasks have at most one entry.
    var completedDates: [Date]
    /// Duration (seconds) recorded via quickLog at completion time.
    var completedDuration: Int
    /// Manual ordering for Home list. Lower values appear first.
    var sortOrder: Int = 0
    /// When set, task is archived (long-term "permanently done") and hidden from Home.
    /// Sessions and analytics still reference it for historical reporting.
    var archivedAt: Date?

    // ── Relationships ────────────────────────────────
    var tag: Tag?

    @Relationship(deleteRule: .cascade, inverse: \TimeSession.workTask)
    var sessions: [TimeSession] = []

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        type: TaskType = .once,
        timerMode: TimerMode = .stopwatch,
        countdownDuration: Int = 1500,
        scheduledDate: Date? = nil,
        startTime: Int? = nil,
        repeatRule: RepeatRule? = nil,
        repeatCustomDays: [Int] = [],
        completedDates: [Date] = [],
        completedDuration: Int = 0,
        sortOrder: Int = 0,
        archivedAt: Date? = nil,
        tag: Tag? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.type = type
        self.timerMode = timerMode
        self.countdownDuration = countdownDuration
        self.scheduledDate = scheduledDate
        self.startTime = startTime
        self.repeatRule = repeatRule
        self.repeatCustomDays = repeatCustomDays
        self.completedDates = completedDates
        self.completedDuration = completedDuration
        self.sortOrder = sortOrder
        self.archivedAt = archivedAt
        self.tag = tag
        self.sessions = []
    }
}
