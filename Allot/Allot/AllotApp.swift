//
//  AllotApp.swift
//  Allot

import SwiftUI
import SwiftData

@main
struct AllotApp: App {
    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Tag.self, WorkTask.self, TimeSession.self])

        // Try CloudKit-backed container first. Falls back to local-only if iCloud
        // isn't entitled, the user is signed out of iCloud, or signing rejects
        // the entitlement (typical in simulator without dev account).
        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.EL.fire.Allot1")
        )
        do {
            return try ModelContainer(for: schema, configurations: [cloudConfig])
        } catch {
            print("⚠️ CloudKit ModelContainer failed, falling back to local: \(error)")
        }

        let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [localConfig])
        } catch {
            print("❌ Local ModelContainer also failed: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var timerService = TimerService(
        systemIntegrationsEnabled: !AllotApp.isRunningTests
    )

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
            .task {
                await AuthManager.shared.restore()
                CloudKitAvailability.shared.refresh()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
