//
//  HomeView.swift
//  Allot

import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var selectedDate: Date
    /// Called with a WorkTask when user wants to start a timer — parent switches to Focus tab.
    var onStart: (WorkTask) -> Void = { _ in }

    @Environment(\.modelContext) private var modelContext
    @Environment(TimerService.self) private var timerService

    @Query private var allTasks: [WorkTask]

    @State private var hideCompleted = false
    @State private var taskToComplete: WorkTask?
    @State private var activeTaskDetail: WorkTask?
    @State private var onceTaskDetail: WorkTask?
    @State private var recurringTaskDetail: WorkTask?
    @State private var taskToEdit: WorkTask?
    @State private var taskPendingSwitch: WorkTask?
    @State private var showDateJump = false

    // MARK: Computed

    private var tasksForDate: [WorkTask] {
        let filtered = allTasks
            .filter { $0.archivedAt == nil }
            .filter { $0.isScheduled(on: selectedDate) }
        let visible  = hideCompleted ? filtered.filter { !$0.isCompleted(on: selectedDate) } : filtered
        return visible.sorted(by: orderingComparator)
    }

    private func orderingComparator(_ a: WorkTask, _ b: WorkTask) -> Bool {
        if a.sortOrder != b.sortOrder { return a.sortOrder < b.sortOrder }
        switch (a.startTime, b.startTime) {
        case (let x?, let y?): return x < y
        case (nil, nil):       return a.createdAt < b.createdAt
        case (_?, nil):        return true
        case (nil, _?):        return false
        }
    }

    private var completedCount: Int {
        allTasks.filter { $0.archivedAt == nil && $0.isScheduled(on: selectedDate) && $0.isCompleted(on: selectedDate) }.count
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                topHeader
                DateStripView(selectedDate: $selectedDate)
                    .padding(.top, 8)
                taskList
            }
            .background(Color.bgPrimary)
            .navigationBarHidden(true)
        }
        .sheet(item: $taskToComplete) { task in
            CompleteSheet(task: task, date: selectedDate)
                // Path A (logged time exists) needs room for the today's-
                // sessions list at the bottom; Path B is a tighter sheet.
                .presentationDetents(
                    task.workedSeconds(on: selectedDate) > 0
                        ? [.medium, .large]
                        : [.height(360)]
                )
                .presentationDragIndicator(.hidden)
                .presentationBackground(Color.bgElevated)
        }
        .sheet(item: $activeTaskDetail) { task in
            ActiveTaskPanelView(task: task, date: selectedDate)
                .presentationDetents([.height(390)])
                .presentationDragIndicator(.hidden)
                .presentationBackground(Color.bgElevated)
        }
        .sheet(item: $onceTaskDetail) { task in
            OncePanelView(
                task: task,
                date: selectedDate,
                onEdit: { taskToEdit = task },
                onStart: { startFromDetail(task) },
                activeTaskTitle: activeTaskTitle(excluding: task)
            )
            .presentationDetents([.height(panelHeight(for: task))])
            .presentationDragIndicator(.hidden)
            .presentationBackground(Color.bgElevated)
        }
        .sheet(item: $recurringTaskDetail) { task in
            RecurringPanelView(
                task: task,
                date: selectedDate,
                onEdit: { taskToEdit = task },
                onStart: { startFromDetail(task) },
                activeTaskTitle: activeTaskTitle(excluding: task)
            )
            .presentationDragIndicator(.hidden)
            .presentationBackground(Color.bgElevated)
        }
        .sheet(item: $taskToEdit) { task in
            NewTaskView(prefilledDate: selectedDate, editingTask: task)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showDateJump) {
            DateJumpSheet(date: $selectedDate, onDismiss: { showDateJump = false })
                .presentationDetents([.medium])
                .presentationBackground(Color.bgElevated)
        }
        .alert(
            "Switch timer",
            isPresented: Binding(
                get: { taskPendingSwitch != nil },
                set: { if !$0 { taskPendingSwitch = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) {
                taskPendingSwitch = nil
            }
            Button("Switch") {
                guard let task = taskPendingSwitch else { return }
                taskPendingSwitch = nil
                timerService.stop(in: modelContext)
                onStart(task)
            }
        } message: {
            Text("This ends the current session and starts this task.")
        }
    }

    // MARK: Top header

    private var topHeader: some View {
        HStack(alignment: .top) {
            Button {
                showDateJump = true
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedDate.formatted(.dateTime.weekday(.wide)))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                    Text(selectedDate.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.system(size: 15))
                        .foregroundStyle(Color.textSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Spacer()
            NavigationLink(destination: SettingsView()) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    // MARK: Task list

    private var taskList: some View {
        List {
            if tasksForDate.isEmpty {
                emptyState
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
            } else {
                ForEach(tasksForDate, id: \.id) { task in
                    VStack(spacing: 0) {
                        TaskRowView(
                            task: task,
                            date: selectedDate,
                            isRunning: timerService.activeSession?.workTask?.id == task.id,
                            timerSeconds: timerService.displaySeconds,
                            isCountingDown: timerService.activeSession?.workTask?.id == task.id
                                && timerService.countdownTarget != nil,
                            onIconTap: { handleIconTap(task) },
                            onRowTap:  { openDetail(task) }
                        )
                        DottedDivider()
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                }
                .onMove(perform: moveTasks)
            }

            hideShowToggle
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 140, trailing: 0))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No tasks for this day")
                .font(.system(size: 16))
                .foregroundStyle(Color.textTertiary)
            Text("Tap + to add one")
                .font(.system(size: 14))
                .foregroundStyle(Color.textTertiary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    @ViewBuilder
    private var hideShowToggle: some View {
        if completedCount > 0 {
            HStack {
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        hideCompleted.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if hideCompleted {
                            Image(systemName: "eye")
                            Text("Show \(completedCount) completed")
                        } else {
                            Image(systemName: "eye.slash")
                            Text("Hide \(completedCount) completed")
                        }
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.bgSecondary, in: Capsule())
                }
                .buttonStyle(.plain)
                Spacer()
            }
        } else {
            Color.clear.frame(height: 1)
        }
    }

    // MARK: Actions

    private func panelHeight(for task: WorkTask) -> CGFloat {
        // Header + actions + bottom note. Session rows are added below.
        var height: CGFloat = 270
        if task.tag != nil && !(task.tag?.isSystem ?? true) { height += 36 }
        let cal = Calendar.current
        let dayCount = task.sessions.filter {
            $0.endAt != nil && cal.isDate($0.startAt, inSameDayAs: selectedDate)
        }.count
        if dayCount > 0 {
            // Section header (28) + per-row (44) capped at 4 rows of visible space
            height += 28 + 44 * CGFloat(min(dayCount, 4))
        }
        return min(max(height, 360), 620)
    }

    private func openDetail(_ task: WorkTask) {
        if timerService.isRunning,
           timerService.activeSession?.workTask?.id == task.id {
            activeTaskDetail = task
            return
        }

        switch task.type {
        case .once:      onceTaskDetail      = task
        case .recurring: recurringTaskDetail = task
        }
    }

    private func activeTaskTitle(excluding task: WorkTask) -> String? {
        guard timerService.isRunning else { return nil }
        if timerService.activeSession?.workTask?.id == task.id { return nil }
        return timerService.activeSession?.workTask?.title ?? "current timer"
    }

    private func startFromDetail(_ task: WorkTask) {
        if timerService.isRunning {
            taskPendingSwitch = task
            return
        }
        onStart(task)
    }

    private func handleIconTap(_ task: WorkTask) {
        if task.isCompleted(on: selectedDate) {
            task.markIncomplete(on: selectedDate)
            try? modelContext.save()
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            return
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        taskToComplete = task
    }

    private func moveTasks(from source: IndexSet, to destination: Int) {
        var working = tasksForDate
        working.move(fromOffsets: source, toOffset: destination)
        for (index, task) in working.enumerated() {
            task.sortOrder = index + 1
        }
        try? modelContext.save()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

// MARK: - Active task sheet

private struct ActiveTaskPanelView: View {
    let task: WorkTask
    let date: Date

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(TimerService.self) private var timerService

    private var modeTitle: String {
        if timerService.countdownCompleted { return "Time's up" }
        if timerService.countdownTarget != nil { return "Countdown" }
        if task.timerMode == .countdown { return "Continuing" }
        return "Stopwatch"
    }

    private var modeIcon: String {
        if timerService.countdownCompleted { return "bell.fill" }
        if timerService.countdownTarget != nil { return "hourglass" }
        if task.timerMode == .countdown { return "arrow.clockwise" }
        return "stopwatch"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GrabberView()

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(task.title)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Label(modeTitle, systemImage: modeIcon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }
                .padding(.top, 12)

                HStack(spacing: 6) {
                    if let tag = task.tag, !tag.isSystem {
                        Circle()
                            .fill(Color.tagColor(tag.colorToken))
                            .frame(width: 7, height: 7)
                        Text(tag.name)
                    } else {
                        Text("Untagged")
                    }
                    Text("·")
                        .foregroundStyle(Color.textTertiary)
                    Text(date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textSecondary)
                .padding(.top, 8)

                Text(formatClock(timerService.displaySeconds))
                    .font(.system(size: 58, weight: .regular, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 34)
                    .animation(nil, value: timerService.displaySeconds)

                HStack(spacing: 10) {
                    Button {
                        timerService.isPaused ? timerService.resume() : timerService.pause()
                    } label: {
                        Label(timerService.isPaused ? "Resume" : "Pause",
                              systemImage: timerService.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color.bgSecondary, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive) {
                        timerService.stop(in: modelContext)
                        dismiss()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.stateDestructive)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color.bgSecondary.opacity(0.75), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 32)

                Text("This task is currently running.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 18)
        }
        .background(Color.bgElevated)
    }
}

// MARK: Calendar jump sheet

private struct DateJumpSheet: View {
    @Binding var date: Date
    let onDismiss: () -> Void

    @State private var draft: Date

    init(date: Binding<Date>, onDismiss: @escaping () -> Void) {
        self._date = date
        self.onDismiss = onDismiss
        self._draft = State(initialValue: date.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            DatePicker("", selection: $draft, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(Color.accentPrimary)
                .padding()
                .navigationTitle("Jump to date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Today") {
                            draft = Date()
                            date = Date()
                            onDismiss()
                        }
                        .foregroundStyle(Color.textSecondary)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            date = draft
                            onDismiss()
                        }
                        .foregroundStyle(Color.accentPrimary)
                        .fontWeight(.semibold)
                    }
                }
        }
    }
}
