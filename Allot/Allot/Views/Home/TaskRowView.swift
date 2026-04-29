//
//  TaskRowView.swift
//  Allot
//
//  Single task row. Two independent tap targets:
//    • LEFT icon (TaskBox / running clock) → tap triggers completion flow
//    • ROW body → tap opens action sheet: Start / Adjust / Remove
//
//  Visual rule: tasks are always squares (TaskBox). Tags are always circles.
//  Right meta always shows the planned start time (if any). When completed,
//  the actual worked duration appears as a small subtitle under the title.

import SwiftUI

struct TaskRowView: View {
    let task: WorkTask
    let date: Date
    let isRunning: Bool
    let timerSeconds: Int
    let isCountingDown: Bool
    let onIconTap: () -> Void
    let onRowTap: () -> Void

    private var isCompleted: Bool { task.isCompleted(on: date) }
    private var workedSeconds: Int { task.workedSeconds(on: date) }
    private var countdownSeconds: Int? {
        task.timerMode == .countdown ? task.countdownDuration : nil
    }

    /// Box color. Even when completed we keep the original tag color so the
    /// row still reads as that tag — the gray checkmark inside is the
    /// completion signal.
    private var iconColor: Color {
        if let tag = task.tag, !tag.isSystem { return Color.tagColor(tag.colorToken) }
        return Color.textSecondary
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onIconTap) {
                TaskIconView(
                    type: task.type,
                    isCompleted: isCompleted,
                    isRunning: isRunning,
                    color: iconColor
                )
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .frame(width: 28, height: 28)

            Button(action: onRowTap) {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(isCompleted ? Color.textTertiary : Color.textPrimary)
                            .lineLimit(1)

                        if workedSeconds > 0 || countdownSeconds != nil {
                            HStack(spacing: 8) {
                                if workedSeconds > 0 {
                                    Text(formatDuration(workedSeconds))
                                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                                        .foregroundStyle(Color.textTertiary)
                                }
                                if let countdownSeconds {
                                    HStack(spacing: 3) {
                                        Image(systemName: "hourglass")
                                            .font(.system(size: 10, weight: .semibold))
                                        Text(formatDuration(countdownSeconds))
                                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                                    }
                                    .foregroundStyle(Color.textTertiary)
                                }
                            }
                        }
                    }

                    Spacer()

                    rightMeta
                }
                // Pin overall row body height so rows with / without a
                // duration line stay the same vertical size, but the title
                // sits in the vertical center when there is no duration.
                .frame(minHeight: 36)
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
        if isRunning {
            // Live ticker takes the same slot as the planned start time so
            // running tasks read as "this is the time on this row" rather than
            // hiding the icon behind a number.
            HStack(spacing: 4) {
                if isCountingDown {
                    Image(systemName: "hourglass")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                }
                Text(compactClock(timerSeconds))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .animation(nil, value: timerSeconds)
            }
        } else if let startTime = task.startTime {
            Text(formatStartTime(startTime))
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .foregroundStyle(isCompleted ? Color.textTertiary : Color.textSecondary)
        }
    }
}

private func compactClock(_ seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    if m >= 60 { return String(format: "%d:%02d", m/60, m%60) }
    return String(format: "%d:%02d", m, s)
}

// MARK: Task type icon

private struct TaskIconView: View {
    let type: TaskType
    let isCompleted: Bool
    let isRunning: Bool
    let color: Color

    var body: some View {
        ZStack {
            TaskBox(
                color: color,
                style: TaskBox.style(for: type),
                size: 22,
                cornerRadius: 5
            )

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.textTertiary)
            }
        }
    }
}
