//
//  WidgetCustomizationView.swift
//  Allot
//
//  Per-widget customization form. Each change is written to App Group
//  immediately and triggers WidgetCenter.reloadAllTimelines() so the user
//  sees the result on Home / Lock screen the moment they leave Settings.

import SwiftData
import SwiftUI
import WidgetKit

struct WidgetCustomizationView: View {
    let kind: WidgetKind

    /// Bound to WidgetGalleryView so the gallery summary cards refresh while
    /// you tweak. The on-disk publish happens in `commit()` below.
    @Binding var prefs: WidgetPreferences

    @Environment(\.dismiss) private var dismiss

    /// Real snapshot if available (so users see THEIR data in the preview);
    /// fall back to placeholder when there's nothing tracked yet.
    private var previewSnapshot: WidgetSnapshot {
        let s = WidgetSnapshot.load()
        // .empty has updatedAt = .distantPast — quick way to detect "no data"
        return s.updatedAt == .distantPast ? .placeholder : s
    }

    var body: some View {
        Form {
            Section {
                previewBlock
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .frame(maxWidth: .infinity)
            }

            switch kind {
            case .liveFocus:     liveFocusSection
            case .todayAllotted: todayAllottedSection
            case .todayCircular: todayCircularSection
            case .focusInline:   focusInlineSection
            case .quickStart:    quickStartSection
            }

            Section {
                Button {
                    resetToDefaults()
                } label: {
                    Label("Reset to defaults", systemImage: "arrow.counterclockwise")
                        .foregroundStyle(Color.textSecondary)
                }
            } footer: {
                Text("Changes apply to your widgets immediately.")
                    .font(.system(size: 12))
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: prefs) { _, _ in commit() }
        .sheet(isPresented: $showTaskPicker) {
            PinnedTaskPickerSheet(pinnedTaskIds: $prefs.quickStart.pinnedTaskIds)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Live preview (top of page)

    @ViewBuilder
    private var previewBlock: some View {
        let snapshot = previewSnapshot

        switch kind {
        case .liveFocus:
            VStack(spacing: 12) {
                WidgetPreviewCard(label: "Home small", width: 170, height: 170) {
                    LiveFocusContent(snapshot: snapshot, prefs: prefs, family: .systemSmall)
                }
                WidgetPreviewCard(label: "Lock screen", width: 160, height: 72) {
                    LiveFocusContent(snapshot: snapshot, prefs: prefs, family: .accessoryRectangular)
                }
            }
        case .todayAllotted:
            WidgetPreviewCard(label: "Home medium", width: 338, height: 158) {
                TodayAllottedContent(snapshot: snapshot, prefs: prefs)
            }
        case .todayCircular:
            WidgetPreviewCard(label: "Lock screen circular", width: 72, height: 72) {
                TodayCircularContent(snapshot: snapshot, prefs: prefs)
            }
        case .focusInline:
            WidgetPreviewCard(label: "Lock screen inline", width: 280, height: 28) {
                FocusInlineContent(snapshot: snapshot, prefs: prefs)
            }
        case .quickStart:
            WidgetPreviewCard(label: "Home small", width: 170, height: 170) {
                QuickStartContent(snapshot: snapshot, prefs: prefs, interactive: false)
            }
        }
    }

    // MARK: - Per-widget sections

    @ViewBuilder
    private var liveFocusSection: some View {
        Section {
            Toggle("Hide when idle", isOn: $prefs.liveFocus.hideWhenIdle)
                .tint(Color.accentPrimary)
        } footer: {
            Text("When you're not focusing on anything, the widget renders empty so it visually fades out of your home / lock screen.")
        }
    }

    @ViewBuilder
    private var todayAllottedSection: some View {
        Section("Range") {
            Picker("Range", selection: $prefs.todayAllotted.range) {
                ForEach(WidgetPreferences.AllottedRange.allCases, id: \.self) { r in
                    Text(r.displayName).tag(r)
                }
            }
            .pickerStyle(.segmented)
        }

        Section("View") {
            Picker("View", selection: $prefs.todayAllotted.view) {
                ForEach(WidgetPreferences.AllottedView.allCases, id: \.self) { v in
                    Text(v.displayName).tag(v)
                }
            }
            .pickerStyle(.segmented)
        }

        Section {
            Stepper(
                value: $prefs.todayAllotted.bucketCount,
                in: 3...5,
                step: 1
            ) {
                HStack {
                    Text("Show top")
                    Spacer()
                    Text("\(prefs.todayAllotted.bucketCount)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(Color.textSecondary)
                }
            }
        } header: {
            Text("Buckets")
        } footer: {
            Text("Anything past the cap merges into a gray \"Others\" bucket.")
        }
    }

    @ViewBuilder
    private var todayCircularSection: some View {
        Section {
            Picker("Center", selection: $prefs.todayCircular.center) {
                ForEach(WidgetPreferences.CircularCenter.allCases, id: \.self) { c in
                    Text(c.displayName).tag(c)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        } header: {
            Text("Center display")
        } footer: {
            Text("The outer ring always shows your top 4 tags by time. Pick what fills the center.")
        }
    }

    @ViewBuilder
    private var focusInlineSection: some View {
        Section {
            Picker("Format", selection: $prefs.focusInline.format) {
                ForEach(WidgetPreferences.InlineFormat.allCases, id: \.self) { f in
                    Text(f.displayName).tag(f)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        } header: {
            Text("Format")
        } footer: {
            Text("Lock-screen inline widgets sit above the clock. Compact saves space; verbose reads like a sentence.")
        }
    }

    // MARK: - Quick Start (with task picker)

    @State private var showTaskPicker = false

    @ViewBuilder
    private var quickStartSection: some View {
        Section {
            Picker("Source", selection: $prefs.quickStart.source) {
                ForEach(WidgetPreferences.QuickStartSource.allCases, id: \.self) { s in
                    Text(s.displayName).tag(s)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        } header: {
            Text("Source")
        } footer: {
            Text("Auto-recent uses the 4 tasks you've tracked most recently. Pinned lets you hand-pick which 4 always show.")
        }

        if prefs.quickStart.source == .pinned {
            Section("Pinned tasks (up to 4)") {
                ForEach(Array(prefs.quickStart.pinnedTaskIds.enumerated()), id: \.offset) { idx, id in
                    PinnedTaskRow(taskId: id) {
                        prefs.quickStart.pinnedTaskIds.removeAll { $0 == id }
                    }
                }
                if prefs.quickStart.pinnedTaskIds.count < 4 {
                    Button {
                        showTaskPicker = true
                    } label: {
                        Label("Add task", systemImage: "plus")
                            .foregroundStyle(Color.textPrimary)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func commit() {
        prefs.publish()
    }

    private func resetToDefaults() {
        switch kind {
        case .liveFocus:     prefs.liveFocus     = .init()
        case .todayAllotted: prefs.todayAllotted = .init()
        case .todayCircular: prefs.todayCircular = .init()
        case .focusInline:   prefs.focusInline   = .init()
        case .quickStart:    prefs.quickStart    = .init()
        }
    }
}

// MARK: - Pinned task row + picker

private struct PinnedTaskRow: View {
    let taskId: UUID
    let onRemove: () -> Void

    @Query private var allTasks: [WorkTask]

    private var task: WorkTask? {
        allTasks.first { $0.id == taskId }
    }

    var body: some View {
        HStack(spacing: 10) {
            if let task {
                if let tag = task.tag, !tag.isSystem {
                    Circle()
                        .fill(Color.tagColor(tag.colorToken))
                        .frame(width: 8, height: 8)
                }
                Text(task.title)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
            } else {
                Text("(deleted task)")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textTertiary)
                    .italic()
            }
            Spacer()
            Button(role: .destructive, action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(Color.stateDestructive.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
    }
}

// Sheet for picking a task to pin. Shown via the parent's `showTaskPicker`
// when source == .pinned and slots are available.
extension WidgetCustomizationView {
    fileprivate struct PinnedTaskPickerSheet: View {
        @Binding var pinnedTaskIds: [UUID]
        @Environment(\.dismiss) private var dismiss

        @Query(sort: \WorkTask.createdAt, order: .reverse) private var allTasks: [WorkTask]

        private var available: [WorkTask] {
            allTasks
                .filter { $0.archivedAt == nil }
                .filter { !pinnedTaskIds.contains($0.id) }
        }

        var body: some View {
            NavigationStack {
                List {
                    ForEach(available, id: \.id) { task in
                        Button {
                            pinnedTaskIds.append(task.id)
                            dismiss()
                        } label: {
                            HStack(spacing: 10) {
                                if let tag = task.tag, !tag.isSystem {
                                    Circle()
                                        .fill(Color.tagColor(tag.colorToken))
                                        .frame(width: 8, height: 8)
                                }
                                Text(task.title)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.textPrimary)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .navigationTitle("Pin a task")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
    }
}
