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

    // MARK: Private

    private var ticker: Timer?
    private var pauseStart: Date?
    private var accumulatedPausedSeconds = 0

    private static let sentinelKey = "activeSession"

    // MARK: Controls

    func start(task: WorkTask, in context: ModelContext) {
        guard !isRunning else { return }

        let now = Date()
        let session = TimeSession(startAt: now, source: .liveTimer, workTask: task)
        context.insert(session)
        try? context.save()

        activeSession = session
        elapsedSeconds = 0
        accumulatedPausedSeconds = 0
        pauseStart = nil
        isRunning = true
        isPaused = false

        writeSentinel(taskId: task.id, taskTitle: task.title, startAt: now)
        startTicker()
    }

    func startUnbound(in context: ModelContext) {
        guard !isRunning else { return }

        let now = Date()
        let session = TimeSession(startAt: now, source: .liveTimer, workTask: nil)
        context.insert(session)
        try? context.save()

        activeSession = session
        elapsedSeconds = 0
        accumulatedPausedSeconds = 0
        pauseStart = nil
        isRunning = true
        isPaused = false

        writeSentinel(taskId: UUID(), taskTitle: "Unbound", startAt: now)
        startTicker()
    }

    func pause() {
        guard isRunning, !isPaused else { return }
        ticker?.invalidate()
        ticker = nil
        pauseStart = Date()
        isPaused = true
    }

    func resume() {
        guard isRunning, isPaused else { return }
        if let ps = pauseStart {
            accumulatedPausedSeconds += Int(Date().timeIntervalSince(ps))
        }
        pauseStart = nil
        isPaused = false
        startTicker()
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
    }

    func discardKillRecovery() {
        clearSentinel()
    }

    // MARK: Helpers

    private func startTicker() {
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let session = self.activeSession, !self.isPaused else { return }
            self.elapsedSeconds = max(0, Int(Date().timeIntervalSince(session.startAt)) - self.accumulatedPausedSeconds)
        }
        RunLoop.main.add(t, forMode: .common)
        ticker = t
    }

    private func clearState() {
        isRunning = false
        isPaused = false
        elapsedSeconds = 0
        activeSession = nil
        accumulatedPausedSeconds = 0
        pauseStart = nil
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
}
