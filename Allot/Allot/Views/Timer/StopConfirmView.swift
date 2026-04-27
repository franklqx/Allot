//
//  StopConfirmView.swift
//  Allot
//
//  Appears after tapping Stop. Auto-saves in 2 seconds if untouched.
//  Session < 30 s → shows "Discard?" instead.

import SwiftUI
import SwiftData

struct StopConfirmView: View {
    let session: TimeSession
    let onDone: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @State private var countdown = 2
    @State private var showDurationEdit = false
    @State private var showAttachSheet = false
    @State private var editedMinutes: Int

    private var duration: Int {
        guard let end = session.endAt else { return 0 }
        return max(0, Int(end.timeIntervalSince(session.startAt)) - session.totalPausedSeconds)
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
        .background(Color.bgElevated)
        .presentationDetents([.height(session.workTask == nil ? 220 : 200)])
        .presentationDragIndicator(.hidden)
        .task {
            // Only auto-save bound sessions; unbound waits for explicit choice.
            if session.workTask != nil { await autoSave() }
        }
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
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Recorded \(formatDuration(duration))")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                if let task = session.workTask {
                    Text("\"\(task.title)\"")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(.horizontal, 24)

            HStack(spacing: 8) {
                ActionButton(label: "Edit", systemImage: "pencil") {
                    showDurationEdit = true
                }
                ActionButton(label: "Mark done", systemImage: "checkmark") {
                    session.workTask?.markCompleted(on: Date())
                    save()
                }
                ActionButton(
                    label: "Save (\(countdown))",
                    systemImage: "checkmark.circle.fill",
                    accent: true
                ) { save() }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private var attachPrompt: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Recorded \(formatDuration(duration))")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("Pick a task — every session needs one")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, 24)

            HStack(spacing: 8) {
                ActionButton(label: "Discard", systemImage: "trash", destructive: true) {
                    discard()
                }
                ActionButton(
                    label: "Choose task",
                    systemImage: "link",
                    accent: true
                ) {
                    showAttachSheet = true
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private var discardPrompt: some View {
        VStack(spacing: 16) {
            Text("That was under 30 seconds.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
            HStack(spacing: 12) {
                ActionButton(label: "Discard", systemImage: "trash", destructive: true) {
                    modelContext.delete(session)
                    try? modelContext.save()
                    dismiss()
                    onDone()
                }
                ActionButton(label: "Save anyway", systemImage: "checkmark") { save() }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
    }

    // MARK: Actions

    private func discard() {
        modelContext.delete(session)
        try? modelContext.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
        onDone()
    }

    private func save() {
        if showDurationEdit {
            // Apply edited duration
            if let end = session.endAt {
                let start = end.addingTimeInterval(-TimeInterval(editedMinutes * 60))
                session.startAt = start
                session.totalPausedSeconds = 0
            }
        }
        // Any successful session counts as completion for that day.
        session.workTask?.markCompleted(on: session.startAt)
        try? modelContext.save()
        dismiss()
        onDone()
    }

    private func autoSave() async {
        for remaining in stride(from: 2, through: 1, by: -1) {
            try? await Task.sleep(for: .seconds(1))
            countdown = remaining - 1
        }
        try? await Task.sleep(for: .seconds(1))
        save()
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
