//
//  LiveFocusWidget.swift
//  AllotWidget
//
//  Live focus surface — appears on:
//    - Home Screen Small  (.systemSmall)
//    - Lock Screen rect   (.accessoryRectangular)
//
//  Render body lives in shared LiveFocusContent (Views/Components/WidgetPreviews)
//  so the Settings preview uses the exact same rendering code.

import SwiftUI
import WidgetKit

struct LiveFocusWidget: Widget {
    let kind = "LiveFocusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            LiveFocusEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LiveFocusBackground()
                }
        }
        .configurationDisplayName("Focus")
        .description("Your current focus session at a glance.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

private struct LiveFocusBackground: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if family == .accessoryRectangular {
                Color.clear
            } else if colorScheme == .dark {
                Color.black
            } else {
                Rectangle().fill(.regularMaterial)
            }
        }
    }
}

private struct LiveFocusEntryView: View {
    let entry: SnapshotEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        LiveFocusContent(
            snapshot: entry.snapshot,
            prefs: entry.prefs,
            family: family
        )
        .widgetURL(URL(string: "allot://focus"))
    }
}
