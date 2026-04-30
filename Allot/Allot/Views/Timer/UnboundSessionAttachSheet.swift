//
//  UnboundSessionAttachSheet.swift
//  Allot
//
//  Shown after stopping a timer that was started without a task. Lets the user
//  attach the session to an existing task or quickly create a new one.
//

import SwiftUI
import SwiftData

struct UnboundSessionAttachSheet: View {

    let session: TimeSession
    let onDone: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @AppStorage("showTaskEmoji") private var showTaskEmoji = true

    @Query(sort: \WorkTask.createdAt, order: .reverse)
    private var allTasks: [WorkTask]

    @State private var showCreateTask = false
    @State private var newTaskTitle: String = ""
    @State private var newTaskTag: Tag?

    private var activeTasks: [WorkTask] {
        allTasks.filter { $0.archivedAt == nil }
    }

    private var duration: Int {
        guard let end = session.endAt else { return 0 }
        return max(0, Int(end.timeIntervalSince(session.startAt)) - session.totalPausedSeconds)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 16)

                List {
                    Section {
                        Button {
                            showCreateTask = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.accentPrimary)
                                Text("Create new task")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.accentPrimary)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowBackground(Color.bgElevated)

                    Section("Existing tasks") {
                        if activeTasks.isEmpty {
                            Text("No tasks yet")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.textTertiary)
                        } else {
                            ForEach(activeTasks) { task in
                                Button { attach(to: task) } label: {
                                    HStack(spacing: 12) {
                                        if let tag = task.tag, !tag.isSystem {
                                            TagDot(color: Color.tagColor(tag.colorToken), style: .filled, size: 10)
                                        } else {
                                            TagDot(color: Color.textTertiary, style: .filled, size: 10)
                                        }
                                        Text(task.displayTitle(showEmoji: showTaskEmoji))
                                            .font(.system(size: 15))
                                            .foregroundStyle(Color.textPrimary)
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .listRowBackground(Color.bgElevated)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.bgElevated)
            }
            .background(Color.bgElevated)
            .navigationTitle("Attach to task")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Discard", role: .destructive) { discard() }
                        .foregroundStyle(Color.stateDestructive)
                }
            }
            .sheet(isPresented: $showCreateTask) {
                CreateAndAttachSheet(
                    initialTag: nil,
                    onCreate: { title, tag in
                        let task = WorkTask(
                            title: title,
                            type: .once,
                            scheduledDate: Calendar.current.startOfDay(for: session.startAt),
                            tag: tag
                        )
                        modelContext.insert(task)
                        attach(to: task)
                    }
                )
                .presentationDetents([.height(360)])
                .presentationBackground(Color.bgElevated)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recorded \(formatDuration(duration))")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            Text("What were you working on?")
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func attach(to task: WorkTask) {
        session.workTask = task
        task.markCompleted(on: session.startAt)
        try? modelContext.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
        onDone()
    }

    private func discard() {
        modelContext.delete(session)
        try? modelContext.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
        onDone()
    }
}

// MARK: Quick "create + attach" minimal form

private struct CreateAndAttachSheet: View {
    let initialTag: Tag?
    let onCreate: (String, Tag?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var tag: Tag?
    @State private var showTagPicker = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            TextField("Task title", text: $title, axis: .vertical)
                .font(.system(size: 22, weight: .medium))
                .focused($focused)
                .padding(.horizontal, 20)
                .padding(.top, 8)

            Spacer()

            HStack {
                Button { showTagPicker = true } label: {
                    HStack(spacing: 6) {
                        if let tag = tag {
                            TagDot(color: Color.tagColor(tag.colorToken), style: .filled, size: 10)
                            Text(tag.name)
                        } else {
                            Image(systemName: "tag")
                                .font(.system(size: 12))
                            Text("Tag")
                        }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(tag != nil ? Color.accentPrimary : Color.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        tag != nil ? Color.accentPrimary.opacity(0.1) : Color.bgSecondary,
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.bgElevated)
        .sheetChrome(
            title: "New task",
            leading: SheetAction(label: "Cancel") { dismiss() },
            trailing: SheetAction(label: "Create") {
                let trimmed = title.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                onCreate(trimmed, tag)
                dismiss()
            }
        )
        .task {
            tag = initialTag
            focused = true
        }
        .sheet(isPresented: $showTagPicker) {
            TagPickerSheet(selectedTag: $tag)
                .presentationDetents([.medium, .large])
                .presentationBackground(Color.bgElevated)
        }
    }
}
