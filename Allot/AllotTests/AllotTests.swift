//
//  AllotTests.swift
//  AllotTests
//

import XCTest
import SwiftData
@testable import Allot

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

        let task = WorkTask(title: "写代码", tags: [tag])
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
        XCTAssertEqual(fetched.first?.tags.first?.name, "工作")
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
        let task = WorkTask(title: "健身", tags: [tag])
        context.insert(task)
        try context.save()

        context.delete(tag)
        try context.save()

        let tasks = try context.fetch(FetchDescriptor<WorkTask>())
        XCTAssertEqual(tasks.count, 1, "WorkTask should survive tag deletion")
    }

    // MARK: - Scheduling fields

    func testRecurringTaskFields() throws {
        let context = try makeContext()

        let task = WorkTask(
            title: "晨跑",
            targetDuration: 1800,   // 30 分钟
            isRecurring: true,
            recurringDays: [1, 2, 3, 4, 5]  // 工作日
        )
        context.insert(task)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<WorkTask>()).first!
        XCTAssertEqual(fetched.targetDuration, 1800)
        XCTAssertTrue(fetched.isRecurring)
        XCTAssertEqual(fetched.recurringDays, [1, 2, 3, 4, 5])
    }

    // MARK: - Helpers

    private func makeContext() throws -> ModelContext {
        let schema = Schema([Tag.self, WorkTask.self, TimeSession.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }
}
