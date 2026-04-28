//
//  StopConfirmView.swift
//  Allot
//
//  Appears after tapping Stop. Stays open until the user picks an action —
//  no auto-dismiss. Three layouts:
//    • duration < 30 s   → discard prompt
//    • unbound session   → attach prompt
//    • bound session     → save prompt (hero duration · meta · actions)

import SwiftUI
import SwiftData

struct StopConfirmView: View {
    let session: TimeSession
    let onDone: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @State private var showDurationEdit = false
    @State private var showAttachSheet  = false
    @State private var editedMinutes: Int

    private var duration: Int {
        guard let end = session.endAt else { return 0 }
        return max(0, Int(end.timeIntervalSince(session.startAt)) - session.totalPausedSeconds)
    }

    private var timeRangeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        let start = f.string(from: session.startAt)
        let end = session.endAt.map { f.string(from: $0) } ?? "—"
        return "\(start) – \(end)"
    }

    init(session: TimeSession, onDone: @escaping () -> Void) {
        self.session = session
        self.onDone = onDone
        _editedMinutes = State(initialValue: max(1, (
            (session.endAt.map { Int($0.timeIntervalSince(session.startAt)) } ?? 0) -
            session.totalPausedSeconds
        ) / 60))
    }

    var body: some View {
        VStack(spacing: 0) {
            GrabberView()

            if duration < 30 {
                discardPrompt
            } else if session.workTask == nil {
                attachPrompt
            } else {
                savePrompt
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.bgElevated.ignoresSafeArea())
        .presentationDetents([
            .height(duration < 30 ? 240 : (session.workTask == nil ? 280 : 320))
        ])
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showDurationEdit) {
            HorizontalSliderView(
                mode: .duration,
                title: "Edit duration",
                valueMinutes: $editedMinutes,
                onDismiss: { showDurationEdit = false }
            )
            .presentationDetents([.height(260)])
            .presentationBackground(Color.black)
        }
        .sheet(isPresented: $showAttachSheet) {
            UnboundSessionAttachSheet(session: session) {
                dismiss()
                onDone()
            }
            .presentationDetents([.large])
            .presentationBackground(Color.bgElevated)
        }
    }

    // MARK: Prompts

    private var savePrompt: some View {
        VStack(spacing: 0) {
            // Hero: duration on left, time range on right — one row, balanced.
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(formatDuration(duration))
                    .font(.system(size: 32, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("Recorded")
                    .font(.system(size: 11, weight: .semibold))
                    .kerning(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.textTertiary)
                Spacer(minLength: 8)
                Text(timeRangeLabel)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 18)

            sheetDivider

            // Meta: task title on the left, tag chip pinned right.
            if let task = session.workTask {
                HStack(spacing: 10) {
                    if let tag = task.tag, !tag.isSystem {
                        Circle()
                            .fill(Color.tagColor(tag.colorToken))
                            .frame(width: 8, height: 8)
                    }
                    Text(task.title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    if let tag = task.tag, !tag.isSystem {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.tagColor(tag.colorToken))
                                .frame(width: 7, height: 7)
                            Text(tag.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.tagColor(tag.colorToken))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Color.tagColorSoft(tag.colorToken),
                            in: RoundedRectangle(cornerRadius: Radius.xs)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
            }

            // Spacer fills the slack so action buttons sit flush at the bottom
            // of the sheet, no awkward gap below them.
            Spacer(minLength: 0)

            actionsBlock {
                ActionButton(label: "Edit", systemImage: "pencil") {
                    showDurationEdit = true
                }
                // "Save" — just stores the time entry; the task's checkbox
                // stays where it was.
                ActionButton(label: "Save", systemImage: "tray.and.arrow.down") {
                    save()
                }
                // "Done" — stores the time entry AND ticks the task complete
                // for today (auto-checks the checkbox).
                ActionButton(label: "Done", systemImage: "checkmark.circle.fill", accent: true) {
                    saveAndMarkDone()
                }
            }
        }
    }

    private var attachPrompt: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(formatDuration(duration))
                    .font(.system(size: 32, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("Unbound")
                    .font(.system(size: 11, weight: .semibold))
                    .kerning(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.textTertiary)
                Spacer(minLength: 8)
                Text(timeRangeLabel)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 18)

            sheetDivider

            HStack {
                Text("Pick a task — every session needs one")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)

            Spacer(minLength: 0)

            actionsBlock {
                ActionButton(label: "Discard", systemImage: "trash", destructive: true) {
                    discard()
                }
                ActionButton(label: "Choose task", systemImage: "link", accent: true) {
                    showAttachSheet = true
                }
            }
        }
    }

    private var discardPrompt: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(formatDuration(duration))
                    .font(.system(size: 32, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)
                Spacer(minLength: 8)
                Text("Under 30 s")
                    .font(.system(size: 11, weight: .semibold))
                    .kerning(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 10)

            HStack {
                Text("That was under 30 seconds. Discard or save anyway?")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 18)

            Spacer(minLength: 0)

            actionsBlock {
                ActionButton(label: "Discard", systemImage: "trash", destructive: true) {
                    modelContext.delete(session)
                    try? modelContext.save()
                    dismiss()
                    onDone()
                }
                ActionButton(label: "Save anyway", systemImage: "checkmark") { save() }
            }
        }
    }

    // MARK: Layout building blocks

    @ViewBuilder
    private func actionsBlock<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 8) {
            content()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 24)
    }

    private var sheetDivider: some View {
        Rectangle()
            .fill(Color.textPrimary.opacity(0.06))
            .frame(height: 1)
    }

    // MARK: Actions

    private func discard() {
        modelContext.delete(session)
        try? modelContext.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
        onDone()
    }

    /// Save the time entry **without** marking the task as completed. Use when
    /// the user did some work but the task is still in progress.
    private func save() {
        applyEditedDurationIfNeeded()
        try? modelContext.save()
        dismiss()
        onDone()
    }

    /// Save the time entry **and** flip the task's checkbox for that day.
    /// Use when the user finished the task in this session.
    private func saveAndMarkDone() {
        applyEditedDurationIfNeeded()
        session.workTask?.markCompleted(on: session.startAt)
        try? modelContext.save()
        dismiss()
        onDone()
    }

    private func applyEditedDurationIfNeeded() {
        guard showDurationEdit, let end = session.endAt else { return }
        let start = end.addingTimeInterval(-TimeInterval(editedMinutes * 60))
        session.startAt = start
        session.totalPausedSeconds = 0
    }
}

private struct ActionButton: View {
    let label: String
    let systemImage: String
    var accent = false
    var destructive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: systemImage).font(.system(size: 12))
                Text(label).font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(
                accent ? .white :
                destructive ? Color.stateDestructive :
                Color.textPrimary
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(
                accent ? Color.accentPrimary : Color.bgSecondary,
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
    }
}
