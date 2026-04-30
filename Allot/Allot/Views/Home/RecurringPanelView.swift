//
//  RecurringPanelView.swift
//  Allot
//
//  Expandable bottom sheet for Recurring tasks.
//  Default 1/3 height → drag up near the Dynamic Island. Content scrolls inside.

import SwiftUI
import SwiftData

struct RecurringPanelView: View {
    let task: WorkTask
    let date: Date
    let onEdit: () -> Void
    var onStart: () -> Void = {}
    var activeTaskTitle: String?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("showTaskEmoji") private var showTaskEmoji = true
    @State private var showRemoveConfirm = false
    @State private var calendarSelectedDate: Date = Calendar.current.startOfDay(for: Date())

    private var tagColor: Color { task.tag.map { Color.tagColor($0.colorToken) } ?? Color.tagStone }
    private var isCountdown: Bool { task.timerMode == .countdown }
    private var countdownLabel: String { formatDuration(task.countdownDuration) }
    private var startTitle: String {
        activeTaskTitle == nil ? (isCountdown ? "Start countdown" : "Start") : "Start this task"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    // Recurring label
                    Text("Recurring")
                        .font(.system(size: 11, weight: .semibold))
                        .kerning(0.8)
                        .textCase(.uppercase)
                        .foregroundStyle(tagColor)
                        .padding(.top, 20)

                    Text(task.displayTitle(showEmoji: showTaskEmoji))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .padding(.top, 8)

                    // Tag + share %
                    if let tag = task.tag {
                        HStack(spacing: 10) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(tagColor)
                                    .frame(width: 7, height: 7)
                                Text(tag.name)
                            }
                            Text("·")
                                .foregroundStyle(Color.textTertiary)
                            Text(shareWithinTagLabel)
                        }
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary)
                        .padding(.top, 8)
                    }

                    if isCountdown {
                        Label(countdownLabel, systemImage: "hourglass")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                            .padding(.top, 8)
                    }

                    VStack(spacing: 8) {
                        if showRemoveConfirm {
                            removeConfirmView
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        } else {
                            actionButtons
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.top, 16)
                    .animation(.easeInOut(duration: 0.18), value: showRemoveConfirm)

                    Divider().padding(.vertical, 24)

                    // 3 core stats
                    HStack(spacing: 0) {
                        StatCell(value: formatDurationCompact(task.workedSecondsThisWeek()), label: "This week")
                        StatCell(value: formatDurationCompact(task.workedSecondsThisMonth()), label: "This month")
                        StatCell(value: formatDurationCompact(task.workedSecondsTotal), label: "Total")
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 8)
                    .background(Color.bgSecondary, in: RoundedRectangle(cornerRadius: Radius.md))

                    Divider().padding(.vertical, 24)

                    // Dot calendar — placed BEFORE the session list so its
                    // position is anchored by the (fixed-height) content above
                    // it. Tapping a different dot only changes the session
                    // list below; the calendar (and the selected ring) never
                    // shifts on screen.
                    DotCalendarView(
                        task: task,
                        accentColor: tagColor,
                        selectedDate: $calendarSelectedDate
                    )

                    TaskDaySessionsList(
                        task: task,
                        date: calendarSelectedDate,
                        sectionTitle: dayTitle(for: calendarSelectedDate)
                    )
                    .padding(.top, 20)

                    Divider().padding(.vertical, 24)

                    // Statistics detail
                    StatisticsSection(task: task)

                    Text("Created \(task.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 24)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(Color.bgElevated)
        .presentationDetents([.fraction(1/3), .fraction(0.92)])
        .presentationDragIndicator(.hidden)
    }

    private var actionButtons: some View {
        VStack(spacing: 8) {
            Button {
                if activeTaskTitle == nil {
                    dismiss()
                    onStart()
                } else {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        onStart()
                    }
                }
            } label: {
                Label(startTitle, systemImage: "play.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.bgPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.textPrimary, in: Capsule())
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Button {
                    dismiss()
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.bgSecondary, in: Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    archiveTask()
                } label: {
                    Label("Hide", systemImage: "eye.slash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.bgSecondary.opacity(0.6), in: Capsule())
                }
                .buttonStyle(.plain)

                Button(role: .destructive) {
                    showRemoveConfirm = true
                } label: {
                    Label("Remove", systemImage: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.stateDestructive)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.bgSecondary, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var removeConfirmView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Remove this task?", systemImage: "trash")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Text("This will delete the task and its sessions.")
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)

            HStack(spacing: 8) {
                Button {
                    showRemoveConfirm = false
                } label: {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.bgElevated, in: Capsule())
                }
                .buttonStyle(.plain)

                Button(role: .destructive) {
                    modelContext.delete(task)
                    try? modelContext.save()
                    dismiss()
                } label: {
                    Text("Remove")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.bgPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.stateDestructive, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color.bgSecondary, in: RoundedRectangle(cornerRadius: Radius.md))
    }

    private func archiveTask() {
        task.archivedAt = Date()
        try? modelContext.save()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
    }

    private func dayTitle(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }

    private var shareWithinTagLabel: String {
        guard let tag = task.tag else { return "" }
        let tagTotal = (tag.tasks ?? []).reduce(0) { $0 + $1.workedSecondsTotal }
        guard tagTotal > 0 else { return "0% of #\(tag.name)" }
        let pct = Int((Double(task.workedSecondsTotal) / Double(tagTotal)) * 100)
        return "\(pct)% of #\(tag.name)"
    }
}

// MARK: Sub-components

private struct StatCell: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .kerning(0.3)
                .textCase(.uppercase)
                .foregroundStyle(Color.textTertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 6)
    }
}

private struct DotCalendarView: View {
    let task: WorkTask
    let accentColor: Color
    @Binding var selectedDate: Date

    private let cal = Calendar.current
    private var today: Date { Date() }

    var body: some View {
        let components = cal.dateComponents([.year, .month], from: today)
        let year = components.year ?? 2026
        let month = components.month ?? 1
        let sessionDays = task.sessionDays(year: year, month: month)
        let daysInMonth = cal.range(of: .day, in: .month, for: today)?.count ?? 30
        let firstWeekday = firstWeekdayOfMonth(year: year, month: month)  // 0=Sun offset
        let selectedDay = selectedDayIfInMonth(year: year, month: month)

        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(today.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("\(sessionDays.count) of \(daysInMonth) days")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
            }

            // Weekday headers
            let headers = ["S","M","T","W","T","F","S"]
            HStack(spacing: 0) {
                ForEach(0..<7) { i in
                    Text(headers[i])
                        .font(.system(size: 10, weight: .semibold))
                        .kerning(0.4)
                        .foregroundStyle(Color.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Dots grid (starting from Sunday)
            let totalCells = firstWeekday + daysInMonth
            let rows = Int(ceil(Double(totalCells) / 7.0))

            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7) { col in
                        let cellIndex = row * 7 + col
                        let day = cellIndex - firstWeekday + 1
                        let inMonth = day >= 1 && day <= daysInMonth
                        let hasSession = inMonth && sessionDays.contains(day)
                        DotCell(
                            day: day,
                            inMonth: inMonth,
                            hasSession: hasSession,
                            isToday: isToday(day: day, year: year, month: month),
                            isSelected: inMonth && day == selectedDay,
                            accentColor: accentColor,
                            onTap: hasSession ? {
                                guard let date = cal.date(from: DateComponents(year: year, month: month, day: day))
                                else { return }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedDate = cal.startOfDay(for: date)
                            } : nil
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func firstWeekdayOfMonth(year: Int, month: Int) -> Int {
        let components = DateComponents(year: year, month: month, day: 1)
        guard let firstDay = cal.date(from: components) else { return 0 }
        let weekday = cal.component(.weekday, from: firstDay)  // 1=Sun
        return weekday - 1  // 0=Sun offset
    }

    private func isToday(day: Int, year: Int, month: Int) -> Bool {
        let c = cal.dateComponents([.year, .month, .day], from: today)
        return c.year == year && c.month == month && c.day == day
    }

    private func selectedDayIfInMonth(year: Int, month: Int) -> Int? {
        let c = cal.dateComponents([.year, .month, .day], from: selectedDate)
        guard c.year == year, c.month == month else { return nil }
        return c.day
    }
}

private struct DotCell: View {
    let day: Int
    let inMonth: Bool
    let hasSession: Bool
    let isToday: Bool
    let isSelected: Bool
    let accentColor: Color
    let onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            ZStack {
                if inMonth {
                    if hasSession {
                        Circle().fill(accentColor).frame(width: 10, height: 10)
                    } else {
                        Circle()
                            .strokeBorder(Color.textPrimary.opacity(0.12), lineWidth: 1)
                            .frame(width: 10, height: 10)
                    }
                    // Selection ring sits outside the today ring so they can
                    // compose on the same dot without conflict.
                    if isSelected {
                        Circle()
                            .strokeBorder(accentColor, lineWidth: 1.5)
                            .frame(width: 20, height: 20)
                    } else if isToday {
                        Circle()
                            .strokeBorder(Color.accentPrimary, lineWidth: 1.5)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .frame(height: 22)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
}

private struct StatisticsSection: View {
    let task: WorkTask

    private var sessions: [TimeSession] { (task.sessions ?? []).filter { $0.endAt != nil } }

    private var avgPerDay: Int {
        let sessionDates = Set(sessions.compactMap { s -> String? in
            let c = Calendar.current.dateComponents([.year, .month, .day], from: s.startAt)
            guard let y = c.year, let m = c.month, let d = c.day else { return nil }
            return "\(y)-\(m)-\(d)"
        })
        guard !sessionDates.isEmpty else { return 0 }
        return task.workedSecondsTotal / sessionDates.count
    }

    private var avgPerWeek: Int {
        let cal = Calendar.current
        let sessionWeeks = Set(sessions.compactMap { s -> String? in
            let c = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: s.startAt)
            guard let y = c.yearForWeekOfYear, let w = c.weekOfYear else { return nil }
            return "\(y)-\(w)"
        })
        guard !sessionWeeks.isEmpty else { return 0 }
        return task.workedSecondsTotal / sessionWeeks.count
    }

    private var longestSession: Int {
        sessions.map { s -> Int in
            guard let end = s.endAt else { return 0 }
            return max(0, Int(end.timeIntervalSince(s.startAt)) - s.totalPausedSeconds)
        }.max() ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Statistics")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)

            StatRow(label: "Average per day",      value: formatDuration(avgPerDay))
            StatRow(label: "Average per week",     value: formatDuration(avgPerWeek))
            StatRow(label: "Longest session",      value: formatDuration(longestSession))
        }
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundStyle(Color.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
        }
        .font(.system(size: 14))
        .padding(.vertical, 10)
        Divider()
    }
}
