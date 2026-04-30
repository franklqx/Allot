//
//  QuickLogSheet.swift
//  Allot
//
//  Horizontal slider for logging duration without a live timer session.
//  Used when completing a task that has no recorded sessions.
//  The custom HorizontalSliderView (Step 5) will replace the system Slider here.

import SwiftUI
import SwiftData

struct QuickLogSheet: View {
    let task: WorkTask
    let date: Date
    /// Called with duration in seconds when the user taps Save.
    let onSave: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedMinutes: Double

    private let step: Double = 5
    private let maxMinutes: Double = 12 * 60

    init(task: WorkTask, date: Date, onSave: @escaping (Int) -> Void) {
        self.task = task
        self.date = date
        self.onSave = onSave
        // Default: last quickLog duration for this task, else 60 min
        let lastDuration = (task.sessions ?? [])
            .filter { $0.source == .quickLog }
            .sorted { ($0.endAt ?? .distantPast) > ($1.endAt ?? .distantPast) }
            .first
            .flatMap { s -> Int? in
                guard let end = s.endAt else { return nil }
                return max(0, Int(end.timeIntervalSince(s.startAt)) - s.totalPausedSeconds)
            }
        _selectedMinutes = State(initialValue: Double((lastDuration ?? 3600) / 60))
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("How long did you work on this?")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .padding(.top, 12)

            Text(formatDuration(Int(selectedMinutes) * 60))
                .font(.system(size: 40, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.accentPrimary)
                .padding(.top, 12)
                .contentTransition(.numericText())

            Slider(value: $selectedMinutes, in: step...maxMinutes, step: step)
                .tint(Color.accentPrimary)
                .padding(.horizontal, 24)
                .padding(.top, 20)

            HStack {
                Text("5m")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
                Spacer()
                Text("12h")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, 28)
            .padding(.top, 4)

            Spacer(minLength: 0)
        }
        .background(Color.bgElevated)
        .sheetChrome(
            title: "Quick log",
            leading: SheetAction(label: "Cancel") { dismiss() },
            trailing: SheetAction(label: "Save") {
                onSave(Int(selectedMinutes) * 60)
                dismiss()
            }
        )
        .presentationDetents([.height(300)])
    }
}
