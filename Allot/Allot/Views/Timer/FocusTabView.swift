//
//  FocusTabView.swift
//  Allot
//
//  Idle: mode picker + circular Start button + task list.
//  Running: large breathing clock + Pause / Stop.
//  Top-right toolbar opens FocusHistoryView.
//  Starting the timer auto-presents the immersive FocusView (full-screen).
//

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
    @State private var unboundSession: TimeSession?
    @State private var showHistory = false
    /// Last session id the user explicitly dismissed from the immersive view.
    /// Prevents re-entering the Focus tab from auto-presenting full-screen
    /// again for the same running session.
    @State private var dismissedSessionId: UUID? = nil

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
            .filter { $0.archivedAt == nil }
            .filter { $0.isScheduled(on: today) && !$0.isCompleted(on: today) }
            .sorted {
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if timerService.isRunning {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismissedSessionId = nil
                            showImmersive = true
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .foregroundStyle(Color.textSecondary)
                        }
                        .accessibilityLabel("Enter focus mode")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .navigationDestination(isPresented: $showHistory) {
                FocusHistoryView()
            }
            .onAppear {
                // Auto-present full-screen when entering the Focus tab WITH a
                // running session — but only if the user hasn't already
                // dismissed full-screen for this same session.
                if let id = timerService.activeSession?.id,
                   dismissedSessionId != id,
                   !showImmersive {
                    showImmersive = true
                }
            }
            .onChange(of: timerService.isRunning) { wasRunning, isRunning in
                if !wasRunning && isRunning && !showImmersive {
                    showImmersive = true
                }
            }
            .onChange(of: showImmersive) { _, isShowing in
                // Capture which session the user just dismissed so re-entering
                // the tab doesn't reopen it.
                if !isShowing, let id = timerService.activeSession?.id {
                    dismissedSessionId = id
                }
            }
        }
        .fullScreenCover(isPresented: $showImmersive) {
            FocusView()
        }
        .sheet(item: $stoppedSession) { session in
            StopConfirmView(session: session) { stoppedSession = nil }
        }
        .sheet(item: $unboundSession) { session in
            UnboundSessionAttachSheet(session: session) { unboundSession = nil }
                .presentationDetents([.large])
                .presentationBackground(Color.bgElevated)
        }
    }

    // MARK: Idle view

    private var idleView: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 8)

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

            HStack(spacing: 6) {
                ForEach(0..<presets.count, id: \.self) { i in
                    Circle()
                        .fill(modeIndex == i ? Color.textPrimary : Color.textQuaternary)
                        .frame(width: 5, height: 5)
                        .animation(.easeInOut(duration: 0.15), value: modeIndex)
                }
            }
            .padding(.bottom, 20)

            startButton
                .padding(.bottom, 24)

            taskPickerList
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
                .font(.system(size: 88, weight: .thin))
                .foregroundStyle(Color.textPrimary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
    }

    private var startButton: some View {
        Button(action: startTimer) {
            ZStack {
                Circle()
                    .fill(Color.textPrimary)
                    .frame(width: 76, height: 76)
                Image(systemName: "play.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Color.bgPrimary)
                    .offset(x: 2)
            }
        }
        .buttonStyle(.plain)
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
                        DottedDivider()
                    }
                    Color.clear.frame(height: 100)   // tab-bar inset
                }
            }
        }
    }

    // MARK: Running view

    private var runningView: some View {
        VStack(spacing: 0) {
            Spacer()

            Text(formatClock(timerService.displaySeconds))
                .font(.system(size: 88, weight: .light))
                .monospacedDigit()
                .foregroundStyle(Color.textPrimary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .animation(nil, value: timerService.displaySeconds)

            if let task = timerService.activeSession?.workTask {
                HStack(spacing: 6) {
                    if let tag = task.tag, !tag.isSystem {
                        TagDot(color: Color.tagColor(tag.colorToken), style: .filled, size: 8)
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
        let countdownSeconds = preset.1.map { $0 * 60 }
        let task = todayTasks.first(where: { $0.id == selectedTaskID })

        if let task = task {
            if let cs = countdownSeconds {
                task.timerMode = .countdown
                task.countdownDuration = cs
            } else {
                task.timerMode = .stopwatch
            }
            timerService.start(task: task, countdownSeconds: countdownSeconds, in: modelContext)
        } else {
            timerService.startUnbound(countdownSeconds: countdownSeconds, in: modelContext)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        showImmersive = true
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

// MARK: Task pick row

private struct TaskPickRow: View {
    let task: WorkTask
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if let tag = task.tag, !tag.isSystem {
                    TagDot(color: Color.tagColor(tag.colorToken), style: .filled, size: 8)
                } else {
                    TagDot(color: Color.textTertiary, style: .filled, size: 8)
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

struct FocusCircleButton: View {
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
