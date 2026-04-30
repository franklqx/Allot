//
//  FocusInlineContent.swift
//  Allot
//
//  Shared rendering for the lock-screen inline widget.

import SwiftUI

struct FocusInlineContent: View {
    let snapshot: WidgetSnapshot
    let prefs: WidgetPreferences

    private var format: WidgetPreferences.InlineFormat { prefs.focusInline.format }

    var body: some View {
        if let active = snapshot.activeSession {
            runningView(active: active)
        } else {
            HStack(spacing: 4) {
                Image(systemName: "circle")
                Text("Allot · ready")
            }
        }
    }

    @ViewBuilder
    private func runningView(active: WidgetSnapshot.ActiveSession) -> some View {
        let icon = active.isPaused ? "pause.fill" : "play.fill"
        let timerRange = active.anchoredStart...Date(timeIntervalSinceNow: 24 * 3600)

        switch format {
        case .compact:
            // Original — falls back to timer-only on tight space.
            ViewThatFits {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                    Text(timerInterval: timerRange, countsDown: false)
                    Text("·")
                    Text(active.taskTitle).lineLimit(1)
                }
                HStack(spacing: 4) {
                    Image(systemName: icon)
                    Text(timerInterval: timerRange, countsDown: false)
                }
            }
        case .verbose:
            // "Focusing 1h 23m on Side project" — wordy but unambiguous,
            // collapses to compact on tight space.
            ViewThatFits {
                HStack(spacing: 4) {
                    Text("Focusing")
                    Text(timerInterval: timerRange, countsDown: false)
                    Text("on")
                    Text(active.taskTitle).lineLimit(1)
                }
                HStack(spacing: 4) {
                    Image(systemName: icon)
                    Text(timerInterval: timerRange, countsDown: false)
                    Text("·")
                    Text(active.taskTitle).lineLimit(1)
                }
            }
        case .timerOnly:
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(timerInterval: timerRange, countsDown: false)
            }
        }
    }
}
