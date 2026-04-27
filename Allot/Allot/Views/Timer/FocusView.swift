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

    @State private var stoppedSession: TimeSession?
    @State private var unboundSession: TimeSession?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
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

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                Spacer()

                Text(formatClock(timerService.displaySeconds))
                    .font(.system(size: 92, weight: .light))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .animation(nil, value: timerService.displaySeconds)

                if let task = timerService.activeSession?.workTask {
                    HStack(spacing: 6) {
                        if let tag = task.tag, !tag.isSystem {
                            TagDot(color: Color.tagColor(tag.colorToken), style: .filled, size: 8)
                        }
                        Text(task.title)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.top, 16)
                } else {
                    Text("Unbound session")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.top, 16)
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
                .padding(.bottom, 60)
            }
        }
        .sheet(item: $stoppedSession) { session in
            StopConfirmView(session: session) {
                stoppedSession = nil
                dismiss()
            }
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
