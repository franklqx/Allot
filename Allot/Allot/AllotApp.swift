//
//  AllotApp.swift
//  Allot

import SwiftUI
import SwiftData

@main
struct AllotApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Tag.self, WorkTask.self, TimeSession.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var timerService = TimerService()

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appColorScheme")         private var colorSchemeString       = "system"

    private var preferredColorScheme: ColorScheme? {
        switch colorSchemeString {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView { hasCompletedOnboarding = true }
                }
            }
            .environment(timerService)
            .preferredColorScheme(preferredColorScheme)
            .onAppear {
                Seed.insertSystemTagsIfNeeded(in: sharedModelContainer.mainContext)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
