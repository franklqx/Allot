//
//  LiveFocusContent.swift
//  Allot
//
//  Shared rendering for the Live Focus widget. Used by:
//    - AllotWidget LiveFocusEntryView (production)
//    - WidgetCustomizationView preview (Settings)
//
//  No widget-only modifiers here (widgetURL / containerBackground / Link).
//  Wrappers add those.

import SwiftUI
import WidgetKit

struct LiveFocusContent: View {
    let snapshot: WidgetSnapshot
    let prefs: WidgetPreferences
    let family: WidgetFamily

    private var hideWhenIdle: Bool { prefs.liveFocus.hideWhenIdle }
    private var isIdle: Bool { snapshot.activeSession == nil }

    var body: some View {
        if hideWhenIdle && isIdle {
            // User opted to hide the widget when nothing is running. We render
            // an empty body — the wrapper's containerBackground stays minimal
            // and the widget visually fades out.
            Color.clear
        } else {
            switch family {
            case .accessoryRectangular: lockRectangle
            default:                    homeSmall
            }
        }
    }

    // MARK: Home Small

    @ViewBuilder
    private var homeSmall: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let active = snapshot.activeSession {
                HStack(spacing: 6) {
                    Text(active.tagEmoji ?? "⏱")
                        .font(.system(size: 18))
                    Text("Focus")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Circle()
                        .fill(Color.tagColor(active.tagColorToken))
                        .frame(width: 8, height: 8)
                }
                Spacer(minLength: 0)
                Text(timerInterval: active.anchoredStart...Date(timeIntervalSinceNow: 24 * 3600), countsDown: false)
                    .font(.system(size: 30, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .opacity(active.isPaused ? 0.5 : 1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(active.taskTitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else if let recent = snapshot.recentTasks.first {
                HStack(spacing: 6) {
                    Text(recent.tagEmoji ?? "○")
                        .font(.system(size: 18))
                    Text("Tap to focus")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Spacer(minLength: 0)
                Text("00:00")
                    .font(.system(size: 30, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
                Text(recent.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                emptyState
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
    }

    // MARK: Lock Rectangle

    @ViewBuilder
    private var lockRectangle: some View {
        HStack(spacing: 10) {
            if let active = snapshot.activeSession {
                ZStack {
                    Circle()
                        .fill(Color.tagColor(active.tagColorToken).opacity(0.6))
                        .frame(width: 36, height: 36)
                    Text(active.tagEmoji ?? "⏱")
                        .font(.system(size: 18))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(active.taskTitle)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    Text(timerInterval: active.anchoredStart...Date(timeIntervalSinceNow: 24 * 3600), countsDown: false)
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                }
                Spacer()
            } else {
                Image(systemName: "circle")
                    .font(.system(size: 16))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Allot")
                        .font(.system(size: 13, weight: .medium))
                    Text("Tap to focus")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 8)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: "timer")
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
            Spacer()
            Text("No tasks yet")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}
