//
//  FilterDrawerView.swift
//  Allot
//
//  Filter sheet for AllottedView: task type + tag visibility.

import SwiftUI
import SwiftData

struct FilterDrawerView: View {

    @Binding var mode:           AllotMode
    @Binding var hiddenTagIds:   Set<UUID>
    @Binding var taskTypeFilter: TaskType?

    @Query(filter: #Predicate<Tag> { tag in tag.isSystem == false }, sort: \Tag.name)
    private var userTags: [Tag]

    @Environment(\.dismiss) private var dismiss

    private var hasActiveFilter: Bool { !hiddenTagIds.isEmpty || taskTypeFilter != nil }

    var body: some View {
        NavigationStack {
            List {
                Section("View") {
                    Picker("Mode", selection: $mode) {
                        ForEach(AllotMode.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(Color.bgElevated)

                Section("Task Type") {
                    typeRow(label: "All types",  value: nil)
                    typeRow(label: "One-time",   value: .once)
                    typeRow(label: "Recurring",  value: .recurring)
                }
                .listRowBackground(Color.bgElevated)

                if !userTags.isEmpty {
                    Section("Tags") {
                        ForEach(userTags) { tag in
                            tagToggleRow(tag: tag)
                        }
                    }
                    .listRowBackground(Color.bgElevated)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.bgElevated)
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        hiddenTagIds = []
                        taskTypeFilter = nil
                    }
                    .foregroundStyle(Color.textSecondary)
                    .disabled(!hasActiveFilter)
                    .opacity(hasActiveFilter ? 1 : 0.35)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.accentPrimary)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func typeRow(label: String, value: TaskType?) -> some View {
        Button {
            taskTypeFilter = value
        } label: {
            HStack {
                Text(label)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                if taskTypeFilter == value {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.accentPrimary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func tagToggleRow(tag: Tag) -> some View {
        Button {
            if hiddenTagIds.contains(tag.id) {
                hiddenTagIds.remove(tag.id)
            } else {
                hiddenTagIds.insert(tag.id)
            }
        } label: {
            HStack(spacing: 12) {
                TagDot(color: Color.tagColor(tag.colorToken), style: .filled, size: 10)
                Text(tag.name)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                if !hiddenTagIds.contains(tag.id) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.accentPrimary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
