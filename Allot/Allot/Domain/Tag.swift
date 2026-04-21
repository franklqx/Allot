//
//  Tag.swift
//  Allot

import Foundation
import SwiftData

@Model final class Tag {
    var id: UUID
    var name: String
    /// Token name matching the design system (e.g. "coral", "teal", "stone").
    var colorToken: String
    /// True only for the system-created Untagged tag — cannot be renamed or deleted.
    var isSystem: Bool
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \WorkTask.tag)
    var tasks: [WorkTask] = []

    init(
        id: UUID = UUID(),
        name: String,
        colorToken: String = "stone",
        isSystem: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorToken = colorToken
        self.isSystem = isSystem
        self.createdAt = createdAt
    }
}
