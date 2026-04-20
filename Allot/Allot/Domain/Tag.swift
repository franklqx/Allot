//
//  Tag.swift
//  Allot
//
//  用户自定义标签，可附加到任意 WorkTask（多对多）。

import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var name: String
    var color: String?      // HEX 颜色，如 "#FF6B6B"；nil = 无颜色（简洁模式）
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \WorkTask.tags)
    var tasks: [WorkTask]

    init(id: UUID = UUID(), name: String, color: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.color = color
        self.createdAt = createdAt
        self.tasks = []
    }
}
