//
//  WorkTask.swift
//  Allot
//
//  产品规格中的 Task；Swift 并发已有 Task，故模型命名为 WorkTask。

import Foundation
import SwiftData

@Model
final class WorkTask {
    var id: UUID
    var title: String
    var createdAt: Date

    // ── 时间目标 ──────────────────────────────────────
    /// 每次做这件事的目标时长（秒）。nil = 没有目标，只记录时间。
    var targetDuration: Int?

    // ── 排期 ─────────────────────────────────────────
    /// true = 重复任务；false = 一次性任务。
    var isRecurring: Bool

    /// 重复的星期。空数组 = 每天；[1,2,3,4,5] = 工作日；[6,7] = 周末。
    /// 1=周一 ... 7=周日。仅 isRecurring = true 时有意义。
    var recurringDays: [Int]

    /// 一次性任务的具体日期。isRecurring = false 时使用。
    var scheduledDate: Date?

    /// 任务开始的具体时间（只使用小时/分钟部分）。nil = 无固定时间。
    var scheduledTime: Date?

    // ── 关联 ─────────────────────────────────────────
    var tags: [Tag]

    @Relationship(deleteRule: .cascade, inverse: \TimeSession.workTask)
    var sessions: [TimeSession]

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        targetDuration: Int? = nil,
        isRecurring: Bool = false,
        recurringDays: [Int] = [],
        scheduledDate: Date? = nil,
        scheduledTime: Date? = nil,
        tags: [Tag] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.targetDuration = targetDuration
        self.isRecurring = isRecurring
        self.recurringDays = recurringDays
        self.scheduledDate = scheduledDate
        self.scheduledTime = scheduledTime
        self.tags = tags
        self.sessions = []
    }
}
