//
//  ContentView.swift
//  Allot
//
//  占位首页，后续替换为规格中的 Home。

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkTask.createdAt, order: .reverse) private var tasks: [WorkTask]
    @Query(sort: \Tag.createdAt) private var tags: [Tag]

    var body: some View {
        NavigationStack {
            List {
                if tasks.isEmpty {
                    ContentUnavailableView(
                        "Allot",
                        systemImage: "clock",
                        description: Text("点击 + 添加任务后即可开始计时。此为占位首页，后续替换为规格中的 Home。")
                    )
                }
                Section("任务") {
                    ForEach(tasks, id: \.id) { task in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                            if !task.tags.isEmpty {
                                Text(task.tags.map(\.name).joined(separator: "、"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteTasks)
                }
                Section("标签") {
                    ForEach(tags, id: \.id) { tag in
                        Text(tag.name)
                    }
                    .onDelete(perform: deleteTags)
                }
            }
            .navigationTitle("Allot")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("新建任务") { addTask() }
                        Button("新建标签") { addTag() }
                    } label: {
                        Label("添加", systemImage: "plus")
                    }
                }
            }
        }
    }

    private func addTask() {
        withAnimation {
            let task = WorkTask(title: "新任务 \(tasks.count + 1)")
            modelContext.insert(task)
        }
    }

    private func addTag() {
        withAnimation {
            let tag = Tag(name: "标签 \(tags.count + 1)")
            modelContext.insert(tag)
        }
    }

    private func deleteTasks(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(tasks[index])
        }
    }

    private func deleteTags(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(tags[index])
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Tag.self, WorkTask.self, TimeSession.self], inMemory: true)
}
