//
//  FocusActivityAttributes.swift
//  Allot
//
//  Live Activity payload shared between the main app and AllotLiveActivity
//  widget extension. Add this file to BOTH targets in Xcode.

import ActivityKit
import Foundation

struct FocusActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var emoji: String
        var tagName: String
        /// Design-system color token (e.g. "sky", "lime"). Mapped to a Color
        /// inside the widget via the shared DesignTokens helper.
        var tagColorToken: String
        var taskTitle: String
        /// Wall-clock anchor for `Text(timerInterval:)` math.
        var startAt: Date
        /// Total seconds the user has paused the session so far. The widget
        /// shifts the timer's anchor by this amount so the displayed elapsed
        /// stays correct without per-second app updates.
        var pausedSeconds: Int
        var isPaused: Bool
        /// nil ⇒ stopwatch (count up). non-nil ⇒ countdown of N seconds.
        var countdownSeconds: Int?
        /// Total seconds spent on this task today, captured at activity start.
        /// Shown only in the expanded view.
        var todayTotalSeconds: Int
        /// How many hours of stopwatch range to reserve in the timer display.
        /// Starts at 1 (M:SS, tight pill). Auto-extended to 24 once the user
        /// crosses 55 minutes, so the format stays correct for long sessions.
        var stopwatchCapHours: Int
    }

    var sessionId: UUID
}
