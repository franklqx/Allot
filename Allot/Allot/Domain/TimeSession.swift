//
//  TimeSession.swift
//  Allot
//
//  A recorded time segment. workTask is nil for unbound (free) timer sessions.

import Foundation
import SwiftData

@Model final class TimeSession {
    var id: UUID
    /// UTC start timestamp.
    var startAt: Date
    /// UTC end timestamp. nil while actively running.
    var endAt: Date?
    /// Accumulated pause duration in seconds (not counted in effective duration).
    var totalPausedSeconds: Int
    var source: SessionSource
    /// Non-nil only when source == .quickLog.
    var quickLogSubtype: QuickLogSubtype?

    /// nil for unbound timer sessions.
    var workTask: WorkTask?

    // Effective duration = (endAt - startAt) - totalPausedSeconds

    init(
        id: UUID = UUID(),
        startAt: Date,
        endAt: Date? = nil,
        totalPausedSeconds: Int = 0,
        source: SessionSource = .liveTimer,
        quickLogSubtype: QuickLogSubtype? = nil,
        workTask: WorkTask? = nil
    ) {
        self.id = id
        self.startAt = startAt
        self.endAt = endAt
        self.totalPausedSeconds = totalPausedSeconds
        self.source = source
        self.quickLogSubtype = quickLogSubtype
        self.workTask = workTask
    }
}
