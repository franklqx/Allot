//
//  Seed.swift
//  Allot
//
//  Tag + task seeding. The Untagged system tag is always inserted on first
//  launch. Preset tags + tasks are opt-in via Onboarding selections.

import Foundation
import SwiftData

enum Seed {

    // MARK: System tags

    static func insertSystemTagsIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.isSystem == true })
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        context.insert(Tag(name: "Untagged", colorToken: "gray", isSystem: true))
        try? context.save()
    }

    // MARK: Preset tags

    struct PresetTag: Identifiable, Hashable {
        let name: String
        let emoji: String
        let colorToken: String
        var id: String { name }
    }

    static let presetTags: [PresetTag] = [
        .init(name: "Work",    emoji: "💼", colorToken: "sky"),
        .init(name: "Health",  emoji: "💪", colorToken: "lime"),
        .init(name: "Learn",   emoji: "📚", colorToken: "lilac"),
        .init(name: "Life",    emoji: "🏠", colorToken: "marigold"),
        .init(name: "Hobby",   emoji: "🎨", colorToken: "rose"),
        .init(name: "Leisure", emoji: "📺", colorToken: "teal"),
    ]

    /// Inserts the preset tags whose names appear in `selectedNames`. Skips any
    /// already present (matched by name, case-insensitive).
    static func installPresetTags(
        selected: [PresetTag],
        in context: ModelContext
    ) {
        let descriptor = FetchDescriptor<Tag>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let existingNames = Set(existing.map { $0.name.lowercased() })

        for preset in selected {
            guard !existingNames.contains(preset.name.lowercased()) else { continue }
            context.insert(Tag(
                name: preset.name,
                colorToken: preset.colorToken,
                emoji: preset.emoji
            ))
        }
        try? context.save()
    }

    // MARK: Preset tasks

    /// Suggested tasks per preset tag, surfaced in Onboarding Step 4.
    static let presetTasks: [String: [String]] = [
        "Work":    ["Main job", "Side project", "Meetings", "Deep work"],
        "Health":  ["Strength", "Cardio", "Yoga", "Meditation"],
        "Learn":   ["Reading", "Language", "Course", "Coding practice"],
        "Life":    ["Chores", "Cooking", "Commute", "Family"],
        "Hobby":   ["Music", "Writing", "Photo", "Games"],
        "Leisure": ["TV", "Phone scroll", "Video"],
    ]

    /// Default selected task names per tag (2-3 per tag) for Onboarding.
    static let defaultSelectedTasks: [String: Set<String>] = [
        "Work":    ["Main job", "Side project"],
        "Health":  ["Strength", "Meditation"],
        "Learn":   ["Reading", "Coding practice"],
        "Life":    ["Chores", "Cooking"],
        "Hobby":   ["Music", "Writing"],
        "Leisure": ["TV"],
    ]

    /// For each tag in `selectedByTag`, inserts the named tasks as recurring
    /// stopwatch tasks with no startTime. Tags must already exist (call
    /// `installPresetTags` first).
    static func installPresetTasks(
        selectedByTag: [String: Set<String>],
        in context: ModelContext
    ) {
        let tagDescriptor = FetchDescriptor<Tag>()
        let allTags = (try? context.fetch(tagDescriptor)) ?? []
        let tagsByName = Dictionary(uniqueKeysWithValues:
            allTags.map { ($0.name.lowercased(), $0) }
        )

        let existingTaskDescriptor = FetchDescriptor<WorkTask>()
        let existingTasks = (try? context.fetch(existingTaskDescriptor)) ?? []
        let existingTitles = Set(existingTasks.map { $0.title.lowercased() })

        var sortOrder = 0
        for (tagName, selected) in selectedByTag {
            guard let tag = tagsByName[tagName.lowercased()] else { continue }
            let orderedNames = (presetTasks[tagName] ?? []).filter { selected.contains($0) }
            for name in orderedNames {
                guard !existingTitles.contains(name.lowercased()) else { continue }
                let task = WorkTask(
                    title: name,
                    type: .recurring,
                    timerMode: .stopwatch,
                    repeatRule: .everyDay,
                    sortOrder: sortOrder,
                    tag: tag
                )
                context.insert(task)
                sortOrder += 1
            }
        }
        try? context.save()
    }
}
