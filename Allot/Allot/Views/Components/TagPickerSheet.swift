//
//  TagPickerSheet.swift
//  Allot

import SwiftUI
import SwiftData

struct TagPickerSheet: View {
    @Binding var selectedTag: Tag?
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Tag.createdAt) private var tags: [Tag]

    var body: some View {
        NavigationStack {
            List {
                // Untagged option
                ForEach(tags.filter { $0.isSystem }) { tag in
                    TagRow(tag: tag, isSelected: selectedTag == nil || selectedTag?.id == tag.id)
                        .onTapGesture {
                            selectedTag = tag.isSystem ? nil : tag
                            dismiss()
                        }
                }

                // User tags
                let userTags = tags.filter { !$0.isSystem }
                if !userTags.isEmpty {
                    Section("Your Tags") {
                        ForEach(userTags) { tag in
                            TagRow(tag: tag, isSelected: selectedTag?.id == tag.id)
                                .onTapGesture {
                                    selectedTag = tag
                                    dismiss()
                                }
                        }
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
        }
        .presentationDetents([.medium])
    }
}

private struct TagRow: View {
    let tag: Tag
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.tagColor(tag.colorToken))
                .frame(width: 14, height: 14)
            Text(tag.name)
                .foregroundStyle(Color.textPrimary)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.accentPrimary)
                    .font(.system(size: 15, weight: .semibold))
            }
        }
    }
}
