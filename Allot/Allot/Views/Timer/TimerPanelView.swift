//
//  TimerPanelView.swift
//  Allot
//
//  Quarter-screen panel that slides down from the top.
//  Idle: swipe left/right to pick Stopwatch or countdown preset, tap a task to start.
//  Running: big clock + Pause / Stop.
//  Pull down further → FocusView (full-screen).

import SwiftUI
import SwiftData

struct TimerPanelView: View {

    let selectedDate: Date
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(TimerService.self) private var timerService

    @Query private var allTasks: [WorkTask]

    @State private var modeIndex: Int = 0          // 0=stopwatch, 1-6=countdown presets
    @State private var showFocus = false
    @State private var stoppedSession: TimeSession?
    @State private var dragY: CGFloat = 0

    private let presets: [(String, Int?)] = [
        ("Stopwatch", nil),
        ("15 min", 15), ("25 min", 25), ("30 min", 30),
        ("45 min", 45), ("1 hour", 60), ("2 hours", 120),
    ]

    private var todayTasks: [WorkTask] {
        allTasks
            .filter { $0.isScheduled(on: selectedDate) }
            .sorted {
                switch ($0.startTime, $1.startTime) {
                case (let a?, let b?): return a < b
                case (nil, nil):       return $0.createdAt < $1.createdAt
                case (_?, nil):        return true
                case (nil, _?):        return false
                }
            }
    }

    // MARK: Body

    var body: some View {
        ZStack(alignment: .bottom) {
            // Dark glass background
            RoundedRectangle(cornerRadius: Radius.xl)
                .fill(.black.opacity(0.94))
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                dragHandle

                if timerService.isRunning {
                    runningView
                } else {
                    idleView
                }
            }
        }
        .gesture(
            DragGesture()
                .onChanged { v in dragY = v.translation.height }
                .onEnded { v in
                    dragY = 0
                    if v.translation.height > 60 { showFocus = true }
                    else if v.translation.height < -40 { onDismiss() }
                }
        )
        .fullScreenCover(isPresented: $showFocus) {
            FocusView()
        }
        .sheet(item: $stoppedSession) { session in
            StopConfirmView(session: session) {
                stoppedSession = nil
                onDismiss()
            }
        }
        .offset(y: max(0, dragY))
    }

    // MARK: Drag handle

    private var dragHandle: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 99)
                .fill(.white.opacity(0.25))
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            Text("↑ Swipe up to close  ↓ Swipe down for focus")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(.bottom, 4)
    }

    // MARK: Idle view

    private var idleView: some View {
        VStack(spacing: 0) {
            // Mode clock — swipeable
            TabView(selection: $modeIndex) {
                ForEach(Array(presets.enumerated()), id: \.offset) { index, preset in
                    modeClockPage(label: preset.0, minutes: preset.1)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 96)
            .onChange(of: modeIndex) { _, _ in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }

            // Page dots
            HStack(spacing: 6) {
                ForEach(0..<presets.count, id: \.self) { i in
                    Circle()
                        .fill(modeIndex == i ? Color.accentPrimary : .white.opacity(0.25))
                        .frame(width: 5, height: 5)
                        .animation(.easeInOut(duration: 0.15), value: modeIndex)
                }
            }
            .padding(.bottom, 12)

            Divider().background(.white.opacity(0.1))

            // Task list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(todayTasks, id: \.id) { task in
                        PanelTaskRow(task: task, date: selectedDate) {
                            startTimer(task: task)
                        }
                        Divider().padding(.leading, 44).background(.white.opacity(0.08))
                    }

                    // Unbound start
                    Button {
                        startUnbound()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.4))
                                .frame(width: 22)
                            Text("Start without task")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.45))
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxHeight: 180)
        }
        .padding(.bottom, 16)
    }

    private func modeClockPage(label: String, minutes: Int?) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
            Text(minutes.map { formatDuration($0 * 60) } ?? "00:00")
                .font(.system(size: 52, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
        }
    }

    // MARK: Running view

    private var runningView: some View {
        VStack(spacing: 0) {
            // Big clock
            Text(formatClock(timerService.displaySeconds))
                .font(.system(size: 60, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .animation(nil, value: timerService.displaySeconds)
                .padding(.vertical, 12)

            // Task info
            if let task = timerService.activeSession?.workTask {
                HStack(spacing: 6) {
                    if let tag = task.tag {
                        Circle()
                            .fill(Color.tagColor(tag.colorToken))
                            .frame(width: 8, height: 8)
                    }
                    Text(task.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                }
                .padding(.bottom, 4)

                HStack(spacing: 8) {
                    Text("Today: \(formatDuration(task.workedSeconds(on: selectedDate)))")
                    Text("·")
                    Text("Total: \(formatDuration(task.workedSecondsTotal))")
                }
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.45))
                .padding(.bottom, 16)
            } else {
                Text("Unbound session")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom, 16)
            }

            // Pause + Stop
            HStack(spacing: 16) {
                CircleControlButton(
                    systemImage: timerService.isPaused ? "play.fill" : "pause.fill",
                    label: timerService.isPaused ? "Resume" : "Pause"
                ) {
                    timerService.isPaused ? timerService.resume() : timerService.pause()
                }

                CircleControlButton(systemImage: "stop.fill", label: "Stop", isStop: true) {
                    stopTimer()
                }
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: Actions

    private func startTimer(task: WorkTask) {
        guard !timerService.isRunning else { return }
        let preset = presets[modeIndex]
        let countdownSeconds = preset.1.map { $0 * 60 }
        if let countdownSeconds {
            task.timerMode = .countdown
            task.countdownDuration = countdownSeconds
        } else {
            task.timerMode = .stopwatch
        }
        timerService.start(task: task, countdownSeconds: countdownSeconds, in: modelContext)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func startUnbound() {
        guard !timerService.isRunning else { return }
        let countdownSeconds = presets[modeIndex].1.map { $0 * 60 }
        timerService.startUnbound(countdownSeconds: countdownSeconds, in: modelContext)
    }

    private func stopTimer() {
        timerService.stop(in: modelContext)
        let descriptor = FetchDescriptor<TimeSession>(
            sortBy: [SortDescriptor(\.startAt, order: .reverse)]
        )
        stoppedSession = try? modelContext.fetch(descriptor).first
    }
}

// MARK: Sub-components

private struct PanelTaskRow: View {
    let task: WorkTask
    let date: Date
    let onTap: () -> Void

    private var isCompleted: Bool { task.isCompleted(on: date) }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                if let tag = task.tag {
                    Circle()
                        .fill(Color.tagColor(tag.colorToken).opacity(isCompleted ? 0.4 : 1))
                        .frame(width: 8, height: 8)
                        .padding(.leading, 12)
                } else {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 8, height: 8)
                        .padding(.leading, 12)
                }
                Text(task.title)
                    .font(.system(size: 15))
                    .foregroundStyle(isCompleted ? .white.opacity(0.35) : .white.opacity(0.85))
                    .lineLimit(1)
                Spacer()
                if let st = task.startTime {
                    Text(formatStartTime(st))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                }
                Image(systemName: "play.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.accentPrimary.opacity(0.7))
                    .padding(.trailing, 16)
            }
            .padding(.vertical, 11)
        }
        .buttonStyle(.plain)
    }
}

private struct CircleControlButton: View {
    let systemImage: String
    let label: String
    var isStop = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 20))
                    .foregroundStyle(isStop ? Color.accentPrimary : .white)
                    .frame(width: 56, height: 56)
                    .background(
                        isStop
                            ? Color.accentPrimary.opacity(0.18)
                            : .white.opacity(0.12),
                        in: Circle()
                    )
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
    }
}
