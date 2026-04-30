//
//  AllTasksView.swift
//  Allot
//
//  Master list of every task ever created (active + hidden). Swipe to delete.
//  Hidden tasks have a small badge so the user knows why they don't show on
//  Home. For restoring hidden tasks, use the dedicated Hidden tasks view.
//

import SwiftUI
import SwiftData

struct AllTasksView: View {

    @Environment(\.modelContext) private var modelContext

    @AppStorage("showTaskEmoji") private var showTaskEmoji = true

    @Query(sort: \WorkTask.createdAt, order: .reverse)
    private var tasks: [WorkTask]

    private enum TypeFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case once = "Task"
        case recurring = "Recurring"
        var id: String { rawValue }
    }

    @State private var typeFilter: TypeFilter = .all
    @State private var taskToEdit: WorkTask?

    private var filteredTasks: [WorkTask] {
        switch typeFilter {
        case .all:       return tasks
        case .once:      return tasks.filter { $0.type == .once }
        case .recurring: return tasks.filter { $0.type == .recurring }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Type", selection: $typeFilter) {
                ForEach(TypeFilter.allCases) { f in
                    Text(f.rawValue).tag(f)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            if filteredTasks.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(filteredTasks) { task in
                        Button {
                            taskToEdit = task
                        } label: {
                            row(task)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.bgElevated)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                addToToday(task)
                            } label: {
                                Label("Add to today", systemImage: "calendar.badge.plus")
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                modelContext.delete(task)
                                try? modelContext.save()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.bgPrimary)
            }
        }
        .navigationTitle("All tasks")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.bgPrimary)
        .sheet(item: $taskToEdit) { task in
            NewTaskView(prefilledDate: task.scheduledDate ?? Date(), editingTask: task)
                .presentationDetents([.large])
        }
    }

    private func row(_ task: WorkTask) -> some View {
        HStack(spacing: 12) {
            TaskBox(
                color: task.tag.map { Color.tagColor($0.colorToken) } ?? Color.textTertiary,
                style: TaskBox.style(for: task.type),
                size: 16,
                cornerRadius: 4
            )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(task.displayTitle(showEmoji: showTaskEmoji))
                        .font(.system(size: 15))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                    if task.isArchived {
                        Text("HIDDEN")
                            .font(.system(size: 9, weight: .semibold))
                            .kerning(0.5)
                            .foregroundStyle(Color.textTertiary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.textTertiary.opacity(0.15), in: Capsule())
                    }
                }
                HStack(spacing: 6) {
                    Text(task.type == .once ? "Once" : "Recurring")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.textTertiary)
                    if task.workedSecondsTotal > 0 {
                        Text("·")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.textTertiary)
                        Text(formatDuration(task.workedSecondsTotal))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.textTertiary)
                    }
                }
            }

            Spacer()

            if !task.isScheduled(on: Date()) {
                Button {
                    addToToday(task)
                } label: {
                    Label("Today", systemImage: "calendar.badge.plus")
                        .labelStyle(.titleAndIcon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.accentPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.accentPrimary.opacity(0.1), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundStyle(Color.textTertiary.opacity(0.35))
            Text(emptyMessage)
                .font(.system(size: 16))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyMessage: String {
        switch typeFilter {
        case .all:       return "No tasks yet"
        case .once:      return "No one-off tasks"
        case .recurring: return "No recurring tasks"
        }
    }

    private func addToToday(_ task: WorkTask) {
        task.reuseFor(date: Date())
        try? modelContext.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
