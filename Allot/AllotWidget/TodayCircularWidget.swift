//
//  TodayCircularWidget.swift
//  AllotWidget
//
//  Lock Screen circular — today's total at the center, top-tag arc as the
//  outer ring. Render body lives in shared TodayCircularContent.

import SwiftUI
import WidgetKit

struct TodayCircularWidget: Widget {
    let kind = "TodayCircularWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            TodayCircularEntry(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Today")
        .description("Today's tracked time as a glanceable ring.")
        .supportedFamilies([.accessoryCircular])
    }
}

private struct TodayCircularEntry: View {
    let entry: SnapshotEntry

    var body: some View {
        TodayCircularContent(snapshot: entry.snapshot, prefs: entry.prefs)
            .widgetURL(URL(string: "allot://allotted"))
    }
}
