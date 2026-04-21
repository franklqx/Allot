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
    var type: TaskType              // .once / .recurring
    var timerMode: TimerMode        // .stopwatch / .countdown
    /// Countdown target in seconds. Only used when timerMode == .countdown. Default 1500 (25 min).
    var countdownDuration: Int

    // ── Schedule ─────────────────────────────────────
    /// Calendar date for once tasks. nil for recurring.
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
        self.tag = tag
        self.sessions = []
    }
}
