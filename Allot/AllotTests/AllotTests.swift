//
//  AllotTests.swift
//  AllotTests
//

import XCTest
import SwiftData
@testable import Allot

@MainActor
final class AllotTests: XCTestCase {

    // MARK: - Schema

    func testModelContainerSchemaIncludesDomainModels() throws {
        let schema = Schema([Tag.self, WorkTask.self, TimeSession.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        XCTAssertNotNil(container)
    }

    // MARK: - Round-trip

    func testInsertTaskWithTagAndSessionRoundTrip() throws {
        let context = try makeContext()

        let tag = Tag(name: "工作")
        context.insert(tag)

        let task = WorkTask(title: "写代码", tag: tag)
        context.insert(task)

        let session = TimeSession(
            startAt: Date(),
            endAt: Date().addingTimeInterval(3600),
            source: .liveTimer,
            workTask: task
        )
        context.insert(session)

        try context.save()

        let fetched = try context.fetch(FetchDescriptor<WorkTask>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.tag?.name, "工作")
        XCTAssertEqual(fetched.first?.sessions.count, 1)
    }

    // MARK: - Cascade

    func testDeleteTaskCascadesToSessions() throws {
        let context = try makeContext()

        let task = WorkTask(title: "ToDelete")
        context.insert(task)
        let session = TimeSession(
            startAt: Date(),
            endAt: Date().addingTimeInterval(300),
            source: .liveTimer,
            workTask: task
        )
        context.insert(session)
        try context.save()

        context.delete(task)
        try context.save()

        let sessions = try context.fetch(FetchDescriptor<TimeSession>())
        XCTAssertTrue(sessions.isEmpty, "Sessions should cascade-delete with WorkTask")
    }

    func testDeleteTagDoesNotDeleteTasks() throws {
        let context = try makeContext()

        let tag = Tag(name: "个人")
        context.insert(tag)
        let task = WorkTask(title: "健身", tag: tag)
        context.insert(task)
        try context.save()

        context.delete(tag)
        try context.save()

        let tasks = try context.fetch(FetchDescriptor<WorkTask>())
        XCTAssertEqual(tasks.count, 1, "WorkTask should survive tag deletion")
    }

    // MARK: - Task fields

    func testTaskTimerAndRepeatFields() throws {
        let context = try makeContext()

        let task = WorkTask(
            title: "晨跑",
            type: .recurring,
            timerMode: .countdown,
            countdownDuration: 1800,
            repeatRule: .weekly,
            repeatCustomDays: [1, 2, 3, 4, 5]
        )
        context.insert(task)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<WorkTask>()).first!
        XCTAssertEqual(fetched.type, .recurring)
        XCTAssertEqual(fetched.timerMode, .countdown)
        XCTAssertEqual(fetched.countdownDuration, 1800)
        XCTAssertEqual(fetched.repeatRule, .weekly)
        XCTAssertEqual(fetched.repeatCustomDays, [1, 2, 3, 4, 5])
    }

    // MARK: - Helpers

    private func makeContext() throws -> ModelContext {
        let schema = Schema([Tag.self, WorkTask.self, TimeSession.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }
}

@MainActor
final class TimerServiceTests: XCTestCase {
    private static var retainedServices: [TimerService] = []

    func testStartCreatesLiveTimerSessionAndSentinel() throws {
        let context = try makeContext()
        let tag = Tag(name: "工作", colorToken: "blue")
        let task = WorkTask(title: "写代码", tag: tag)
        context.insert(tag)
        context.insert(task)
        try context.save()

        let service = makeTimerService()
        service.start(task: task, in: context)

        XCTAssertTrue(service.isRunning)
        XCTAssertFalse(service.isPaused)
        XCTAssertNotNil(service.activeSession)
        XCTAssertEqual(service.activeSession?.workTask?.id, task.id)
        XCTAssertEqual(service.killRecoverySentinel?.taskId, task.id)

        service.stop(in: context)
    }

    func testStopFinalizesActiveSession() throws {
        let context = try makeContext()
        let task = WorkTask(title: "整理发布清单")
        context.insert(task)
        try context.save()

        let service = makeTimerService()
        service.start(task: task, in: context)
        service.stop(in: context)

        let sessions = try context.fetch(FetchDescriptor<TimeSession>())
        XCTAssertEqual(sessions.count, 1)
        XCTAssertNotNil(sessions.first?.endAt)
        XCTAssertFalse(service.isRunning)
        XCTAssertNil(service.activeSession)
        XCTAssertNil(service.killRecoverySentinel)
    }

    func testCountdownDisplayAndExtension() throws {
        let context = try makeContext()
        let task = WorkTask(title: "专注", timerMode: .countdown, countdownDuration: 300)
        context.insert(task)
        try context.save()

        let service = makeTimerService()
        service.start(task: task, countdownSeconds: task.countdownDuration, in: context)

        XCTAssertEqual(service.countdownTarget, 300)
        XCTAssertEqual(service.displaySeconds, 300)

        service.extendCountdown(by: 60)
        XCTAssertEqual(service.countdownTarget, 360)
        XCTAssertEqual(service.displaySeconds, 360)

        service.continueCountdownAsStopwatch()
        XCTAssertNil(service.countdownTarget)
        XCTAssertEqual(service.displaySeconds, 0)

        service.stop(in: context)
    }

    func testRecoverSessionWritesEndedSessionAndClearsSentinel() throws {
        let context = try makeContext()
        let task = WorkTask(title: "恢复测试")
        context.insert(task)
        try context.save()

        let sentinel = ActiveSessionSentinel(
            taskId: task.id,
            taskTitle: task.title,
            startAt: Date().addingTimeInterval(-600)
        )

        let recoveryService = makeTimerService()
        recoveryService.recoverSession(for: sentinel, in: context)

        let sessions = try context.fetch(FetchDescriptor<TimeSession>())
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.workTask?.id, task.id)
        XCTAssertNotNil(sessions.first?.endAt)
        XCTAssertNil(recoveryService.killRecoverySentinel)
    }

    private func makeTimerService() -> TimerService {
        let service = TimerService(systemIntegrationsEnabled: false)
        Self.retainedServices.append(service)
        return service
    }

    private func makeContext() throws -> ModelContext {
        let schema = Schema([Tag.self, WorkTask.self, TimeSession.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }
}
