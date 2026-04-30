//
//  TaskDaySessionsList.swift
//  Allot
//
//  Lists a task's recorded sessions for a specific day.
//
//  • Live-timer sessions show "HH:mm – HH:mm · duration".
//  • QuickLog sessions (no real start time) sink to the bottom; their left
//    column is rendered blank. Tapping a quickLog row opens a time-of-day
//    slider so the user can backfill a real start time — the duration is
//    preserved and the row promotes into a regular timed session.
//  • Renders an empty-state placeholder when the task has no sessions on the
//    given day.
//

import SwiftUI
import SwiftData

struct TaskDaySessionsList: View {
    let task: WorkTask
    let date: Date
    var sectionTitle: String = "Today"

    @Environment(\.modelContext) private var modelContext
    @State private var editingSession: TimeSession?

    private var sessions: [TimeSession] {
        let cal = Calendar.current
        return (task.sessions ?? [])
            .filter { $0.endAt != nil && cal.isDate($0.startAt, inSameDayAs: date) }
            .sorted { a, b in
                // No-real-time sessions (quickLog / manualEntry) float to the
                // top so the user sees them first; live-timer sessions follow
                // in chronological order.
                let aLive = a.source == .liveTimer
                let bLive = b.source == .liveTimer
                if aLive != bLive { return !aLive }
                return a.startAt < b.startAt
            }
    }

    var body: some View {
        Group {
            if sessions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(sectionTitle)
                        .font(.system(size: 11, weight: .semibold))
                        .kerning(0.4)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.textTertiary)
                    Text("No sessions")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 18)
                        .background(Color.bgSecondary, in: RoundedRectangle(cornerRadius: Radius.md))
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(sectionTitle)
                        .font(.system(size: 11, weight: .semibold))
                        .kerning(0.4)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.textTertiary)

                    VStack(spacing: 0) {
                        ForEach(Array(sessions.enumerated()), id: \.element.id) { idx, session in
                            sessionRow(session)
                            if idx < sessions.count - 1 {
                                Divider().foregroundStyle(Color.textPrimary.opacity(0.06))
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 14)
                    .background(Color.bgSecondary, in: RoundedRectangle(cornerRadius: Radius.md))
                }
            }
        }
        .sheet(item: $editingSession) { session in
            SetStartTimeSheet(
                initialDate: defaultEditDate(for: session)
            ) { picked in
                applyStartTime(to: session, picked: picked)
                editingSession = nil
            }
            .presentationDetents([.height(340)])
            .presentationBackground(Color.bgElevated)
        }
    }

    /// Default time when opening the wheel for an unedited row: 09:00 on the
    /// current `date`. If the session already has a real-time start (rare —
    /// disabled rows can't open this sheet), use it.
    private func defaultEditDate(for session: TimeSession) -> Date {
        let cal = Calendar.current
        if session.source == .liveTimer { return session.startAt }
        let dayStart = cal.startOfDay(for: date)
        return cal.date(byAdding: .hour, value: 9, to: dayStart) ?? dayStart
    }

    @ViewBuilder
    private func sessionRow(_ session: TimeSession) -> some View {
        let dur = max(0,
            Int((session.endAt ?? session.startAt).timeIntervalSince(session.startAt))
            - session.totalPausedSeconds
        )
        let hasNoRealTime = session.source != .liveTimer

        Button {
            guard hasNoRealTime else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            editingSession = session
        } label: {
            HStack(spacing: 10) {
                if hasNoRealTime {
                    // Faint "Set start time" hint instead of plain blank — tells
                    // the user this row is tappable. The text sits in the same
                    // 96-pt slot as a real time range so layout doesn't jump
                    // when the row promotes to liveTimer after editing.
                    Text("Set start time")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.textTertiary.opacity(0.7))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(width: 96, alignment: .leading)
                } else {
                    Text(timeRangeLabel(session))
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(width: 96, alignment: .leading)
                }

                Spacer(minLength: 8)

                Text(formatDuration(dur))
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!hasNoRealTime)
    }

    private func timeRangeLabel(_ session: TimeSession) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        let start = f.string(from: session.startAt)
        let end = session.endAt.map { f.string(from: $0) } ?? "—"
        return "\(start) – \(end)"
    }

    private func applyStartTime(to session: TimeSession, picked: Date) {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let comps = cal.dateComponents([.hour, .minute], from: picked)
        guard let newStart = cal.date(
            bySettingHour: comps.hour ?? 9,
            minute: comps.minute ?? 0,
            second: 0,
            of: dayStart
        ) else { return }

        // Preserve the existing effective duration; only translate startAt.
        let dur = max(0,
            Int((session.endAt ?? session.startAt).timeIntervalSince(session.startAt))
            - session.totalPausedSeconds
        )
        session.startAt = newStart
        session.endAt   = newStart.addingTimeInterval(TimeInterval(dur))
        session.totalPausedSeconds = 0
        // Promote to a real-timed session so the row renders HH:mm – HH:mm
        // and analytics treat it as a normal live session from now on.
        session.source = .liveTimer
        try? modelContext.save()
    }
}

private struct SetStartTimeSheet: View {
    let initialDate: Date
    let onSave: (Date) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Date

    init(initialDate: Date, onSave: @escaping (Date) -> Void) {
        self.initialDate = initialDate
        self.onSave = onSave
        _selected = State(initialValue: initialDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            GrabberView()
            Text("Set start time")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .padding(.top, 12)
                .padding(.bottom, 4)

            DatePicker(
                "",
                selection: $selected,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)

            PrimaryButton(title: "Set time") {
                onSave(selected)
                dismiss()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.bgElevated.ignoresSafeArea())
    }
}
