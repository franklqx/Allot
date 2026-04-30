//
//  TimerService.swift
//  Allot
//
//  Singleton owned by App lifecycle. NOT embedded in a ViewModel — timers inside
//  ViewModels don't survive background transitions.
//
//  Usage:
//    @Environment(TimerService.self) var timerService
//    timerService.start(task: task, in: modelContext)
//    timerService.pause()
//    timerService.resume()
//    timerService.stop(in: modelContext)

import Foundation
import SwiftData
import Observation
import ActivityKit

// Persisted to UserDefaults for app-kill recovery.
struct ActiveSessionSentinel: Codable {
    let taskId: UUID
    let taskTitle: String
    let startAt: Date
}

@Observable final class TimerService {

    // MARK: Public state (read-only outside)

    private(set) var isRunning = false
    private(set) var isPaused = false
    /// Net elapsed seconds: (now - startAt) minus accumulated pauses.
    private(set) var elapsedSeconds = 0
    /// The SwiftData session currently being recorded.
    private(set) var activeSession: TimeSession?
    /// When set, the session is a countdown of this many seconds.
    /// `displaySeconds` then returns the remaining time instead of the elapsed.
    private(set) var countdownTarget: Int?
    private(set) var countdownCompleted = false

    /// What the running UI should show. Counts up for stopwatch, counts down
    /// for countdown sessions (clamped at 0).
    var displaySeconds: Int {
        if let target = countdownTarget {
            return max(0, target - elapsedSeconds)
        }
        return elapsedSeconds
    }

    // MARK: Private

    private var ticker: Timer?
    private var pauseStart: Date?
    private var accumulatedPausedSeconds = 0
    private let systemIntegrationsEnabled: Bool

    private static let sentinelKey = "activeSession"
    private static let reminderIntervalKey = "focusReminderIntervalMinutes"
    private static let dynamicIslandEnabledKey = "dynamicIslandEnabled"
    private static let showTaskEmojiKey = "showTaskEmoji"

    init(systemIntegrationsEnabled: Bool = true) {
        self.systemIntegrationsEnabled = systemIntegrationsEnabled

        // App cold start: the system may still hold Live Activities from a
        // previous launch (foreground crash, force-quit, OS bug). End them
        // unconditionally so we don't end up with two stacked activities once
        // the user starts a new session.
        if systemIntegrationsEnabled {
            Task { await Self.endAllActivitiesAtLaunch() }
        }
    }

    private static func endAllActivitiesAtLaunch() async {
        for activity in Activity<FocusActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    // MARK: Live Activity

    private var liveActivity: Activity<FocusActivityAttributes>?
    /// Reserved hours for the stopwatch timer text on the island. Starts at 1
    /// so the OS uses M:SS format (tight pill, like Apple Workout). Bumped to
    /// 24 once we approach the 1-hour mark so long sessions stay correct.
    private var stopwatchCapHours: Int = 1

    // MARK: Controls

    func start(task: WorkTask, countdownSeconds: Int? = nil, in context: ModelContext) {
        guard !isRunning else { return }

        let now = Date()
        let session = TimeSession(startAt: now, source: .liveTimer, workTask: task)
        context.insert(session)
        try? context.save()

        activeSession = session
        elapsedSeconds = 0
        accumulatedPausedSeconds = 0
        pauseStart = nil
        countdownTarget = countdownSeconds
        countdownCompleted = false
        isRunning = true
        isPaused = false

        writeSentinel(taskId: task.id, taskTitle: task.title, startAt: now)
        startTicker()

        if systemIntegrationsEnabled {
            FocusNotificationScheduler.requestAuthorizationIfNeeded()
            FocusNotificationScheduler.schedule(
                taskTitle: liveActivityTaskTitle(for: task),
                countdownSeconds: countdownSeconds,
                reminderIntervalMinutes: reminderIntervalMinutesPreference
            )
            startLiveActivity(
                sessionId: session.id,
                task: task,
                startAt: now,
                countdownSeconds: countdownSeconds,
                todayTotalSeconds: todayTotalSeconds(for: task, in: context)
            )
        }
        WidgetSnapshotBuilder.publish(in: context, timerService: self)
    }

    func startUnbound(countdownSeconds: Int? = nil, in context: ModelContext) {
        guard !isRunning else { return }

        let now = Date()
        let session = TimeSession(startAt: now, source: .liveTimer, workTask: nil)
        context.insert(session)
        try? context.save()

        activeSession = session
        elapsedSeconds = 0
        accumulatedPausedSeconds = 0
        pauseStart = nil
        countdownTarget = countdownSeconds
        countdownCompleted = false
        isRunning = true
        isPaused = false

        writeSentinel(taskId: UUID(), taskTitle: "Unbound", startAt: now)
        startTicker()

        if systemIntegrationsEnabled {
            FocusNotificationScheduler.requestAuthorizationIfNeeded()
            FocusNotificationScheduler.schedule(
                taskTitle: "",
                countdownSeconds: countdownSeconds,
                reminderIntervalMinutes: reminderIntervalMinutesPreference
            )
            startLiveActivity(
                sessionId: session.id,
                task: nil,
                startAt: now,
                countdownSeconds: countdownSeconds,
                todayTotalSeconds: 0
            )
        }
        WidgetSnapshotBuilder.publish(in: context, timerService: self)
    }

    func pause() {
        guard isRunning, !isPaused else { return }
        ticker?.invalidate()
        ticker = nil
        pauseStart = Date()
        isPaused = true

        // Cancel pending notifications — we'll reschedule on resume with the
        // post-pause anchor so reminder cadence remains correct.
        if systemIntegrationsEnabled {
            FocusNotificationScheduler.cancelAll()
            updateLiveActivityState()
        }
    }

    func resume() {
        guard isRunning, isPaused else { return }
        if let ps = pauseStart {
            accumulatedPausedSeconds += Int(Date().timeIntervalSince(ps))
        }
        pauseStart = nil
        isPaused = false
        startTicker()

        if systemIntegrationsEnabled {
            FocusNotificationScheduler.schedule(
                taskTitle: liveActivityTaskTitle(for: activeSession?.workTask),
                countdownSeconds: countdownTarget,
                reminderIntervalMinutes: reminderIntervalMinutesPreference,
                elapsedSecondsAtStart: elapsedSeconds
            )
            updateLiveActivityState()
        }
    }

    func extendCountdown(by seconds: Int) {
        guard isRunning, let target = countdownTarget else { return }
        countdownTarget = target + max(1, seconds)
        countdownCompleted = false

        if !isPaused, ticker == nil {
            startTicker()
        }

        if systemIntegrationsEnabled {
            FocusNotificationScheduler.schedule(
                taskTitle: liveActivityTaskTitle(for: activeSession?.workTask),
                countdownSeconds: countdownTarget,
                reminderIntervalMinutes: reminderIntervalMinutesPreference,
                elapsedSecondsAtStart: elapsedSeconds
            )
            updateLiveActivityState()
        }
    }

    func continueCountdownAsStopwatch() {
        guard isRunning, countdownTarget != nil else { return }
        countdownTarget = nil
        countdownCompleted = false
        if elapsedSeconds >= 3300 {
            stopwatchCapHours = 24
        }

        if systemIntegrationsEnabled {
            FocusNotificationScheduler.schedule(
                taskTitle: liveActivityTaskTitle(for: activeSession?.workTask),
                countdownSeconds: nil,
                reminderIntervalMinutes: reminderIntervalMinutesPreference,
                elapsedSecondsAtStart: elapsedSeconds
            )
            updateLiveActivityState()
        }
    }

    func stop(in context: ModelContext) {
        guard isRunning, let session = activeSession else { return }

        ticker?.invalidate()
        ticker = nil

        let now = Date()

        // Finalise pause accounting
        if isPaused, let ps = pauseStart {
            accumulatedPausedSeconds += Int(now.timeIntervalSince(ps))
        }
        session.totalPausedSeconds = accumulatedPausedSeconds

        // Cross-day split (RESOLVED-3)
        let cal = Calendar.current
        let startDay = cal.startOfDay(for: session.startAt)
        let endDay   = cal.startOfDay(for: now)

        if startDay < endDay {
            // Session crosses midnight — split into two records
            let midnight = cal.date(byAdding: .day, value: 1, to: startDay)!
            session.endAt = midnight

            let tail = TimeSession(
                startAt: midnight,
                endAt: now,
                totalPausedSeconds: 0,   // pauses attributed to the first segment
                source: session.source,
                workTask: session.workTask
            )
            context.insert(tail)
        } else {
            session.endAt = now
        }

        try? context.save()
        clearState()
        clearSentinel()

        if systemIntegrationsEnabled {
            FocusNotificationScheduler.cancelAll()
            endLiveActivity()
        }
        WidgetSnapshotBuilder.publish(in: context, timerService: self)
    }

    // MARK: Kill Recovery

    var killRecoverySentinel: ActiveSessionSentinel? {
        guard let data = UserDefaults.standard.data(forKey: Self.sentinelKey) else { return nil }
        return try? JSONDecoder().decode(ActiveSessionSentinel.self, from: data)
    }

    /// Save with estimated end = now and clear the sentinel.
    func recoverSession(for sentinel: ActiveSessionSentinel, in context: ModelContext) {
        let descriptor = FetchDescriptor<WorkTask>(
            predicate: #Predicate { $0.id == sentinel.taskId }
        )
        let task = (try? context.fetch(descriptor))?.first

        let session = TimeSession(
            startAt: sentinel.startAt,
            endAt: Date(),
            source: .liveTimer,
            workTask: task
        )
        context.insert(session)
        try? context.save()
        clearSentinel()

        if systemIntegrationsEnabled {
            FocusNotificationScheduler.cancelAll()
            endAllOrphanedActivities()
        }
    }

    /// Resume the session that was running before the app got killed. Reuses
    /// the orphan TimeSession (endAt == nil) when present, or recreates one at
    /// the sentinel's startAt if the row is missing. The TimerService transitions
    /// back to `running` — ticker, Live Activity, and widget snapshot all
    /// re-engage. The sentinel stays so a second kill is still recoverable.
    ///
    /// Caveat: a countdown that was running pre-kill drops back to stopwatch
    /// mode here — we don't persist countdown target, and after a kill there's
    /// no reliable "remaining seconds" to resume against.
    func continueRecoveredSession(for sentinel: ActiveSessionSentinel, in context: ModelContext) {
        guard !isRunning else { return }

        let startAt = sentinel.startAt
        let descriptor = FetchDescriptor<TimeSession>(
            predicate: #Predicate { $0.startAt == startAt && $0.endAt == nil }
        )
        let existing = (try? context.fetch(descriptor))?.first

        let session: TimeSession
        if let existing {
            session = existing
        } else {
            // Orphan row was cleaned up — recreate to anchor the sentinel start.
            let taskDesc = FetchDescriptor<WorkTask>(
                predicate: #Predicate { $0.id == sentinel.taskId }
            )
            let task = (try? context.fetch(taskDesc))?.first
            session = TimeSession(
                startAt: sentinel.startAt,
                source: .liveTimer,
                workTask: task
            )
            context.insert(session)
            try? context.save()
        }

        activeSession = session
        elapsedSeconds = max(0, Int(Date().timeIntervalSince(session.startAt)) - session.totalPausedSeconds)
        accumulatedPausedSeconds = session.totalPausedSeconds
        pauseStart = nil
        countdownTarget = nil
        countdownCompleted = false
        isRunning = true
        isPaused = false
        startTicker()

        if systemIntegrationsEnabled, let task = session.workTask {
            FocusNotificationScheduler.requestAuthorizationIfNeeded()
            FocusNotificationScheduler.schedule(
                taskTitle: liveActivityTaskTitle(for: task),
                countdownSeconds: nil,
                reminderIntervalMinutes: reminderIntervalMinutesPreference,
                elapsedSecondsAtStart: elapsedSeconds
            )
            startLiveActivity(
                sessionId: session.id,
                task: task,
                startAt: session.startAt,
                countdownSeconds: nil,
                todayTotalSeconds: todayTotalSeconds(for: task, in: context)
            )
        }
        WidgetSnapshotBuilder.publish(in: context, timerService: self)
        // Sentinel deliberately retained — survives a second kill.
    }

    func discardKillRecovery() {
        clearSentinel()
        if systemIntegrationsEnabled {
            FocusNotificationScheduler.cancelAll()
            endAllOrphanedActivities()
        }
    }

    // MARK: Helpers

    private func startTicker() {
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let session = self.activeSession, !self.isPaused else { return }
            let prev = self.elapsedSeconds
            self.elapsedSeconds = max(0, Int(Date().timeIntervalSince(session.startAt)) - self.accumulatedPausedSeconds)

            // Foreground-only: when a countdown hits zero, fire a Live Activity
            // alert update so the island expands with sound. Background path
            // is covered by the scheduled local notification.
            if let target = self.countdownTarget,
               prev < target,
               self.elapsedSeconds >= target {
                self.fireCountdownCompleteAlert()
            }

            // Stopwatch only: at 55 minutes, extend the cap from 1h → 24h so
            // expanded/lock-screen text can render H:MM:SS for long sessions.
            // The compact pill is held narrow by an explicit frame width on
            // the widget side (FocusActivityWidget.compactTrailing), so this
            // cap bump no longer crowds the status bar.
            if self.countdownTarget == nil,
               self.stopwatchCapHours == 1,
               prev < 3300,
               self.elapsedSeconds >= 3300 {
                self.stopwatchCapHours = 24
                self.updateLiveActivityState()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        ticker = t
    }

    private func fireCountdownCompleteAlert() {
        countdownCompleted = true
        guard let activity = liveActivity, let session = activeSession else { return }
        let task = session.workTask
        let tag = task?.tag
        let state = FocusActivityAttributes.ContentState(
            emoji: liveActivityEmoji(for: task),
            tagName: tag?.name ?? "Untagged",
            tagColorToken: tag?.colorToken ?? "gray",
            taskTitle: liveActivityTaskTitle(for: task),
            startAt: session.startAt,
            pausedSeconds: accumulatedPausedSeconds,
            isPaused: isPaused,
            countdownSeconds: countdownTarget,
            countdownFinished: true,
            todayTotalSeconds: activity.content.state.todayTotalSeconds,
            stopwatchCapHours: stopwatchCapHours
        )
        let alert = AlertConfiguration(
            title: "时间到",
            body: LocalizedStringResource(stringLiteral: task?.title ?? "Countdown finished"),
            sound: .default
        )
        Task {
            await activity.update(
                ActivityContent(state: state, staleDate: nil),
                alertConfiguration: alert
            )
        }
    }

    private func clearState() {
        isRunning = false
        isPaused = false
        elapsedSeconds = 0
        activeSession = nil
        accumulatedPausedSeconds = 0
        pauseStart = nil
        countdownTarget = nil
        countdownCompleted = false
    }

    private func writeSentinel(taskId: UUID, taskTitle: String, startAt: Date) {
        let s = ActiveSessionSentinel(taskId: taskId, taskTitle: taskTitle, startAt: startAt)
        if let data = try? JSONEncoder().encode(s) {
            UserDefaults.standard.set(data, forKey: Self.sentinelKey)
        }
    }

    private func clearSentinel() {
        UserDefaults.standard.removeObject(forKey: Self.sentinelKey)
    }

    private var reminderIntervalMinutesPreference: Int {
        // 0 = off, default to 60 if unset.
        let stored = UserDefaults.standard.object(forKey: Self.reminderIntervalKey) as? Int
        return stored ?? 60
    }

    /// Sum of completed sessions' effective duration for `task` since 00:00 today.
    /// Used to seed the expanded-island "Today" stat.
    private func todayTotalSeconds(for task: WorkTask, in context: ModelContext) -> Int {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let taskId = task.id
        let descriptor = FetchDescriptor<TimeSession>(
            predicate: #Predicate { s in
                s.endAt != nil
                && s.startAt >= startOfDay
                && s.workTask?.id == taskId
            }
        )
        guard let sessions = try? context.fetch(descriptor) else { return 0 }
        return sessions.reduce(0) { acc, s in
            guard let end = s.endAt else { return acc }
            let raw = Int(end.timeIntervalSince(s.startAt)) - s.totalPausedSeconds
            return acc + max(0, raw)
        }
    }

    // MARK: - Live Activity

    private var dynamicIslandEnabledPreference: Bool {
        // Default to true if user hasn't toggled the setting yet.
        let v = UserDefaults.standard.object(forKey: Self.dynamicIslandEnabledKey) as? Bool
        return v ?? true
    }

    private var showTaskEmojiPreference: Bool {
        let v = UserDefaults.standard.object(forKey: Self.showTaskEmojiKey) as? Bool
        return v ?? true
    }

    private func startLiveActivity(
        sessionId: UUID,
        task: WorkTask?,
        startAt: Date,
        countdownSeconds: Int?,
        todayTotalSeconds: Int
    ) {
        guard dynamicIslandEnabledPreference else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        stopwatchCapHours = 1   // start tight (M:SS); extend at 55-min mark

        let tag = task?.tag
        let state = FocusActivityAttributes.ContentState(
            emoji: liveActivityEmoji(for: task),
            tagName: tag?.name ?? "Untagged",
            tagColorToken: tag?.colorToken ?? "gray",
            taskTitle: liveActivityTaskTitle(for: task),
            startAt: startAt,
            pausedSeconds: 0,
            isPaused: false,
            countdownSeconds: countdownSeconds,
            countdownFinished: false,
            todayTotalSeconds: todayTotalSeconds,
            stopwatchCapHours: stopwatchCapHours
        )
        let attributes = FocusActivityAttributes(sessionId: sessionId)
        do {
            liveActivity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            // Live Activity request can fail (e.g. user disabled them) — we
            // fail silently; the in-app timer + local notifications still work.
            liveActivity = nil
        }
    }

    private func updateLiveActivityState() {
        guard let activity = liveActivity, let session = activeSession else { return }
        let task = session.workTask
        let tag = task?.tag
        let state = FocusActivityAttributes.ContentState(
            emoji: liveActivityEmoji(for: task),
            tagName: tag?.name ?? "Untagged",
            tagColorToken: tag?.colorToken ?? "gray",
            taskTitle: liveActivityTaskTitle(for: task),
            startAt: session.startAt,
            pausedSeconds: accumulatedPausedSeconds,
            isPaused: isPaused,
            countdownSeconds: countdownTarget,
            countdownFinished: countdownCompleted,
            todayTotalSeconds: activity.content.state.todayTotalSeconds,
            stopwatchCapHours: stopwatchCapHours
        )
        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    private func liveActivityEmoji(for task: WorkTask?) -> String {
        guard showTaskEmojiPreference, let task else { return "" }
        return task.titleEmojiPrefix
    }

    /// The badge already carries the emoji (or the ⏱ fallback when the
    /// preference is off), so the title text should never repeat it.
    private func liveActivityTaskTitle(for task: WorkTask?) -> String {
        task?.titleWithoutEmoji ?? ""
    }

    private func endLiveActivity() {
        let activity = liveActivity
        liveActivity = nil
        guard let activity else { return }
        Task {
            await activity.end(activity.content, dismissalPolicy: .immediate)
        }
    }

    /// Walk every running activity and end it. Used during kill recovery so
    /// stale islands from a previous app launch don't linger.
    private func endAllOrphanedActivities() {
        for activity in Activity<FocusActivityAttributes>.activities {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        liveActivity = nil
    }
}

