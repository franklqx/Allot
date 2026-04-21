//
//  Seed.swift
//  Allot
//
//  One-time setup: insert system tags that must always exist.

import Foundation
import SwiftData

enum Seed {
    static func insertSystemTagsIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.isSystem == true })
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        context.insert(Tag(name: "Untagged", colorToken: "stone", isSystem: true))
        try? context.save()
    }
}
