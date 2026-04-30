//
//  SettingsView.swift
//  Allot

import SwiftUI

struct SettingsView: View {

    @AppStorage("appColorScheme")               private var colorSchemeString = "system"
    @AppStorage("hasCompletedOnboarding")       private var hasCompletedOnboarding = true
    @AppStorage("focusReminderIntervalMinutes") private var focusReminderIntervalMinutes = 60
    @AppStorage("dynamicIslandEnabled")         private var dynamicIslandEnabled = true
    @AppStorage("showTaskEmoji")                private var showTaskEmoji = true

    @Bindable private var auth = AuthManager.shared

    @Environment(\.colorScheme) private var colorScheme

    /// Toggle "on" tint that stays visible in dark / glass mode.
    /// Light mode keeps the existing label-color chrome; dark mode uses Sky
    /// so the track contrasts with the white thumb on translucent glass.
    private var toggleTint: Color {
        colorScheme == .dark ? Color.tagSky : Color.accentPrimary
    }

    var body: some View {
        List {
            Section("Account") {
                NavigationLink {
                    AccountView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: auth.isSignedIn ? "person.crop.circle.fill" : "person.crop.circle.badge.exclamationmark")
                            .font(.system(size: 22))
                            .foregroundStyle(auth.isSignedIn ? Color.textPrimary : Color.stateDestructive)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(auth.isSignedIn ? (auth.displayName ?? "Signed in") : "Sign in to back up")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.textPrimary)
                            Text(auth.isSignedIn ? "iCloud sync active" : "Protect your data across reinstalls")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            Section("Widgets") {
                NavigationLink {
                    WidgetGalleryView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.3.group")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.textPrimary)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Customize widgets")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.textPrimary)
                            Text("Live Focus, Today, Quick Start, and more")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

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
                .tint(toggleTint)

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

                Toggle(isOn: $showTaskEmoji) {
                    Label("Show task emoji", systemImage: "face.smiling")
                        .foregroundStyle(Color.textPrimary)
                }
                .tint(toggleTint)
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
