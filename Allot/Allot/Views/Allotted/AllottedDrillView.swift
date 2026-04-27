//
//  AllottedDrillView.swift
//  Allot
//
//  Tag drill-down: donut of tasks within tag + task list.

import SwiftUI
import SwiftData

private struct TaskStat: Identifiable {
    let id: UUID
    let task: WorkTask
    var seconds: Int
    var fraction: Double = 0
}

struct AllottedDrillView: View {

    let tag: Tag
    let timeRange: TimeRange
    let sessions: [TimeSession]   // pre-filtered by time range + active filters

    @State private var highlightTaskId: UUID? = nil

    // MARK: Computed

    private var tagSessions: [TimeSession] {
        sessions.filter { $0.workTask?.tag?.id == tag.id }
    }

    private var taskStats: [TaskStat] {
        var dict: [UUID: TaskStat] = [:]
        for s in tagSessions {
            guard let endAt = s.endAt, let task = s.workTask else { continue }
            let dur = max(0, Int(endAt.timeIntervalSince(s.startAt)) - s.totalPausedSeconds)
            guard dur > 0 else { continue }
            if var ex = dict[task.id] { ex.seconds += dur; dict[task.id] = ex }
            else { dict[task.id] = TaskStat(id: task.id, task: task, seconds: dur) }
        }
        let total = dict.values.reduce(0) { $0 + $1.seconds }
        guard total > 0 else { return [] }
        return dict.values
            .sorted { $0.seconds > $1.seconds }
            .map { var s = $0; s.fraction = Double(s.seconds) / Double(total); return s }
    }

    private var totalSeconds: Int { taskStats.reduce(0) { $0 + $1.seconds } }

    private var innerSegments: [DonutSegment] {
        let n = taskStats.count
        return taskStats.enumerated().map { i, stat in
            let opacity = n > 1 ? (0.4 + 0.6 * Double(n - 1 - i) / Double(n - 1)) : 1.0
            return DonutSegment(
                id: stat.id,
                color: Color.tagColor(tag.colorToken).opacity(opacity),
                fraction: stat.fraction,
                label: stat.task.title,
                sublabel: formatDuration(stat.seconds)
            )
        }
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            if taskStats.isEmpty {
                emptyState
            } else {
                DonutChartView(
                    segments: innerSegments,
                    centerTitle: formatDuration(totalSeconds),
                    centerSubtitle: tag.name,
                    highlightId: highlightTaskId,
                    onTapSegment: { id in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            highlightTaskId = (highlightTaskId == id) ? nil : id
                        }
                    }
                )
                .frame(height: 280)
                .padding(.vertical, 12)

                Divider().foregroundStyle(Color.textPrimary.opacity(0.06))

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(taskStats) { stat in
                            taskRow(stat: stat)
                            DottedDivider()
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .background(Color.bgPrimary)
        .navigationTitle(tag.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func taskRow(stat: TaskStat) -> some View {
        let dimmed = highlightTaskId != nil && highlightTaskId != stat.id
        return HStack(spacing: 0) {
            Circle()
                .fill(Color.tagColor(tag.colorToken).opacity(dimmed ? 0.2 : 1))
                .frame(width: 8, height: 8)
                .padding(.leading, 20)
                .padding(.trailing, 12)
            VStack(alignment: .leading, spacing: 2) {
                Text(stat.task.title)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textPrimary.opacity(dimmed ? 0.3 : 1))
                    .lineLimit(1)
                Text(String(format: "%.0f%%  ·  %@", stat.fraction * 100, timeRange.rawValue))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary.opacity(dimmed ? 0.3 : 1))
            }
            Spacer()
            Text(formatDuration(stat.seconds))
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.textPrimary.opacity(dimmed ? 0.3 : 1))
                .padding(.trailing, 20)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                highlightTaskId = (highlightTaskId == stat.id) ? nil : stat.id
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 44))
                .foregroundStyle(Color.textTertiary.opacity(0.35))
                .padding(.bottom, 8)
            Text("No sessions for \(tag.name)")
                .font(.system(size: 16))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 100)
    }
}
