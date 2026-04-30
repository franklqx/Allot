//
//  TodayAllottedWidget.swift
//  AllotWidget
//
//  Home Medium — today's (or this week's) distribution as a mini Prism Chart.
//  Render body lives in shared TodayAllottedContent.

import SwiftUI
import WidgetKit

struct TodayAllottedWidget: Widget {
    let kind = "TodayAllottedWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            TodayAllottedEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    TodayBackground()
                }
        }
        .configurationDisplayName("Today")
        .description("How your time is allotted, at a glance.")
        .supportedFamilies([.systemMedium])
    }
}

private struct TodayBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        Group {
            if colorScheme == .dark {
                Color.black
            } else {
                Rectangle().fill(.regularMaterial)
            }
        }
    }
}

private struct TodayAllottedEntryView: View {
    let entry: SnapshotEntry

    var body: some View {
        TodayAllottedContent(snapshot: entry.snapshot, prefs: entry.prefs)
            .widgetURL(URL(string: "allot://allotted"))
    }
}
