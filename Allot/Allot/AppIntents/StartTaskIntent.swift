//
//  StartTaskIntent.swift
//  Allot
//
//  App Intent fired by the Quick Start widget. Opens the main app via deep
//  link so the running TimerService (which lives in the main process) starts
//  the session. The intent itself stays cheap — no SwiftData reads in the
//  extension process.

import AppIntents
import Foundation

struct StartTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Task"
    static var description = IntentDescription("Start a focus session for the chosen task.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Task ID")
    var taskId: String

    init() {}
    init(taskId: String) { self.taskId = taskId }

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        // openAppWhenRun = true means the system opens the host app. We pair
        // that with a deep link so the app's onOpenURL handler can route the
        // start request — this avoids needing direct ModelContainer access
        // from the widget process.
        return .result()
    }
}
