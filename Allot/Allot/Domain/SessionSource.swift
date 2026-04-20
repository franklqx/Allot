//
//  SessionSource.swift
//  Allot
//
//  TimeSession 的来源：正计时或补录（见 PRODUCT_SPEC §12.3）。

import Foundation

enum SessionSource: String, Codable, CaseIterable {
    /// 用户在 App 内开始/暂停/结束的正计时
    case liveTimer
    /// 补录时间段
    case manualEntry
}
