//
//  FocusInlineWidget.swift
//  AllotWidget
//
//  Lock Screen inline — single text line. Render body lives in shared
//  FocusInlineContent.

import SwiftUI
import WidgetKit

struct FocusInlineWidget: Widget {
    let kind = "FocusInlineWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            FocusInlineEntry(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Focus inline")
        .description("Compact running session indicator.")
        .supportedFamilies([.accessoryInline])
    }
}

private struct FocusInlineEntry: View {
    let entry: SnapshotEntry

    var body: some View {
        FocusInlineContent(snapshot: entry.snapshot, prefs: entry.prefs)
            .widgetURL(URL(string: "allot://focus"))
    }
}
