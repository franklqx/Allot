//
//  TagsView.swift
//  Allot
//
//  Settings subpage: list, create, edit, and delete user-created tags.

import SwiftUI
import SwiftData

struct TagsView: View {

    @Query(filter: #Predicate<Tag> { tag in tag.isSystem == false },
           sort: \Tag.name)
    private var userTags: [Tag]

    @Environment(\.modelContext) private var modelContext

    @State private var showCreateSheet = false
    @State private var editingTag: Tag?

    var body: some View {
        Group {
            if userTags.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(userTags) { tag in
                        Button { editingTag = tag } label: {
                            tagRow(tag)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.bgPrimary)
                    }
                    .onDelete(perform: deleteTags)
                }
                .listStyle(.plain)
            }
        }
        .background(Color.bgPrimary)
        .navigationTitle("Tags")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showCreateSheet = true } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.accentPrimary)
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            TagEditSheet()
                .presentationDetents([.height(400)])
                .presentationBackground(Color.bgPrimary)
        }
        .sheet(item: $editingTag) { tag in
            TagEditSheet(tag: tag)
                .presentationDetents([.height(400)])
                .presentationBackground(Color.bgPrimary)
        }
    }

    private func tagRow(_ tag: Tag) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.tagColor(tag.colorToken))
                .frame(width: 14, height: 14)
            Text(tag.name)
                .font(.system(size: 16))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            let n = tag.tasks.count
            Text("\(n) task\(n == 1 ? "" : "s")")
                .font(.system(size: 13))
                .foregroundStyle(Color.textTertiary)
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(Color.textTertiary.opacity(0.5))
        }
        .padding(.vertical, 3)
    }

    private func deleteTags(at offsets: IndexSet) {
        for i in offsets { modelContext.delete(userTags[i]) }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tag")
                .font(.system(size: 44))
                .foregroundStyle(Color.textTertiary.opacity(0.35))
                .padding(.bottom, 8)
            Text("No tags yet")
                .font(.system(size: 16))
                .foregroundStyle(Color.textTertiary)
            Text("Tap + to create your first tag")
                .font(.system(size: 14))
                .foregroundStyle(Color.textTertiary.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
