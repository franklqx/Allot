//
//  TaskRowView.swift
//  Allot
//
//  Single task row: [icon] title           startTime / elapsed / done+duration

import SwiftUI

struct TaskRowView: View {
    let task: WorkTask
    let date: Date
    let isRunning: Bool
    let elapsedSeconds: Int
    let onShortPress: () -> Void
    let onLongPress: () -> Void

    private var isCompleted: Bool { task.isCompleted(on: date) }
    private var workedSeconds: Int { task.workedSeconds(on: date) }
    private var iconColor: Color { isCompleted ? Color.textTertiary : (task.tag.map { Color.tagColor($0.colorToken) } ?? Color.textSecondary) }

    var body: some View {
        Button(action: onShortPress) {
            HStack(spacing: 12) {
                TaskIconView(type: task.type, isCompleted: isCompleted, color: iconColor)

                Text(task.title)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(isCompleted ? Color.textTertiary : Color.textPrimary)
                    .lineLimit(1)

                Spacer()

                rightMeta
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isRunning ? Color.accentPrimary.opacity(0.06) : .clear)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.6)
                .onEnded { _ in
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    onLongPress()
                }
        )
    }

    @ViewBuilder
    private var rightMeta: some View {
        if isRunning {
            Text(formatClock(elapsedSeconds))
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.accentPrimary)
                .animation(nil, value: elapsedSeconds)
        } else if isCompleted && workedSeconds > 0 {
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .semibold))
                Text(formatDuration(workedSeconds))
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
            }
            .foregroundStyle(Color.textTertiary)
        } else if let startTime = task.startTime {
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
    let color: Color

    var body: some View {
        ZStack {
            if type == .recurring {
                // Dashed circle
                Circle()
                    .fill(isCompleted ? color : .clear)
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [2.5, 2.5]))
                    .foregroundStyle(color)
            } else {
                // Solid rounded rect
                RoundedRectangle(cornerRadius: 4)
                    .fill(isCompleted ? color : .clear)
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(lineWidth: 1.5)
                    .foregroundStyle(color)
            }

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 22, height: 22)
    }
}
