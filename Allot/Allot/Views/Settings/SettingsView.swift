//
//  SettingsView.swift
//  Allot

import SwiftUI

struct SettingsView: View {

    @AppStorage("appColorScheme")          private var colorSchemeString = "system"
    @AppStorage("hasCompletedOnboarding")  private var hasCompletedOnboarding = true

    var body: some View {
        List {
            Section("Manage") {
                NavigationLink {
                    TagsView()
                } label: {
                    Label("Tags", systemImage: "tag")
                        .foregroundStyle(Color.textPrimary)
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
