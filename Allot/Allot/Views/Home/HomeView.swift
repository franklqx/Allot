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

    // MARK: Computed

    private var tasksForDate: [WorkTask] {
        let filtered = allTasks.filter { $0.isScheduled(on: selectedDate) }
        let visible  = hideCompleted ? filtered.filter { !$0.isCompleted(on: selectedDate) } : filtered
        return visible.sorted {
            switch ($0.startTime, $1.startTime) {
            case (let a?, let b?): return a < b
            case (nil, nil):       return $0.createdAt < $1.createdAt
            case (_?, nil):        return true
            case (nil, _?):        return false
            }
        }
    }

    private var completedCount: Int {
        allTasks.filter { $0.isScheduled(on: selectedDate) && $0.isCompleted(on: selectedDate) }.count
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerBar
                DateStripView(selectedDate: $selectedDate)
                Divider()
                    .foregroundStyle(Color.textPrimary.opacity(0.06))
                taskList
            }
            .background(Color.bgPrimary)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
        }
        .sheet(item: $taskToComplete) { task in
            CompleteSheet(task: task, date: selectedDate)
                .presentationDetents([.height(task.workedSeconds(on: selectedDate) > 0 ? 360 : 420)])
                .presentationDragIndicator(.hidden)
                .presentationBackground(Color.bgElevated)
        }
        .sheet(item: $onceTaskDetail) { task in
            OncePanelView(
                task: task,
                date: selectedDate,
                onEdit: { },
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
                onEdit: { },
                onStart: { onStart(task) }
            )
            .presentationBackground(Color.bgElevated)
        }
    }

    // MARK: Header

    private var headerBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedDate.formatted(.dateTime.weekday(.wide)))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text(selectedDate.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 17))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: Task list

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if tasksForDate.isEmpty {
                    emptyState
                } else {
                    ForEach(tasksForDate, id: \.id) { task in
                        TaskRowView(
                            task: task,
                            date: selectedDate,
                            isRunning: timerService.activeSession?.workTask?.id == task.id,
                            elapsedSeconds: timerService.elapsedSeconds,
                            onIconTap: { handleIconTap(task) },
                            onRowTap:  { openDetail(task) }
                        )
                        Divider()
                            .padding(.leading, 60)
                            .foregroundStyle(Color.textPrimary.opacity(0.06))
                    }
                }

                hideShowToggle
                    .padding(.top, 12)
                    .padding(.bottom, 140)
            }
        }
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
        .padding(.top, 60)
    }

    @ViewBuilder
    private var hideShowToggle: some View {
        if completedCount > 0 {
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
        }
    }

    // MARK: Actions

    private func panelHeight(for task: WorkTask) -> CGFloat {
        var height: CGFloat = 220                                   // title + meta + Start + Edit/Remove row
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
}
