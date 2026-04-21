//
//  Enums.swift
//  Allot

import Foundation

enum TaskType: String, Codable, CaseIterable {
    case once
    case recurring
}

enum TimerMode: String, Codable, CaseIterable {
    case stopwatch
    case countdown
}

enum RepeatRule: String, Codable, CaseIterable {
    case everyDay
    case everyWeekday   // Mon–Fri
    case everyWeekend   // Sat–Sun
    case weekly         // specific weekday(s), see repeatCustomDays
    case monthly        // specific day-of-month, see repeatCustomDays
    case yearly
    case custom         // free selection, see repeatCustomDays
}

enum QuickLogSubtype: String, Codable, CaseIterable {
    case manual         // long-press Done
    case completion     // Complete with no existing session
    case sleepHealth    // Pro: Apple Health sleep sync
}
