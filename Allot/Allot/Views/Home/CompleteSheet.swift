//
//  CompleteSheet.swift
//  Allot
//
//  Shown when user taps the icon on a task row.
//
//  Behaviour: every tap is additive. As long as the task is not yet completed
//  the user can keep adding sessions one after another. Each duration chip ➜
//  preview ➜ Save (just records) or Complete (records + ticks the task done).
//
//  Existing sessions for the day are listed at the bottom. Tapping a row opens
//  an edit sheet where both the start time AND the duration can be adjusted.
//
//  Top-level layout (always):
//    1. Big title header (task title + date)
//    2. If there are sessions today  → "Logged today: Xm" total line
//    3. "Add session" duration chips
//    4. Custom… / Mark done only secondary actions
//    5. Today's sessions list (tappable rows)
//
//  When a chip is tapped we swap the chip area for a preview card with
//  Save / Complete / Back; the bottom session list stays visible.

import SwiftUI
import SwiftData

struct CompleteSheet: View {
    let task: WorkTask
    let date: Date

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @AppStorage("showTaskEmoji") private var showTaskEmoji = true

    @State private var showCustom: Bool = false
    /// When non-nil, we are in the "preview a new session" state — chip has
    /// been picked, user hasn't committed Save vs Complete yet.
    @State private var pendingSeconds: Int? = nil
    /// When set, opens the session-edit sheet (start time + duration).
    @State private var editingSession: TimeSession? = nil
    /// When set, the alert asks the user to confirm deletion of this session.
    @State private var sessionPendingDelete: TimeSession? = nil

    private var existing: Int { task.workedSeconds(on: date) }

    /// All sessions on `date`, ordered by start time.
    private var todaysSessions: [TimeSession] {
        let cal = Calendar.current
        return (task.sessions ?? [])
            .filter { cal.isDate($0.startAt, inSameDayAs: date) }
            .sorted { $0.startAt < $1.startAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 20)
                .padding(.horizontal, 20)

            if let pending = pendingSeconds {
                previewBody(seconds: pending)
            } else {
                addSessionBody
            }

            todaysSessionsList
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Color.bgElevated)
        .sheet(isPresented: $showCustom) {
            CustomMinutesSheet(initial: 30) { minutes in
                pendingSeconds = minutes * 60
            }
            .presentationDetents([.height(320)])
            .presentationBackground(Color.black)
        }
        .sheet(item: $editingSession) { session in
            EditSessionSheet(session: session) {
                try? modelContext.save()
            }
            .presentationDetents([.height(440)])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.bgElevated)
        }
        .alert(
            deletePromptTitle,
            isPresented: Binding(
                get: { sessionPendingDelete != nil },
                set: { if !$0 { sessionPendingDelete = nil } }
            ),
            presenting: sessionPendingDelete
        ) { session in
            Button("Cancel", role: .cancel) { sessionPendingDelete = nil }
            Button("Delete", role: .destructive) { performDelete(session) }
        } message: { _ in
            Text("This session will be removed from today's records.")
        }
    }

    private var deletePromptTitle: String {
        guard let s = sessionPendingDelete, let end = s.endAt else {
            return "Delete session?"
        }
        let dur = max(0, Int(end.timeIntervalSince(s.startAt)) - s.totalPausedSeconds)
        return "Delete \(formatDuration(dur)) session?"
    }

    private func performDelete(_ session: TimeSession) {
        modelContext.delete(session)
        try? modelContext.save()
        sessionPendingDelete = nil
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            if let tag = task.tag, !tag.isSystem {
                TagDot(color: Color.tagColor(tag.colorToken), style: .filled, size: 10)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.displayTitle(showEmoji: showTaskEmoji))
                    .font(.system(size: 24, weight: .bold))
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

    // MARK: Add-session body (chip picker)

    private var addSessionBody: some View {
        VStack(spacing: 0) {
            if existing > 0 {
                HStack(spacing: 6) {
                    Text("Logged today")
                        .font(.system(size: 12, weight: .medium))
                        .kerning(0.5)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.textTertiary)
                    Spacer()
                    Text(formatDuration(existing))
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.textPrimary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 4)
            }

            Text("Add a session")
                .font(.system(size: 12, weight: .medium))
                .kerning(0.5)
                .textCase(.uppercase)
                .foregroundStyle(Color.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 10)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 8
            ) {
                ForEach([15, 25, 30, 45, 60, 90], id: \.self) { m in
                    DurationChip(minutes: m) {
                        pendingSeconds = m * 60
                    }
                }
            }
            .padding(.horizontal, 20)

            HStack(spacing: 8) {
                GhostButton(title: "Custom…") { showCustom = true }
                GhostButton(title: "Mark done only") { markCompletedOnly() }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 18)
        }
    }

    // MARK: Preview body — duration picked, ask Save vs Complete

    private func previewBody(seconds: Int) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("New session")
                    .font(.system(size: 12, weight: .medium))
                    .kerning(0.5)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.textTertiary)

                Text(formatDuration(seconds))
                    .font(.system(size: 44, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .background(Color.bgSecondary, in: RoundedRectangle(cornerRadius: Radius.lg))
            .padding(.horizontal, 20)
            .padding(.top, 18)

            HStack(spacing: 8) {
                GhostButton(title: "Save")     { logManual(seconds: seconds, alsoComplete: false) }
                PrimaryButton(title: "Complete") { logManual(seconds: seconds, alsoComplete: true)  }
            }
            .padding(.top, 14)
            .padding(.horizontal, 20)

            GhostButton(title: "Back") { pendingSeconds = nil }
                .padding(.top, 8)
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
        }
    }

    // MARK: Today's sessions list

    @ViewBuilder
    private var todaysSessionsList: some View {
        let sessions = todaysSessions
        if !sessions.isEmpty {
            VStack(spacing: 0) {
                Divider()
                    .padding(.horizontal, 20)

                Text("Today's sessions")
                    .font(.system(size: 12, weight: .medium))
                    .kerning(0.5)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 4)

                // List is required for native .swipeActions. .plain style +
                // hidden separators + clear background keep the visual close
                // to the original rounded-card rows.
                List {
                    ForEach(sessions, id: \.id) { session in
                        SessionRow(session: session) {
                            editingSession = session
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 3, leading: 20, bottom: 3, trailing: 20))
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                sessionPendingDelete = session
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .padding(.bottom, 6)
            }
        }
    }

    // MARK: Actions

    private func markCompletedOnly() {
        task.markCompleted(on: date)
        try? modelContext.save()
        dismiss()
    }

    /// Append a new session with the given duration. Never replaces existing
    /// sessions — the user manages those individually via the list at the
    /// bottom. Start defaults to start-of-day; user can adjust per-session.
    private func logManual(seconds: Int, alsoComplete: Bool) {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: date)
        let session = TimeSession(
            startAt: startOfDay,
            endAt: startOfDay.addingTimeInterval(TimeInterval(seconds)),
            source: .manualEntry,
            workTask: task
        )
        modelContext.insert(session)
        if alsoComplete {
            task.markCompleted(on: date)
        }
        try? modelContext.save()
        if alsoComplete {
            dismiss()
        } else {
            // After Save, return to the chip picker so the user can keep
            // stacking sessions without reopening the sheet.
            pendingSeconds = nil
        }
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
        self._minutes = State(initialValue: max(5, (initial / 5) * 5))
    }

    var body: some View {
        // Black/red-line ruler (HorizontalSliderView .duration) — consistent
        // with StopConfirmView's Edit duration picker. Drag the ruler under
        // the fixed center red line to set the minutes.
        HorizontalSliderView(
            mode: .duration,
            title: "Custom duration",
            valueMinutes: $minutes,
            onDismiss: {
                onConfirm(minutes)
                dismiss()
            }
        )
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

// MARK: Session row + edit sheet

private struct SessionRow: View {
    let session: TimeSession
    let onTap: () -> Void

    private var duration: Int {
        guard let end = session.endAt else { return 0 }
        return max(0, Int(end.timeIntervalSince(session.startAt)) - session.totalPausedSeconds)
    }

    /// True when startAt sits at the start of its day → manual-entry sentinel,
    /// shown as "Set time" rather than "00:00".
    private var hasUserSetTime: Bool {
        let cal = Calendar.current
        return session.startAt != cal.startOfDay(for: session.startAt)
    }

    private var timeRangeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        if let end = session.endAt {
            return "\(f.string(from: session.startAt))–\(f.string(from: end))"
        }
        return f.string(from: session.startAt)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Text(formatDuration(duration))
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)

                Spacer(minLength: 8)

                if hasUserSetTime {
                    Text(timeRangeString)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color.textSecondary)
                } else {
                    Text("Set time")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textQuaternary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.bgSecondary, in: RoundedRectangle(cornerRadius: Radius.md))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Edits both the start time AND the duration of a session. Native iOS
/// time picker for the start, ± stepper for the duration in minutes.
private struct EditSessionSheet: View {
    @Bindable var session: TimeSession
    let onSave: () -> Void

    @Environment(\.dismiss)      private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var startAt: Date
    @State private var minutes: Int

    init(session: TimeSession, onSave: @escaping () -> Void) {
        self.session = session
        self.onSave = onSave
        self._startAt = State(initialValue: session.startAt)
        if let end = session.endAt {
            let dur = max(0, Int(end.timeIntervalSince(session.startAt)) - session.totalPausedSeconds)
            self._minutes = State(initialValue: max(1, dur / 60))
        } else {
            self._minutes = State(initialValue: 25)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Start time row
            VStack(alignment: .leading, spacing: 6) {
                Text("Start time")
                    .font(.system(size: 12, weight: .medium))
                    .kerning(0.5)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.textTertiary)

                DatePicker(
                    "Start",
                    selection: $startAt,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
                .labelsHidden()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 22)

            // Duration row — ± buttons, minute granularity.
            VStack(alignment: .leading, spacing: 6) {
                Text("Duration")
                    .font(.system(size: 12, weight: .medium))
                    .kerning(0.5)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.textTertiary)

                HStack(spacing: 12) {
                    Button { minutes = max(1, minutes - 5) } label: {
                        stepButton("−")
                    }
                    .buttonStyle(.plain)

                    Text("\(minutes) min")
                        .font(.system(size: 22, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.textPrimary)
                        .frame(maxWidth: .infinity)

                    Button { minutes = min(600, minutes + 5) } label: {
                        stepButton("+")
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheetChrome(
            title: "Edit session",
            leading: SheetAction(label: "Cancel") { dismiss() },
            trailing: SheetAction(label: "Save") {
                apply()
                dismiss()
            }
        )
    }

    private func stepButton(_ glyph: String) -> some View {
        Text(glyph)
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(Color.textPrimary)
            .frame(width: 46, height: 46)
            .background(Color.bgSecondary, in: RoundedRectangle(cornerRadius: Radius.md))
    }

    private func apply() {
        // Keep startAt on the same calendar day as the original session,
        // overriding only the hour/minute the user picked.
        let cal = Calendar.current
        let originalDay = cal.startOfDay(for: session.startAt)
        let comps = cal.dateComponents([.hour, .minute], from: startAt)
        let newStart = cal.date(
            byAdding: .minute,
            value: (comps.hour ?? 0) * 60 + (comps.minute ?? 0),
            to: originalDay
        ) ?? session.startAt

        session.startAt = newStart
        session.endAt   = newStart.addingTimeInterval(TimeInterval(minutes * 60))
        // Pause time is no longer meaningful on a manually edited session.
        session.totalPausedSeconds = 0
        onSave()
    }
}
