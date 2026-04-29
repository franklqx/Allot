//
//  SettingsView.swift
//  Allot

import SwiftUI

struct SettingsView: View {

    @AppStorage("appColorScheme")               private var colorSchemeString = "system"
    @AppStorage("hasCompletedOnboarding")       private var hasCompletedOnboarding = true
    @AppStorage("focusReminderIntervalMinutes") private var focusReminderIntervalMinutes = 60
    @AppStorage("dynamicIslandEnabled")         private var dynamicIslandEnabled = true

    var body: some View {
        List {
            Section("Manage") {
                NavigationLink {
                    TagsView()
                } label: {
                    Label("Tags", systemImage: "tag")
                        .foregroundStyle(Color.textPrimary)
                }
                NavigationLink {
                    AllTasksView()
                } label: {
                    Label("All tasks", systemImage: "list.bullet.rectangle")
                        .foregroundStyle(Color.textPrimary)
                }
                NavigationLink {
                    ArchivedTasksView()
                } label: {
                    Label("Hidden tasks", systemImage: "eye.slash")
                        .foregroundStyle(Color.textPrimary)
                }
            }

            Section {
                Toggle(isOn: $dynamicIslandEnabled) {
                    Label("Dynamic Island", systemImage: "capsule.portrait")
                        .foregroundStyle(Color.textPrimary)
                }
                .tint(Color.accentPrimary)

                NavigationLink {
                    TagsView()
                } label: {
                    HStack {
                        Label("Tags", systemImage: "tag")
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        Text("Edit")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.textTertiary)
                    }
                }

                HStack {
                    Label("Stopwatch reminder", systemImage: "bell")
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Picker("", selection: $focusReminderIntervalMinutes) {
                        Text("Off").tag(0)
                        Text("30m").tag(30)
                        Text("1h").tag(60)
                        Text("2h").tag(120)
                    }
                    .pickerStyle(.menu)
                    .tint(Color.accentPrimary)
                }
            } header: {
                Text("Focus")
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Active focus sessions appear in the Dynamic Island on supported devices (iPhone 14 Pro and later). The left side shows the task emoji, the right side shows the live timer. Long-press the island to expand.")
                    Text("Stopwatch reminders fire at the chosen interval. Countdown sessions always alert at completion.")
                }
            }

            Section("Appearance") {
                HStack {
                    Label("Color Scheme", systemImage: "circle.lefthalf.filled")
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Picker("", selection: $colorSchemeString) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
            }

            Section("About") {
                HStack {
                    Label("Version", systemImage: "info.circle")
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Text(appVersion)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(Color.textSecondary)
                }
                Button {
                    hasCompletedOnboarding = false
                } label: {
                    Label("Replay Onboarding", systemImage: "arrow.counterclockwise")
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(v) (\(b))"
    }
}
