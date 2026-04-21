//
//  FocusView.swift
//  Allot
//
//  Full-screen immersive focus mode. Triggered by dragging the timer panel further down.
//  ✕ exits back to quarter panel (timer keeps running). Stop ends the session.

import SwiftUI
import SwiftData

struct FocusView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TimerService.self) private var timerService
    @Environment(\.dismiss) private var dismiss

    @State private var stoppedSession: TimeSession?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button {
                        dismiss()  // back to quarter panel, timer keeps running
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(12)
                            .background(.white.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        stopTimer()
                    } label: {
                        Text("Stop")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.accentPrimary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.accentPrimary.opacity(0.15), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Huge clock
                Text(formatClock(timerService.elapsedSeconds))
                    .font(.system(size: 80, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                    .animation(nil, value: timerService.elapsedSeconds)

                // Task name
                if let task = timerService.activeSession?.workTask {
                    HStack(spacing: 6) {
                        if let tag = task.tag {
                            Circle()
                                .fill(Color.tagColor(tag.colorToken))
                                .frame(width: 8, height: 8)
                        }
                        Text(task.title)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.top, 16)
                } else {
                    Text("Unbound session")
                        .font(.system(size: 17))
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.top, 16)
                }

                Spacer()

                // Pause button
                Button {
                    timerService.isPaused ? timerService.resume() : timerService.pause()
                } label: {
                    Image(systemName: timerService.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .background(.white.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 60)
            }
        }
        .sheet(item: $stoppedSession) { session in
            StopConfirmView(session: session) {
                stoppedSession = nil
                dismiss()
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true  // keep screen on in focus mode
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private func stopTimer() {
        timerService.stop(in: modelContext)
        // Get the most recent session for the confirm sheet
        // (TimerService sets endAt before clearing activeSession)
        // We snapshot it before stop clears state by reading the result
        // Re-fetch latest session via a quick query
        let descriptor = FetchDescriptor<TimeSession>(
            sortBy: [SortDescriptor(\.startAt, order: .reverse)]
        )
        stoppedSession = try? modelContext.fetch(descriptor).first
    }
}
