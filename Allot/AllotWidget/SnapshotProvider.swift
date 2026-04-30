//
//  SnapshotProvider.swift
//  AllotWidget
//
//  Shared TimelineProvider that feeds every widget. Reads the App Group
//  snapshot and produces a single entry — widgets are reloaded explicitly
//  by the main app via WidgetCenter.reloadAllTimelines(), so the timeline
//  stays a one-shot.
//
//  WidgetSnapshot.placeholder lives in Engine/WidgetSnapshot.swift (shared
//  with main app so the Settings preview can use it too).

import WidgetKit
import Foundation

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    let prefs: WidgetPreferences
}

struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: Date(), snapshot: .placeholder, prefs: .default)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        let snap = context.isPreview ? .placeholder : WidgetSnapshot.load()
        let prefs = context.isPreview ? .default : WidgetPreferences.load()
        completion(SnapshotEntry(date: Date(), snapshot: snap, prefs: prefs))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let snap = WidgetSnapshot.load()
        let prefs = WidgetPreferences.load()
        let entry = SnapshotEntry(date: Date(), snapshot: snap, prefs: prefs)
        // Refresh hourly even without explicit reload — covers the case where
        // the main app hasn't run for a while.
        let next = Date().addingTimeInterval(60 * 60)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}
