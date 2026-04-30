//
//  QuickStartContent.swift
//  Allot
//
//  Shared rendering for the Quick Start widget. `interactive` controls
//  whether each cell wraps in a Link for deep-link tap (true on widget,
//  false on Settings preview to avoid the preview tap re-launching the app).

import SwiftUI

struct QuickStartContent: View {
    let snapshot: WidgetSnapshot
    let prefs: WidgetPreferences
    var interactive: Bool = false

    /// Which 4 tasks to show. In `.pinned` mode we honor the user's selection
    /// (looked up by id in snapshot.recentTasks); in `.autoRecent` we just
    /// take the first 4. Pinned ids that no longer match any recent task are
    /// dropped and the slot backfills from recent so the widget never looks
    /// broken.
    private var cells: [WidgetSnapshot.RecentTask] {
        let recent = snapshot.recentTasks
        switch prefs.quickStart.source {
        case .autoRecent:
            return Array(recent.prefix(4))
        case .pinned:
            let byId = Dictionary(uniqueKeysWithValues: recent.map { ($0.id, $0) })
            let pinned = prefs.quickStart.pinnedTaskIds.compactMap { byId[$0] }
            let pinnedIds = Set(pinned.map(\.id))
            let backfill = recent.filter { !pinnedIds.contains($0.id) }
            return Array((pinned + backfill).prefix(4))
        }
    }

    var body: some View {
        let slots = cells
        if slots.isEmpty {
            empty
        } else {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    cell(slots[safe: 0])
                    cell(slots[safe: 1])
                }
                HStack(spacing: 6) {
                    cell(slots[safe: 2])
                    cell(slots[safe: 3])
                }
            }
            .padding(6)
        }
    }

    @ViewBuilder
    private func cell(_ task: WidgetSnapshot.RecentTask?) -> some View {
        if let t = task {
            if interactive {
                Link(destination: URL(string: "allot://focus?start=\(t.id.uuidString)")!) {
                    quickCellContent(t)
                }
            } else {
                quickCellContent(t)
            }
        } else {
            quickCellPlaceholder
        }
    }

    private func quickCellContent(_ t: WidgetSnapshot.RecentTask) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(t.tagEmoji ?? "○")
                    .font(.system(size: 14))
                Spacer()
                Circle()
                    .fill(Color.tagColor(t.tagColorToken))
                    .frame(width: 6, height: 6)
            }
            Spacer(minLength: 0)
            Text(t.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial)
        )
    }

    private var quickCellPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(.thinMaterial)
            .opacity(0.4)
    }

    private var empty: some View {
        VStack(spacing: 6) {
            Image(systemName: "plus.circle")
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
            Text("Add tasks")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension Array {
    fileprivate subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
