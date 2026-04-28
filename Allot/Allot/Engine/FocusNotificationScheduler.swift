//
//  FocusNotificationScheduler.swift
//  Allot
//
//  Local-notification fallback for focus session alerts. Lives separately
//  from the Live Activity so the user still gets a banner when the app is
//  killed (Live Activity alertConfiguration only fires while the activity
//  is alive).
//
//  Lifecycle (called from TimerService):
//    start  → requestAuthorizationIfNeeded(); schedule(...)
//    pause  → cancelAll() (we'll reschedule on resume with a fresh anchor)
//    resume → schedule(...) using the current pause-adjusted elapsed
//    stop   → cancelAll()

import Foundation
import UserNotifications

enum FocusNotificationScheduler {

    private static let categoryId = "com.allot.focus.reminder"
    /// Cap stopwatch reminders at 12 hours of session length.
    private static let stopwatchReminderHorizonSeconds = 12 * 3600

    static func requestAuthorizationIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
            default:
                break
            }
        }
    }

    /// Schedule reminders for a session based on its mode.
    ///
    /// - Parameters:
    ///   - taskTitle: shown in the notification body. May be empty.
    ///   - countdownSeconds: when set, schedule a single completion alert.
    ///   - reminderIntervalMinutes: 0 ⇒ no stopwatch reminders. Used only
    ///     when `countdownSeconds == nil`.
    ///   - elapsedSecondsAtStart: nonzero on resume — shifts reminder offsets
    ///     so we don't double-fire ones that already passed during the first
    ///     run before the pause.
    static func schedule(
        taskTitle: String,
        countdownSeconds: Int?,
        reminderIntervalMinutes: Int,
        elapsedSecondsAtStart: Int = 0
    ) {
        cancelAll()
        let center = UNUserNotificationCenter.current()

        if let target = countdownSeconds {
            let remaining = max(1, target - elapsedSecondsAtStart)
            let content = UNMutableNotificationContent()
            content.title = "时间到"
            content.body = taskTitle.isEmpty ? "Countdown finished." : taskTitle
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(remaining),
                repeats: false
            )
            let req = UNNotificationRequest(
                identifier: countdownIdentifier,
                content: content,
                trigger: trigger
            )
            center.add(req) { _ in }
            return
        }

        // Stopwatch reminders.
        guard reminderIntervalMinutes > 0 else { return }
        let intervalSeconds = reminderIntervalMinutes * 60
        var offset = intervalSeconds - (elapsedSecondsAtStart % intervalSeconds)
        var n = 1
        while offset <= stopwatchReminderHorizonSeconds {
            let totalElapsedAtFire = elapsedSecondsAtStart + offset
            let content = UNMutableNotificationContent()
            content.title = "Still focusing"
            let elapsedLabel = elapsedDescription(totalElapsedAtFire)
            content.body = taskTitle.isEmpty
                ? "You've been at it for \(elapsedLabel)."
                : "\(taskTitle) — \(elapsedLabel)."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(offset),
                repeats: false
            )
            let req = UNNotificationRequest(
                identifier: stopwatchIdentifier(n),
                content: content,
                trigger: trigger
            )
            center.add(req) { _ in }
            offset += intervalSeconds
            n += 1
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: allIdentifiers())
    }

    // MARK: - Identifiers

    private static let countdownIdentifier = "focus.countdown.complete"
    private static func stopwatchIdentifier(_ n: Int) -> String { "focus.stopwatch.\(n)" }
    private static func allIdentifiers() -> [String] {
        var ids = [countdownIdentifier]
        // Generous upper bound: 12h / 30m = 24 reminders max.
        for i in 1...32 { ids.append(stopwatchIdentifier(i)) }
        return ids
    }

    private static func elapsedDescription(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}
