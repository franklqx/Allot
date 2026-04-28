//
//  OncePanelView.swift
//  Allot
//
//  Short bottom-sheet for Once tasks. Fixed height — cannot expand.

import SwiftUI
import SwiftData

struct OncePanelView: View {
    let task: WorkTask
    let date: Date
    let onEdit: () -> Void
    var onStart: () -> Void = {}

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showRemoveConfirm = false

    private var isCompleted: Bool { task.isCompleted(on: date) }
    private var workedSeconds: Int { task.workedSeconds(on: date) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GrabberView()

            VStack(alignment: .leading, spacing: 0) {
                // Title row — task name on the left, worked duration on the
                // far right at a size that visually pairs with (but doesn't
                // overpower) the title.
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(task.title)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    if workedSeconds > 0 {
                        Text(formatDuration(workedSeconds))
                            .font(.system(size: 18, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .padding(.top, 12)

                // Date · startTime
                HStack(spacing: 6) {
                    Text(date.formatted(.dateTime.month(.abbreviated).day().year()))
                        .foregroundStyle(Color.textSecondary)
                    if let st = task.startTime {
                        Text("·")
                            .foregroundStyle(Color.textTertiary)
                        Text(formatStartTime(st))
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .font(.subheadline)
                .padding(.top, 6)

                // Tag chip (only if not Untagged)
                if let tag = task.tag, !tag.isSystem {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.tagColor(tag.colorToken))
                            .frame(width: 7, height: 7)
                        Text(tag.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.tagColor(tag.colorToken))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.tagColorSoft(tag.colorToken), in: RoundedRectangle(cornerRadius: Radius.xs))
                    .padding(.top, 10)
                }

                TaskDaySessionsList(task: task, date: date)
                    .padding(.top, 16)

                // Actions
                VStack(spacing: 8) {
                    Button {
                        dismiss()
                        onStart()
                    } label: {
                        Label("Start", systemImage: "play.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.bgPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.textPrimary, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 8) {
                        Button {
                            dismiss()
                            onEdit()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.bgSecondary, in: Capsule())
                        }
                        .buttonStyle(.plain)

                        Button(role: .destructive) {
                            showRemoveConfirm = true
                        } label: {
                            Label("Remove", systemImage: "trash")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.stateDestructive)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.bgSecondary, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 20)

                Text("Created \(task.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 14)
        }
        .background(Color.bgElevated)
        .confirmationDialog("Remove \"\(task.title)\"?", isPresented: $showRemoveConfirm, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                modelContext.delete(task)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

}
