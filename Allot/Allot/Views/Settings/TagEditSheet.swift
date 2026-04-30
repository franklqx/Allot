//
//  TagEditSheet.swift
//  Allot
//
//  Create or edit a tag: name field + 12-color swatch grid + tasks list.
//  Layout matches the rest of the Settings tree (insetGrouped List), so
//  rows render as white cards on the system grouped background.

import SwiftUI
import SwiftData

private let tagColorTokens: [String] = [
    "coral", "marigold", "mustard", "sage",
    "olive", "teal", "powder", "periwinkle",
    "mauve", "terracotta", "rose", "stone",
]

struct TagEditSheet: View {

    let tag: Tag?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage("showTaskEmoji") private var showTaskEmoji = true

    @State private var name: String
    @State private var selectedToken: String
    @State private var showDeleteConfirm = false
    @State private var taskToEdit: WorkTask?
    @FocusState private var nameFieldFocused: Bool

    init(tag: Tag? = nil) {
        self.tag = tag
        _name         = State(wrappedValue: tag?.name       ?? "")
        _selectedToken = State(wrappedValue: tag?.colorToken ?? "coral")
    }

    private var isEditing: Bool { tag != nil }
    private var canSave: Bool   { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    private var taggedTasks: [WorkTask] {
        guard let tag else { return [] }
        return (tag.tasks ?? [])
            .filter { $0.archivedAt == nil }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        List {
            Section("Name") {
                TextField("Tag name", text: $name)
                    .font(.system(size: 17))
                    .focused($nameFieldFocused)
                    .submitLabel(.done)
            }

            Section("Color") {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 6),
                    spacing: 14
                ) {
                    ForEach(tagColorTokens, id: \.self) { token in
                        colorSwatch(token)
                    }
                }
                .padding(.vertical, 6)
            }

            if isEditing {
                tasksSection

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Tag")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.stateDestructive)
                            Spacer()
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.bgGrouped)
        .sheetChrome(
            title: isEditing ? "Edit Tag" : "New Tag",
            leading: SheetAction(label: "Cancel") { dismiss() },
            trailing: SheetAction(label: "Save", isDisabled: !canSave) { save() }
        )
        .onAppear { nameFieldFocused = !isEditing }
        .confirmationDialog(
            "Delete \"\(tag?.name ?? "")\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Tag", role: .destructive) {
                if let t = tag { modelContext.delete(t) }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Tasks using this tag will become untagged.")
        }
        .sheet(item: $taskToEdit) { task in
            NewTaskView(prefilledDate: task.scheduledDate ?? Date(), editingTask: task)
                .presentationDetents([.large])
        }
    }

    @ViewBuilder
    private var tasksSection: some View {
        let tasks = taggedTasks
        Section {
            if tasks.isEmpty {
                Text("No tasks use this tag yet")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textTertiary)
            } else {
                ForEach(tasks, id: \.id) { task in
                    Button {
                        taskToEdit = task
                    } label: {
                        taskRow(task)
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            HStack {
                Text("Tasks")
                Spacer()
                if !tasks.isEmpty {
                    Text("\(tasks.count)")
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
    }

    private func taskRow(_ task: WorkTask) -> some View {
        HStack(spacing: 12) {
            TaskBox(
                color: Color.tagColor(selectedToken),
                style: TaskBox.style(for: task.type),
                size: 14,
                cornerRadius: 3
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(task.displayTitle(showEmoji: showTaskEmoji))
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                Text(task.type == .once ? "Once" : "Recurring")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textTertiary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.textTertiary.opacity(0.5))
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func colorSwatch(_ token: String) -> some View {
        let selected = selectedToken == token
        return Circle()
            .fill(Color.tagColor(token))
            .frame(width: 38, height: 38)
            .overlay {
                if selected {
                    Circle()
                        .stroke(Color.tagColor(token), lineWidth: 3)
                        .padding(-5)
                        .opacity(0.4)
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .onTapGesture { selectedToken = token }
            .frame(maxWidth: .infinity)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let existing = tag {
            existing.name       = trimmed
            existing.colorToken = selectedToken
            existing.emoji      = nil
        } else {
            modelContext.insert(Tag(name: trimmed, colorToken: selectedToken))
        }
        dismiss()
    }
}
