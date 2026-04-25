//
//  FocusTabView.swift
//  Allot
//
//  Dedicated Focus tab (replaces the old pull-down TimerPanelView).
//  Idle: mode picker + task list + Start button.
//  Running: large breathing clock + task + Pause / Stop.
//  Top-right ⛶ opens the full-screen immersive FocusView.

import SwiftUI
import SwiftData

struct FocusTabView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(TimerService.self) private var timerService

    @Query private var allTasks: [WorkTask]

    @State private var modeIndex: Int = 0          // 0=stopwatch, 1-6=countdown presets
    @State private var selectedTaskID: UUID? = nil
    @State private var showImmersive = false
    @State private var stoppedSession: TimeSession?
    @State private var breathe = false

    private let presets: [(String, Int?)] = [
        ("Stopwatch", nil),
        ("15 min", 15),
        ("25 min", 25),
        ("30 min", 30),
        ("45 min", 45),
        ("1 hour", 60),
        ("2 hours", 120),
    ]

    private var todayTasks: [WorkTask] {
        let today = Date()
        return allTasks
            .filter { $0.isScheduled(on: today) && !$0.isCompleted(on: today) }
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
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                if timerService.isRunning {
                    runningView
                } else {
                    idleView
                }
            }
            .navigationTitle("Focus")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showImmersive = true
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .foregroundStyle(Color.textSecondary)
                    }
                    .disabled(!timerService.isRunning)
                    .opacity(timerService.isRunning ? 1 : 0.3)
                }
            }
        }
        .fullScreenCover(isPresented: $showImmersive) {
            FocusView()
        }
        .sheet(item: $stoppedSession) { session in
            StopConfirmView(session: session) { stoppedSession = nil }
        }
    }

    // MARK: Idle view

    private var idleView: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            // Mode clock paged swipe
            TabView(selection: $modeIndex) {
                ForEach(Array(presets.enumerated()), id: \.offset) { index, preset in
                    modeClockPage(label: preset.0, minutes: preset.1)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 180)
            .onChange(of: modeIndex) { _, _ in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }

            // Page dots
            HStack(spacing: 6) {
                ForEach(0..<presets.count, id: \.self) { i in
                    Circle()
                        .fill(modeIndex == i ? Color.textPrimary : Color.textQuaternary)
                        .frame(width: 5, height: 5)
                        .animation(.easeInOut(duration: 0.15), value: modeIndex)
                }
            }
            .padding(.bottom, 24)

            // Task list
            taskPickerList

            Spacer()

            // Start button
            Button(action: startTimer) {
                Text(selectedTaskID == nil ? "Start without task" : "Start")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.bgPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.textPrimary, in: RoundedRectangle(cornerRadius: Radius.md))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 120)  // clear tab bar
        }
    }

    private func modeClockPage(label: String, minutes: Int?) -> some View {
        VStack(spacing: 10) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)

            Text(minutes.map { String(format: "%02d:00", $0 % 60 == 0 && $0 >= 60 ? $0 / 60 : $0) } ?? "00:00")
                .font(.system(size: 88, weight: .thin, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
    }

    private var taskPickerList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Pick a task")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Spacer()
            }
            .padding(.horizontal, 20)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(todayTasks, id: \.id) { task in
                        TaskPickRow(
                            task: task,
                            isSelected: selectedTaskID == task.id,
                            onTap: {
                                selectedTaskID = (selectedTaskID == task.id) ? nil : task.id
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        )
                        Divider()
                            .padding(.leading, 44)
                            .foregroundStyle(Color.textPrimary.opacity(0.06))
                    }
                }
            }
            .frame(maxHeight: 260)
        }
    }

    // MARK: Running view

    private var runningView: some View {
        VStack(spacing: 0) {
            Spacer()

            Text(formatClock(timerService.elapsedSeconds))
                .font(.system(size: 88, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .animation(nil, value: timerService.elapsedSeconds)
                .scaleEffect(breathe ? 1.01 : 1.0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        breathe = true
                    }
                }
                .onDisappear { breathe = false }

            if let task = timerService.activeSession?.workTask {
                HStack(spacing: 6) {
                    if let tag = task.tag, !tag.isSystem {
                        Circle()
                            .fill(Color.tagColor(tag.colorToken))
                            .frame(width: 8, height: 8)
                    }
                    Text(task.title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }
                .padding(.top, 20)
            } else {
                Text("Unbound session")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textTertiary)
                    .padding(.top, 20)
            }

            Spacer()

            HStack(spacing: 16) {
                FocusCircleButton(
                    systemImage: timerService.isPaused ? "play.fill" : "pause.fill",
                    label: timerService.isPaused ? "Resume" : "Pause"
                ) {
                    timerService.isPaused ? timerService.resume() : timerService.pause()
                }

                FocusCircleButton(
                    systemImage: "stop.fill",
                    label: "Stop",
                    isDestructive: true
                ) { stopTimer() }
            }
            .padding(.bottom, 120)
        }
    }

    // MARK: Actions

    private func startTimer() {
        guard !timerService.isRunning else { return }
        let preset = presets[modeIndex]
        let task = todayTasks.first(where: { $0.id == selectedTaskID })

        if let task = task {
            if let minutes = preset.1 {
                task.timerMode = .countdown
                task.countdownDuration = minutes * 60
            } else {
                task.timerMode = .stopwatch
            }
            timerService.start(task: task, in: modelContext)
        } else {
            timerService.startUnbound(in: modelContext)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func stopTimer() {
        timerService.stop(in: modelContext)
        let descriptor = FetchDescriptor<TimeSession>(
            sortBy: [SortDescriptor(\.startAt, order: .reverse)]
        )
        stoppedSession = try? modelContext.fetch(descriptor).first
    }
}

// MARK: Task pick row

private struct TaskPickRow: View {
    let task: WorkTask
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if let tag = task.tag, !tag.isSystem {
                    Circle()
                        .fill(Color.tagColor(tag.colorToken))
                        .frame(width: 8, height: 8)
                } else {
                    Circle()
                        .fill(Color.textTertiary)
                        .frame(width: 8, height: 8)
                }

                Text(task.title)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.textPrimary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color.textPrimary.opacity(0.04) : .clear)
    }
}

// MARK: Circle control button

private struct FocusCircleButton: View {
    let systemImage: String
    let label: String
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isDestructive ? Color.stateDestructive : Color.textPrimary)
                    .frame(width: 60, height: 60)
                    .background(
                        (isDestructive ? Color.stateDestructive : Color.textPrimary).opacity(0.08),
                        in: Circle()
                    )
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .buttonStyle(.plain)
    }
}
