//
//  CompleteSheet.swift
//  Allot
//
//  Shown when user taps the icon on a task row.
//    A. workedSeconds > 0 → show logged time, confirm or adjust.
//    B. workedSeconds == 0 → quick-pick chips (15/25/30/45/60/90) + custom + skip.

import SwiftUI
import SwiftData

struct CompleteSheet: View {
    let task: WorkTask
    let date: Date

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @State private var customMinutes: Int = 30
    @State private var showCustom: Bool = false

    private var existing: Int { task.workedSeconds(on: date) }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 20)
                .padding(.horizontal, 20)

            if existing > 0 {
                confirmExistingBody
            } else {
                quickPickBody
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Color.bgElevated)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            if let tag = task.tag, !tag.isSystem {
                TagDot(color: Color.tagColor(tag.colorToken), style: .filled, size: 10)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textTertiary)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: Path A — confirm existing time

    private var confirmExistingBody: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("Logged today")
                    .font(.system(size: 12, weight: .medium))
                    .kerning(0.5)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.textTertiary)

                Text(formatDuration(existing))
                    .font(.system(size: 44, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .background(Color.bgSecondary, in: RoundedRectangle(cornerRadius: Radius.lg))
            .padding(.horizontal, 20)
            .padding(.top, 16)

            VStack(spacing: 8) {
                PrimaryButton(title: "Confirm & mark done") { markCompleted() }
                GhostButton(title: "Adjust time")          { showCustom = true }
            }
            .padding(.top, 14)
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
        .sheet(isPresented: $showCustom) {
            CustomMinutesSheet(initial: max(1, existing / 60)) { minutes in
                logManual(seconds: minutes * 60, replacing: true)
            }
            .presentationDetents([.height(320)])
        }
    }

    // MARK: Path B — quick pick

    private var quickPickBody: some View {
        VStack(spacing: 0) {
            Text("How long did you spend?")
                .font(.system(size: 12, weight: .medium))
                .kerning(0.5)
                .textCase(.uppercase)
                .foregroundStyle(Color.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 10)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 8
            ) {
                ForEach([15, 25, 30, 45, 60, 90], id: \.self) { m in
                    DurationChip(minutes: m) {
                        logManual(seconds: m * 60, replacing: false)
                    }
                }
            }
            .padding(.horizontal, 20)

            HStack(spacing: 8) {
                GhostButton(title: "Custom…") { showCustom = true }
                GhostButton(title: "Skip log") { markCompletedOnly() }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 18)
        }
        .sheet(isPresented: $showCustom) {
            CustomMinutesSheet(initial: 30) { minutes in
                logManual(seconds: minutes * 60, replacing: false)
            }
            .presentationDetents([.height(320)])
        }
    }

    // MARK: Actions

    private func markCompleted() {
        task.markCompleted(on: date)
        try? modelContext.save()
        dismiss()
    }

    private func markCompletedOnly() {
        task.markCompleted(on: date)
        try? modelContext.save()
        dismiss()
    }


    private func logManual(seconds: Int, replacing: Bool) {
        let cal = Calendar.current
        if replacing {
            let dayStart = cal.startOfDay(for: date)
            let dayEnd   = cal.date(byAdding: .day, value: 1, to: dayStart)!
            for s in task.sessions where s.startAt >= dayStart && s.startAt < dayEnd {
                modelContext.delete(s)
            }
        }
        let startOfDay = cal.startOfDay(for: date)
        let session = TimeSession(
            startAt: startOfDay,
            endAt: startOfDay.addingTimeInterval(TimeInterval(seconds)),
            source: .manualEntry,
            workTask: task
        )
        modelContext.insert(session)
        task.markCompleted(on: date)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: Chip

private struct DurationChip: View {
    let minutes: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text("\(minutes)m")
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.bgSecondary, in: RoundedRectangle(cornerRadius: Radius.md))
        }
        .buttonStyle(.plain)
    }
}

// MARK: Custom minutes sheet

private struct CustomMinutesSheet: View {
    let initial: Int
    let onConfirm: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var minutes: Int

    init(initial: Int, onConfirm: @escaping (Int) -> Void) {
        self.initial = initial
        self.onConfirm = onConfirm
        self._minutes = State(initialValue: initial)
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Custom duration")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .padding(.top, 24)

            Picker("", selection: $minutes) {
                ForEach(1...600, id: \.self) { m in
                    Text("\(m) min").tag(m)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 160)

            PrimaryButton(title: "Log \(minutes)m") {
                onConfirm(minutes)
                dismiss()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.bgElevated)
    }
}

// MARK: Buttons

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.bgPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.textPrimary, in: RoundedRectangle(cornerRadius: Radius.md))
        }
        .buttonStyle(.plain)
    }
}

struct GhostButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(Color.bgSecondary, in: RoundedRectangle(cornerRadius: Radius.md))
        }
        .buttonStyle(.plain)
    }
}
