//
//  AllotApp.swift
//  Allot
//
//  Created by Frank Li on 4/16/26.
//

import SwiftUI
import SwiftData

@main
struct AllotApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Tag.self,
            WorkTask.self,
            TimeSession.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
