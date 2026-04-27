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
    @State private var onceTaskDetail: WorkTask?
    @State private var recurringTaskDetail: WorkTask?
    @State private var taskToEdit: WorkTask?
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
                .presentationDetents([.height(task.workedSeconds(on: selectedDate) > 0 ? 300 : 290)])
                .presentationDragIndicator(.hidden)
                .presentationBackground(Color.bgElevated)
        }
        .sheet(item: $onceTaskDetail) { task in
            OncePanelView(
                task: task,
                date: selectedDate,
                onEdit: { taskToEdit = task },
                onStart: { onStart(task) }
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
                onStart: { onStart(task) }
            )
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
                            elapsedSeconds: timerService.elapsedSeconds,
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
        var height: CGFloat = 220
        if task.tag != nil && !(task.tag?.isSystem ?? true) { height += 40 }
        if task.workedSeconds(on: selectedDate) > 0 { height += 70 }
        return min(height + 40, 480)
    }

    private func openDetail(_ task: WorkTask) {
        switch task.type {
        case .once:      onceTaskDetail      = task
        case .recurring: recurringTaskDetail = task
        }
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
