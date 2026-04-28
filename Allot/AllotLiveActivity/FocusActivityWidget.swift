//
//  FocusActivityWidget.swift
//  AllotLiveActivity
//
//  Dynamic Island + lock-screen UI for the active focus session.
//
//  Compact (default Dynamic Island state):
//    leading  → tag emoji
//    trailing → live timer (count up or count down) driven entirely by
//               Text(timerInterval:) so the OS animates digits without
//               needing per-second activity updates.
//
//  Expanded (long-press on the island):
//    leading  → emoji + tag chip
//    trailing → big live timer
//    bottom   → task title • "Started 14:02" • "Today 2h 18m"
//
//  Lock screen / banner:
//    full-width row matching the app's design tokens.

import ActivityKit
import SwiftUI
import WidgetKit

struct FocusActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            // Lock-screen / banner UI
            LockScreenView(state: context.state)
                .activityBackgroundTint(Color.bgElevated)
                .activitySystemActionForegroundColor(Color.textPrimary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Text(context.state.emoji.isEmpty ? "⏱" : context.state.emoji)
                            .font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.tagName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.tagColor(context.state.tagColorToken))
                                .lineLimit(1)
                            if !context.state.taskTitle.isEmpty {
                                Text(context.state.taskTitle)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    timerText(for: context.state, big: true)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(context.state.isPaused ? Color.textSecondary : Color.textPrimary)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        Label(startTimeString(context.state.startAt), systemImage: "play.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.textSecondary)
                        Spacer()
                        if context.state.isPaused {
                            Label("Paused", systemImage: "pause.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.textSecondary)
                        }
                        Spacer()
                        Label("Today \(formatDurationCompact(context.state.todayTotalSeconds))",
                              systemImage: "clock")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 2)
                }
            } compactLeading: {
                Text(context.state.emoji.isEmpty ? "⏱" : context.state.emoji)
                    .font(.system(size: 14))
            } compactTrailing: {
                timerText(for: context.state, big: false)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(context.state.isPaused ? Color.textSecondary : Color.textPrimary)
            } minimal: {
                Text(context.state.emoji.isEmpty ? "⏱" : context.state.emoji)
                    .font(.system(size: 14))
            }
            .keylineTint(Color.tagColor(context.state.tagColorToken))
        }
    }

    /// Builds a `Text(timerInterval:)` whose anchor is shifted so paused time
    /// is excluded. For countdown sessions, we anchor to the projected end so
    /// the OS animates a count-down to 00:00.
    @ViewBuilder
    private func timerText(for state: FocusActivityAttributes.ContentState, big: Bool) -> some View {
        if state.isPaused {
            // While paused, freeze on the elapsed-at-pause value.
            let frozen = max(0, Int(Date().timeIntervalSince(state.startAt)) - state.pausedSeconds)
            if let target = state.countdownSeconds {
                Text(formatClock(max(0, target - frozen)))
            } else {
                Text(formatClock(frozen))
            }
        } else if let target = state.countdownSeconds {
            // End anchor = startAt + target + pausedSeconds (so pause shifts the
            // wall-clock end forward by the paused duration).
            let end = state.startAt.addingTimeInterval(TimeInterval(target + state.pausedSeconds))
            Text(timerInterval: Date()...end, countsDown: true)
        } else {
            // Stopwatch: anchor = startAt + pausedSeconds, count up. iOS picks
            // the timer format from the range size — 1h cap → M:SS (tight, like
            // Apple Workout), 24h cap → H:MM:SS. TimerService bumps the cap
            // from 1 → 24 around the 55-minute mark.
            let anchor = state.startAt.addingTimeInterval(TimeInterval(state.pausedSeconds))
            let cap = anchor.addingTimeInterval(TimeInterval(state.stopwatchCapHours * 3600))
            Text(timerInterval: anchor...cap, countsDown: false)
        }
    }

    private func startTimeString(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: d)
    }
}

private struct LockScreenView: View {
    let state: FocusActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.tagColor(state.tagColorToken).opacity(0.18))
                    .frame(width: 52, height: 52)
                Text(state.emoji.isEmpty ? "⏱" : state.emoji)
                    .font(.system(size: 28))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.tagColor(state.tagColorToken))
                        .frame(width: 8, height: 8)
                    Text(state.tagName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.tagColor(state.tagColorToken))
                }
                if !state.taskTitle.isEmpty {
                    Text(state.taskTitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                }
                Text(state.isPaused ? "Paused" : "In progress")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            timer
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(state.isPaused ? Color.textSecondary : Color.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var timer: some View {
        if state.isPaused {
            let frozen = max(0, Int(Date().timeIntervalSince(state.startAt)) - state.pausedSeconds)
            if let target = state.countdownSeconds {
                Text(formatClock(max(0, target - frozen)))
            } else {
                Text(formatClock(frozen))
            }
        } else if let target = state.countdownSeconds {
            let end = state.startAt.addingTimeInterval(TimeInterval(target + state.pausedSeconds))
            Text(timerInterval: Date()...end, countsDown: true)
        } else {
            let anchor = state.startAt.addingTimeInterval(TimeInterval(state.pausedSeconds))
            let cap = anchor.addingTimeInterval(TimeInterval(state.stopwatchCapHours * 3600))
            Text(timerInterval: anchor...cap, countsDown: false)
        }
    }
}
