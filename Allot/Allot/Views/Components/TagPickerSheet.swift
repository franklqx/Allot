//
//  TagPickerSheet.swift
//  Allot

import SwiftUI
import SwiftData

struct TagPickerSheet: View {
    @Binding var selectedTag: Tag?
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Tag.createdAt) private var tags: [Tag]

    @State private var showCreate = false

    var body: some View {
        NavigationStack {
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
                    }
                }
            }
            .navigationTitle("Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.accentPrimary)
                }
            }
            .sheet(isPresented: $showCreate) {
                TagEditSheet()
                    .presentationDetents([.height(400)])
                    .presentationBackground(Color.bgPrimary)
            }
        }
        .presentationDetents([.medium])
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
