//
//  FocusView.swift
//  Allot
//
//  Full-screen immersive focus mode. Small chevron-down at top-left exits back
//  to the Focus tab (timer keeps running). Pause + Stop circle buttons at the
//  bottom; stopping ends the session and dismisses on confirmation.
//

import SwiftUI
import SwiftData

struct FocusView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TimerService.self) private var timerService
    @Environment(\.dismiss) private var dismiss
    @AppStorage("showTaskEmoji") private var showTaskEmoji = true

    @State private var stoppedSession: TimeSession?
    @State private var unboundSession: TimeSession?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Timer is anchored to the true screen center (status bar +
            // home indicator included) so it always reads as visually
            // centered no matter how tall the chrome above/below is.
            Text(formatClock(timerService.displaySeconds))
                .font(.system(size: 92, weight: .light))
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .animation(nil, value: timerService.displaySeconds)

            // Chrome stays inside the safe area so chevron, tag chip and
            // bottom buttons don't collide with status bar / home indicator.
            VStack(spacing: 0) {
                // Top bar: chevron-down on the left, tag chip + title stacked
                // below as the header. Sits flush at the top of the screen.
                HStack(alignment: .top, spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.45))
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .overlay(alignment: .top) {
                    headerBlock
                        .padding(.top, 4)
                        .padding(.horizontal, 56)
                }

                Spacer()

                HStack(spacing: 28) {
                    DarkCircleButton(
                        systemImage: timerService.isPaused ? "play.fill" : "pause.fill",
                        label: timerService.isPaused ? "Resume" : "Pause"
                    ) {
                        timerService.isPaused ? timerService.resume() : timerService.pause()
                    }
                    DarkCircleButton(
                        systemImage: "stop.fill",
                        label: "Stop",
                        isDestructive: true
                    ) {
                        stopTimer()
                    }
                }
                .padding(.bottom, 36)
            }
        }
        .sheet(item: $stoppedSession) { session in
            StopConfirmView(session: session) {
                stoppedSession = nil
                dismiss()
            }
            .presentationBackground(Color.bgElevated)
        }
        .sheet(item: $unboundSession) { session in
            UnboundSessionAttachSheet(session: session) {
                unboundSession = nil
                dismiss()
            }
            .presentationDetents([.large])
            .presentationBackground(Color.bgElevated)
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    @ViewBuilder
    private var headerBlock: some View {
        VStack(spacing: 12) {
            if let task = timerService.activeSession?.workTask {
                if let tag = task.tag, !tag.isSystem {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.tagColor(tag.colorToken))
                            .frame(width: 8, height: 8)
                        Text(tag.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.tagColor(tag.colorToken))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Color.tagColor(tag.colorToken).opacity(0.18),
                        in: Capsule()
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                Color.tagColor(tag.colorToken).opacity(0.35),
                                lineWidth: 1
                            )
                    )
                } else {
                    Text("Untagged")
                        .font(.system(size: 12, weight: .semibold))
                        .kerning(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.4))
                }
                Text(task.displayTitle(showEmoji: showTaskEmoji))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            } else {
                Text("Unbound")
                    .font(.system(size: 12, weight: .semibold))
                    .kerning(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.vertical, 7)
                    .padding(.horizontal, 14)
                    .background(.white.opacity(0.06), in: Capsule())
                Text("Unbound session")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    private func stopTimer() {
        timerService.stop(in: modelContext)
        let descriptor = FetchDescriptor<TimeSession>(
            sortBy: [SortDescriptor(\.startAt, order: .reverse)]
        )
        guard let session = try? modelContext.fetch(descriptor).first else { return }
        if session.workTask == nil {
            unboundSession = session
        } else {
            stoppedSession = session
        }
    }
}

private struct DarkCircleButton: View {
    let systemImage: String
    let label: String
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(isDestructive ? Color.stateDestructive : .white)
                    .frame(width: 72, height: 72)
                    .background(
                        (isDestructive ? Color.stateDestructive : Color.white).opacity(0.14),
                        in: Circle()
                    )
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .buttonStyle(.plain)
    }
}
