//
//  TagPickerSheet.swift
//  Allot

import SwiftUI
import SwiftData

struct TagPickerSheet: View {
    @Binding var selectedTag: Tag?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Tag.createdAt) private var tags: [Tag]

    @State private var showCreate = false
    @State private var pendingDelete: Tag?

    var body: some View {
        List {
            // Untagged option
            ForEach(tags.filter { $0.isSystem }) { tag in
                Button {
                    selectedTag = nil
                    dismiss()
                } label: {
                    TagRow(tag: tag, isSelected: selectedTag == nil || selectedTag?.id == tag.id)
                }
                .buttonStyle(.plain)
            }

            // User tags
            let userTags = tags.filter { !$0.isSystem }
            Section("Your Tags") {
                Button { showCreate = true } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.accentPrimary)
                        Text("New tag")
                            .foregroundStyle(Color.accentPrimary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                ForEach(userTags) { tag in
                    Button {
                        selectedTag = tag
                        dismiss()
                    } label: {
                        TagRow(tag: tag, isSelected: selectedTag?.id == tag.id)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            pendingDelete = tag
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.bgElevated)
        .sheetChrome(
            title: "Tag",
            trailing: SheetAction(label: "Done") { dismiss() }
        )
        .sheet(isPresented: $showCreate) {
            TagEditSheet()
                .presentationDetents([.height(400)])
                .presentationBackground(Color.bgElevated)
        }
        .confirmationDialog(
            deleteTitle,
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: deletePendingTag)
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("Tasks stay untagged.")
        }
    }

    private var deleteTitle: String {
        guard let pendingDelete else { return "Delete tag" }
        return "Delete \"\(pendingDelete.name)\""
    }

    private func deletePendingTag() {
        guard let tag = pendingDelete else { return }
        for task in (tag.tasks ?? []) {
            task.tag = nil
        }
        if selectedTag?.id == tag.id {
            selectedTag = nil
        }
        modelContext.delete(tag)
        try? modelContext.save()
        pendingDelete = nil
    }
}

private struct TagRow: View {
    let tag: Tag
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            TagDot(color: Color.tagColor(tag.colorToken), style: .filled, size: 14)
            Text(tag.name)
                .foregroundStyle(Color.textPrimary)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.accentPrimary)
                    .font(.system(size: 15, weight: .semibold))
            }
        }
        .contentShape(Rectangle())
    }
}
