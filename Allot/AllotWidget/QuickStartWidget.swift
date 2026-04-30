//
//  QuickStartWidget.swift
//  AllotWidget
//
//  Home Small — 2x2 grid of recent tasks. Tap any cell → deep link starts that
//  task. Render body lives in shared QuickStartContent (with interactive: true
//  so cells wrap in Link).

import SwiftUI
import WidgetKit

struct QuickStartWidget: Widget {
    let kind = "QuickStartWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            QuickStartEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    QuickStartBackground()
                }
        }
        .configurationDisplayName("Quick start")
        .description("Tap a recent task to start a session.")
        .supportedFamilies([.systemSmall])
    }
}

private struct QuickStartBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        if colorScheme == .dark {
            Color.black
        } else {
            Rectangle().fill(.regularMaterial)
        }
    }
}

private struct QuickStartEntryView: View {
    let entry: SnapshotEntry

    var body: some View {
        QuickStartContent(
            snapshot: entry.snapshot,
            prefs: entry.prefs,
            interactive: true
        )
    }
}
