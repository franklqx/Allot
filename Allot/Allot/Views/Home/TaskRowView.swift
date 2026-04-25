//
//  TaskRowView.swift
//  Allot
//
//  Single task row. Two independent tap targets:
//    • LEFT icon (○ / ☐ / ✓ / running clock) → tap triggers completion flow
//    • ROW body → tap opens action sheet: Start / Adjust / Remove

import SwiftUI

struct TaskRowView: View {
    let task: WorkTask
    let date: Date
    let isRunning: Bool
    let elapsedSeconds: Int
    let onIconTap: () -> Void
    let onRowTap: () -> Void

    private var isCompleted: Bool { task.isCompleted(on: date) }
    private var workedSeconds: Int { task.workedSeconds(on: date) }

    private var iconColor: Color {
        if isCompleted { return Color.textTertiary }
        if let tag = task.tag, !tag.isSystem { return Color.tagColor(tag.colorToken) }
        return Color.textSecondary
    }

    var body: some View {
        HStack(spacing: 12) {
            // LEFT: icon button (independent tap target)
            Button(action: onIconTap) {
                TaskIconView(
                    type: task.type,
                    isCompleted: isCompleted,
                    isRunning: isRunning,
                    elapsedSeconds: elapsedSeconds,
                    color: iconColor
                )
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .frame(width: 28, height: 28)

            // RIGHT: row body button
            Button(action: onRowTap) {
                HStack(spacing: 0) {
                    Text(task.title)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(isCompleted ? Color.textTertiary : Color.textPrimary)
                        .lineLimit(1)
                        .strikethrough(isCompleted, color: Color.textTertiary)

                    Spacer()

                    rightMeta
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
        .background(isRunning ? Color.textPrimary.opacity(0.04) : .clear)
    }

    @ViewBuilder
    private var rightMeta: some View {
        if isCompleted && workedSeconds > 0 {
            Text(formatDuration(workedSeconds))
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.textTertiary)
        } else if !isRunning, let startTime = task.startTime {
            Text(formatStartTime(startTime))
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .foregroundStyle(isCompleted ? Color.textTertiary : Color.textSecondary)
        }
    }
}

// MARK: Task type icon

private struct TaskIconView: View {
    let type: TaskType
    let isCompleted: Bool
    let isRunning: Bool
    let elapsedSeconds: Int
    let color: Color

    var body: some View {
        ZStack {
            if isRunning {
                // Inline mini mm:ss clock replaces the icon while running
                Text(compactClock(elapsedSeconds))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 28, height: 22)
                    .background(Color.textPrimary.opacity(0.08), in: Capsule())
                    .animation(nil, value: elapsedSeconds)
            } else if type == .recurring {
                // Dashed circle
                Circle()
                    .fill(isCompleted ? color : .clear)
                    .frame(width: 22, height: 22)
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [2.5, 2.5]))
                    .foregroundStyle(color)
                    .frame(width: 22, height: 22)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.bgPrimary)
                }
            } else {
                // Solid rounded rect
                RoundedRectangle(cornerRadius: 4)
                    .fill(isCompleted ? color : .clear)
                    .frame(width: 22, height: 22)
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(lineWidth: 1.5)
                    .foregroundStyle(color)
                    .frame(width: 22, height: 22)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.bgPrimary)
                }
            }
        }
    }

    private func compactClock(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if m >= 60 { return String(format: "%d:%02d", m/60, m%60) }
        return String(format: "%d:%02d", m, s)
    }
}
