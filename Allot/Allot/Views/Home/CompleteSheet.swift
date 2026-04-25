//
//  CompleteSheet.swift
//  Allot
//
//  Shown when user taps the ○ / ☐ icon on a task row.
//  Two paths depending on whether the task already has worked seconds:
//    A. workedSeconds > 0 → "You spent X on [title]. Is this right?" [Confirm] [Adjust]
//    B. workedSeconds == 0 → chip picker (15 / 30 / 45 / 60 / Custom / Don't log)
//
//  Writing the duration creates a manual QuickLog-style TimeSession;
//  confirmation marks the task completed on the given date.

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
            GrabberView()
                .padding(.top, 8)

            // Title
            VStack(spacing: 6) {
                Text(task.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if let tag = task.tag, !tag.isSystem {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.tagColor(tag.colorToken))
                            .frame(width: 6, height: 6)
                        Text(tag.name)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 24)

            if existing > 0 {
                confirmExistingBody
            } else {
                quickPickBody
            }
        }
        .background(Color.bgElevated)
    }

    // MARK: Path A — confirm existing time

    private var confirmExistingBody: some View {
        VStack(spacing: 0) {
            Text("You logged")
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)
                .padding(.top, 24)

            Text(formatDuration(existing))
                .font(.system(size: 44, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
                .padding(.top, 4)

            Text("on this task today — keep it?")
                .font(.system(size: 14))
                .foregroundStyle(Color.textTertiary)
                .padding(.top, 8)

            VStack(spacing: 10) {
                PrimaryButton(title: "Confirm & mark done") {
                    markCompleted()
                }

                GhostButton(title: "Adjust time") {
                    showCustom = true
                }
            }
            .padding(.top, 28)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
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
        VStack(spacing: 16) {
            Text("How long did you spend?")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .padding(.top, 24)

            // Chip grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach([15, 25, 30, 45, 60, 90], id: \.self) { m in
                    DurationChip(minutes: m) {
                        logManual(seconds: m * 60, replacing: false)
                    }
                }
            }
            .padding(.horizontal, 20)

            HStack(spacing: 10) {
                GhostButton(title: "Custom…") { showCustom = true }
                GhostButton(title: "Don't log time") {
                    markCompletedOnly()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
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
                .font(.system(size: 16, weight: .medium, design: .monospaced))
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
            GrabberView().padding(.top, 8)

            Text("Custom duration")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .padding(.top, 16)

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
            .padding(.bottom, 20)
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
                .frame(height: 50)
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
                .frame(height: 44)
                .background(Color.bgSecondary, in: RoundedRectangle(cornerRadius: Radius.md))
        }
        .buttonStyle(.plain)
    }
}
