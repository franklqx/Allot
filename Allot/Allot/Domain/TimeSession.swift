//
//  TimeSession.swift
//  Allot
//
//  一段可归属到 WorkTask 的时间记录（正计时结束或补录）。

import Foundation
import SwiftData

@Model
final class TimeSession {
    var id: UUID
    var startAt: Date
    var endAt: Date?
    /// 暂停累计秒数（规格 §12.3；正计时采用暂停累计模型时使用）
    var totalPausedSeconds: Int
    var source: SessionSource

    @Relationship(inverse: \WorkTask.sessions)
    var workTask: WorkTask

    init(
        id: UUID = UUID(),
        startAt: Date,
        endAt: Date? = nil,
        totalPausedSeconds: Int = 0,
        source: SessionSource = .liveTimer,
        workTask: WorkTask
    ) {
        self.id = id
        self.startAt = startAt
        self.endAt = endAt
        self.totalPausedSeconds = totalPausedSeconds
        self.source = source
        self.workTask = workTask
    }
}
