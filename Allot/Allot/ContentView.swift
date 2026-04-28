//
//  ContentView.swift
//  Allot
//
//  Root shell. Native iOS 26 Liquid Glass TabView:
//    • 3 regular Tabs on the left (pill)
//    • 1 Tab(role: .search) repurposed as the + action (detached right pill)
//  Selecting the + "tab" opens New Task and snaps the selection back.

import SwiftUI
import SwiftData

private enum AppTab: Hashable { case home, focus, allotted, add }

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TimerService.self) private var timerService

    @State private var selectedTab: AppTab = .home
    @State private var lastRealTab: AppTab = .home
    @State private var showNewTask = false
    @State private var recoverySentinel: ActiveSessionSentinel?
    @State private var homeSelectedDate: Date = Date()

    /// Custom selection binding — when user taps the .add (FAB) tab we run
    /// `handleAddTap()` but never write `.add` into `selectedTab`, so the
    /// TabView's content never flips to the placeholder Color.clear and we
    /// avoid the visible flash on FAB-to-today.
    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { selectedTab },
            set: { new in
                if new == .add {
                    handleAddTap()
                } else {
                    selectedTab = new
                    lastRealTab = new
                }
            }
        )
    }

    var body: some View {
        TabView(selection: tabSelection) {
            SwiftUI.Tab("Home", systemImage: "house", value: AppTab.home) {
                HomeView(
                    selectedDate: $homeSelectedDate,
                    onStart: { task in startTaskAndJumpToFocus(task) }
                )
            }
            SwiftUI.Tab("Focus", systemImage: "timer", value: AppTab.focus) {
                FocusTabView()
            }
            SwiftUI.Tab("Allotted", systemImage: "chart.bar.xaxis", value: AppTab.allotted) {
                AllottedView()
            }
            // Repurposed search slot — detached right pill.
            // The custom binding above intercepts taps so we never actually
            // switch to this tab; the placeholder content is unreachable.
            SwiftUI.Tab("Add", systemImage: fabIcon, value: AppTab.add, role: .search) {
                Color.clear
            }
        }
        .tint(Color.textPrimary)
        .sheet(isPresented: $showNewTask) {
            NewTaskView(prefilledDate: homeSelectedDate)
                .presentationDetents([.large])
        }
        .onAppear(perform: checkKillRecovery)
        .alert("Timer was running", isPresented: Binding(
            get: { recoverySentinel != nil },
            set: { if !$0 { recoverySentinel = nil } }
        )) {
            Button("Save") {
                if let s = recoverySentinel { timerService.recoverSession(for: s, in: modelContext) }
                recoverySentinel = nil
            }
            Button("Discard", role: .destructive) {
                timerService.discardKillRecovery()
                recoverySentinel = nil
            }
        } message: {
            if let s = recoverySentinel {
                Text("Your timer for \"\(s.taskTitle)\" was still running. Save with end time set to now?")
            }
        }
    }

    // MARK: Derived

    /// Default `+` uses the filled-disc variant (dark ring CTA).
    /// Non-today swaps to a plain calendar hint (tap jumps back to today).
    /// Timer-running does NOT override — add is always available.
    private var fabIcon: String {
        if !Calendar.current.isDateInToday(homeSelectedDate) { return "calendar" }
        return "plus.circle.fill"
    }

    // MARK: Actions

    private func handleAddTap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        // Anchor is shared with Allotted, so this also resets that tab.
        // Stay on whichever tab the user was on (lastRealTab is already set).
        if !Calendar.current.isDateInToday(homeSelectedDate) {
            homeSelectedDate = Date()
            return
        }
        showNewTask = true
    }

    private func startTaskAndJumpToFocus(_ task: WorkTask) {
        guard !timerService.isRunning else {
            selectedTab = .focus
            return
        }
        task.timerMode = .stopwatch
        timerService.start(task: task, in: modelContext)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        // Snap directly to focus — animating the tab switch creates a fade
        // that combines unpleasantly with the immersive cover presentation.
        selectedTab = .focus
    }

    private func checkKillRecovery() {
        guard !timerService.isRunning,
              let sentinel = timerService.killRecoverySentinel else { return }
        recoverySentinel = sentinel
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Tag.self, WorkTask.self, TimeSession.self,
        configurations: config
    )
    return ContentView()
        .modelContainer(container)
        .environment(TimerService())
}
