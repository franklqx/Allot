//
//  Tag.swift
//  Allot

import Foundation
import SwiftData

@Model final class Tag {
    // CloudKit requires every stored property to have a default value OR be
    // optional. Inline defaults below; init can still override.
    var id: UUID = UUID()
    var name: String = ""
    /// Token name matching the design system v0.2 (e.g. "sky", "lime", "gray").
    var colorToken: String = "gray"
    /// Single-character emoji shown in Dynamic Island compact view + tag chips.
    /// nil falls back to a clock glyph on the island.
    var emoji: String?
    /// True only for the system-created Untagged tag — cannot be renamed or deleted.
    var isSystem: Bool = false
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \WorkTask.tag)
    var tasks: [WorkTask]? = []

    init(
        id: UUID = UUID(),
        name: String,
        colorToken: String = "gray",
        emoji: String? = nil,
        isSystem: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorToken = colorToken
        self.emoji = emoji
        self.isSystem = isSystem
        self.createdAt = createdAt
    }
}
