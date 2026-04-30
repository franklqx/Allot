//
//  ArchivedTasksView.swift
//  Allot
//
//  Lists tasks paused/archived from Home. Restore puts them back into the
//  active rotation; Delete removes them and their session history.
//

import SwiftUI
import SwiftData

struct ArchivedTasksView: View {

    @Environment(\.modelContext) private var modelContext
    @AppStorage("showTaskEmoji") private var showTaskEmoji = true
    @Query private var allTasks: [WorkTask]

    private var archived: [WorkTask] {
        allTasks
            .filter { $0.archivedAt != nil }
            .sorted { ($0.archivedAt ?? Date()) > ($1.archivedAt ?? Date()) }
    }

    var body: some View {
        Group {
            if archived.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(archived) { task in
                        row(task)
                            .listRowBackground(Color.bgElevated)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.bgPrimary)
            }
        }
        .navigationTitle("Hidden")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.bgPrimary)
    }

    private func row(_ task: WorkTask) -> some View {
        HStack(spacing: 12) {
            TaskBox(
                color: task.tag.map { Color.tagColor($0.colorToken) } ?? Color.textTertiary,
                style: TaskBox.style(for: task.type),
                size: 18,
                cornerRadius: 4
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(task.displayTitle(showEmoji: showTaskEmoji))
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                if let archivedAt = task.archivedAt {
                    Text("Hidden \(archivedAt.formatted(.relative(presentation: .named)))")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textTertiary)
                }
            }

            Spacer()

            Button {
                restore(task)
            } label: {
                Text("Show")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.accentPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentPrimary.opacity(0.1), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
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

    private func restore(_ task: WorkTask) {
        task.archivedAt = nil
        try? modelContext.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "eye.slash")
                .font(.system(size: 44))
                .foregroundStyle(Color.textTertiary.opacity(0.35))
            Text("No hidden tasks")
                .font(.system(size: 16))
                .foregroundStyle(Color.textTertiary)
            Text("Hide a task from its detail panel and it will land here. You can bring it back any time.")
                .font(.system(size: 13))
                .foregroundStyle(Color.textTertiary.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
