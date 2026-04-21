//
//  ContentView.swift
//  Allot
//
//  Root shell: Liquid Glass TabView + Timer FAB + top-sliding Timer panel.

import SwiftUI
import SwiftData

private enum Tab: Hashable { case home, allotted }

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TimerService.self) private var timerService

    @State private var selectedTab: Tab = .home
    @State private var showTimerPanel = false
    @State private var showNewTask = false
    @State private var recoverySentinel: ActiveSessionSentinel?
    @State private var homeSelectedDate: Date = Date()

    var body: some View {
        ZStack(alignment: .top) {

            // ── Main content ────────────────────────────────────
            ZStack(alignment: .bottomTrailing) {
                TabView(selection: $selectedTab) {
                    HomeView(
                        selectedDate: $homeSelectedDate,
                        onShowTimer: { withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { showTimerPanel = true } }
                    )
                    .tabItem { Label("Home", systemImage: selectedTab == .home ? "house.fill" : "house") }
                    .tag(Tab.home)

                    AllottedView()
                        .tabItem { Label("Allotted", systemImage: selectedTab == .allotted ? "chart.pie.fill" : "chart.pie") }
                        .tag(Tab.allotted)
                }
                .tint(Color.accentPrimary)

                TimerFABButton(
                    isRunning: timerService.isRunning,
                    isViewingToday: Calendar.current.isDateInToday(homeSelectedDate),
                    action: {
                        if !Calendar.current.isDateInToday(homeSelectedDate) {
                            homeSelectedDate = Date()
                        } else {
                            showNewTask = true
                        }
                    }
                )
                .padding(.trailing, 20)
                .padding(.bottom, 20)
                .ignoresSafeArea(edges: .bottom)
            }
            .zIndex(0)

            // ── Timer panel backdrop ────────────────────────────
            if showTimerPanel {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showTimerPanel = false
                        }
                    }
                    .zIndex(1)
            }

            // ── Timer panel (slides from top) ───────────────────
            if showTimerPanel {
                TimerPanelView(
                    selectedDate: homeSelectedDate,
                    onDismiss: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showTimerPanel = false
                        }
                    }
                )
                .frame(maxWidth: .infinity)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(2)
            }

            // ── Top-edge drag trigger ───────────────────────────
            if !showTimerPanel {
                Color.clear
                    .frame(height: 50)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 20, coordinateSpace: .local)
                            .onEnded { value in
                                if value.translation.height > 30 {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        showTimerPanel = true
                                    }
                                }
                            }
                    )
                    .zIndex(3)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showTimerPanel)
        .fullScreenCover(isPresented: $showNewTask) {
            NewTaskView(prefilledDate: homeSelectedDate)
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
