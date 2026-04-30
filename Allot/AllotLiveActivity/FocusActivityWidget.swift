//
//  FocusActivityWidget.swift
//  AllotLiveActivity
//
//  Dynamic Island + lock-screen UI for the active focus session.
//
//  Compact (default Dynamic Island state):
//    leading  → stable mode icon
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
            // Lock-screen / banner UI. Pass nil so iOS uses its default
            // translucent glass material in light mode (wallpaper visible
            // through). The view itself paints solid black in dark mode so
            // the result is OLED-friendly there.
            LockScreenView(state: context.state)
                .activityBackgroundTint(nil)
                .activitySystemActionForegroundColor(Color.textPrimary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Text(context.state.emoji.isEmpty ? "⏱" : context.state.emoji)
                            .font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.countdownFinished ? "Time's up" : context.state.tagName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(context.state.countdownFinished ? Color.textPrimary : Color.tagColor(context.state.tagColorToken))
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
                    // Anchored hard to the right edge so the digits sit at
                    // the very far right of the expanded island. `frame
                    // maxWidth: .infinity, alignment: .trailing` overrides
                    // SwiftUI's default fill-and-center for Text(timerInterval:).
                    timerText(for: context.state, big: true)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(context.state.isPaused ? Color.textSecondary : Color.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 6)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        Label(startTimeString(context.state.startAt), systemImage: "play.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.textSecondary)
                        Spacer()
                        if context.state.countdownFinished {
                            Label("Time's up", systemImage: "bell.badge.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.textPrimary)
                        } else if context.state.isPaused {
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
                compactLeading(for: context.state)
            } compactTrailing: {
                // CRITICAL — `Text(timerInterval:)` makes iOS reserve space
                // for the widest possible representation of the range (e.g.
                // "59:59:59" for a 24h cap). On Pro devices that pushes the
                // compact pill wide enough to overlap the status-bar time
                // and signal/battery. Apple's stock Timer uses a private
                // API to dodge this; the public workaround (per Apple Dev
                // Forums #735125 / #723316) is to clamp the trailing view
                // to a fixed width and let `minimumScaleFactor` shrink the
                // digits if a longer format ever lands inside it.
                timerText(for: context.state, big: false)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: 54, alignment: .trailing)
                    .foregroundStyle(context.state.isPaused ? Color.white.opacity(0.6) : Color.white)
            } minimal: {
                if context.state.emoji.isEmpty {
                    compactSystemIcon(for: context.state)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.tagColor(context.state.tagColorToken))
                } else {
                    Text(context.state.emoji)
                        .font(.system(size: 14))
                }
            }
            .keylineTint(Color.tagColor(context.state.tagColorToken))
        }
    }

    /// What the OS shows on the left side of the compact pill. We prefer
    /// the user's task emoji and fall back to a status glyph when no emoji
    /// is set or the user has hidden emoji globally.
    @ViewBuilder
    private func compactLeading(for state: FocusActivityAttributes.ContentState) -> some View {
        if state.emoji.isEmpty {
            compactSystemIcon(for: state)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.tagColor(state.tagColorToken))
                .frame(width: 18, height: 18)
        } else {
            Text(state.emoji)
                .font(.system(size: 16))
                .frame(width: 20, height: 20)
        }
    }

    @ViewBuilder
    private func compactSystemIcon(for state: FocusActivityAttributes.ContentState) -> some View {
        if state.countdownFinished {
            Image(systemName: "bell.fill")
        } else if state.isPaused {
            Image(systemName: "pause.fill")
        } else if state.countdownSeconds != nil {
            Image(systemName: "hourglass")
        } else {
            Image(systemName: "stopwatch")
        }
    }

    /// Builds a `Text(timerInterval:)` whose anchor is shifted so paused time
    /// is excluded. For countdown sessions, we anchor to the projected end so
    /// the OS animates a count-down to 00:00.
    @ViewBuilder
    private func timerText(for state: FocusActivityAttributes.ContentState, big: Bool) -> some View {
        if state.countdownFinished {
            Text("0:00")
        } else if state.isPaused {
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
        // Leave the background to iOS — `activityBackgroundTint(nil)` on the
        // ActivityConfiguration lets the system render its default
        // translucent glass material in both light and dark modes, so the
        // wallpaper shows through and the banner adapts to whatever the
        // lock screen looks like underneath.
        content
    }

    private var content: some View {
        // Single-row layout: ALL meta info on the left, timer pinned hard
        // to the far right edge. This matches the expanded Dynamic Island
        // (leading region carries the meta, trailing region carries the
        // timer), so the lock-screen banner reads consistently with it.
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.tagColor(state.tagColorToken).opacity(0.18))
                    .frame(width: 52, height: 52)
                Text(state.emoji.isEmpty ? "⏱" : state.emoji)
                    .font(.system(size: 28))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(state.countdownFinished ? Color.textPrimary : Color.tagColor(state.tagColorToken))
                        .frame(width: 8, height: 8)
                    Text(state.countdownFinished ? "Time's up" : state.tagName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(state.countdownFinished ? Color.textPrimary : Color.tagColor(state.tagColorToken))
                        .lineLimit(1)
                }
                if !state.taskTitle.isEmpty {
                    Text(state.taskTitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                }
                metaRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            timer
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(state.isPaused ? Color.textSecondary : Color.textPrimary)
                .frame(width: 118, alignment: .trailing)
        }
        .padding(.leading, 16)
        .padding(.trailing, 10)
        .padding(.vertical, 14)
    }

    /// Compact "Started 14:02 · Today 1h 12m · Paused" row that lives
    /// under the title on the left side.
    private var metaRow: some View {
        HStack(spacing: 8) {
            Label(startTimeString(state.startAt), systemImage: "play.circle")
                .labelStyle(.titleAndIcon)
                .font(.system(size: 11))
                .foregroundStyle(Color.textSecondary)

            Text("·")
                .font(.system(size: 11))
                .foregroundStyle(Color.textTertiary)

            Label("Today \(formatDurationCompact(state.todayTotalSeconds))",
                  systemImage: "clock")
                .labelStyle(.titleAndIcon)
                .font(.system(size: 11))
                .foregroundStyle(Color.textSecondary)

            if state.countdownFinished {
                Text("·")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textTertiary)
                Label("Done", systemImage: "bell.badge.fill")
                    .labelStyle(.titleAndIcon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
            } else if state.isPaused {
                Text("·")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textTertiary)
                Label("Paused", systemImage: "pause.fill")
                    .labelStyle(.titleAndIcon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .lineLimit(1)
    }

    private func startTimeString(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: d)
    }

    @ViewBuilder
    private var timer: some View {
        if state.countdownFinished {
            Text("0:00")
        } else if state.isPaused {
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

// MARK: - SwiftUI Previews
//
// Xcode-only previews so the lock-screen banner can be inspected against
// both color schemes and a wallpaper-style background. iOS itself uses a
// `.regularMaterial` glass behind the banner when `activityBackgroundTint`
// is nil — the previews below approximate that material so the visual is
// representative.

private extension FocusActivityAttributes.ContentState {
    static var previewSample: Self {
        .init(
            emoji: "💻",
            tagName: "Work",
            tagColorToken: "sky",
            taskTitle: "Polish Live Activity",
            startAt: Date().addingTimeInterval(-127),
            pausedSeconds: 0,
            isPaused: false,
            countdownSeconds: nil,
            countdownFinished: false,
            todayTotalSeconds: 8_220,
            stopwatchCapHours: 1
        )
    }
}

struct FocusActivityWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZStack {
                // Stand-in for the wallpaper behind the activity banner.
                LinearGradient(
                    colors: [.blue.opacity(0.7), .purple.opacity(0.4), .pink.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 220)

                LockScreenView(state: .previewSample)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .padding(.horizontal, 16)
                    .preferredColorScheme(.light)
            }
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Lock - Light (glass)")

            ZStack {
                Color(white: 0.06)
                    .frame(height: 220)

                LockScreenView(state: .previewSample)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .padding(.horizontal, 16)
                    .preferredColorScheme(.dark)
            }
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Lock - Dark (black)")
        }
    }
}
