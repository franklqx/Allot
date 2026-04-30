//
//  OnboardingState.swift
//  Allot
//
//  Mutable state collected across onboarding steps. Lives for the duration
//  of the onboarding flow only; commit to SwiftData on the final step.

import Foundation
import Observation

@Observable
@MainActor
final class OnboardingState {
    /// Tags the user kept selected. Maps preset name → toggle/edit fields.
    struct EditableTag: Identifiable, Hashable {
        let id: String
        var name: String
        var emoji: String
        var colorToken: String
        var enabled: Bool
        let isCustom: Bool
    }

    var tags: [EditableTag]
    /// Per tag, the set of preset task names the user kept ticked.
    var selectedTasksByTag: [String: Set<String>]
    /// Whether the user tapped at least one Prism brick (gating Step 2 → Step 3).
    var didExplorePrism: Bool = false

    init() {
        self.tags = Seed.presetTags.map {
            EditableTag(
                id: $0.name,
                name: $0.name,
                emoji: $0.emoji,
                colorToken: $0.colorToken,
                enabled: true,
                isCustom: false
            )
        }
        self.selectedTasksByTag = Seed.defaultSelectedTasks
    }

    var enabledPresetTags: [Seed.PresetTag] {
        tags
            .filter { $0.enabled && !$0.isCustom }
            .map {
                Seed.PresetTag(name: $0.name, emoji: $0.emoji, colorToken: $0.colorToken)
            }
    }

    var enabledCustomTags: [EditableTag] {
        tags.filter { $0.enabled && $0.isCustom }
    }

    func addCustomTag(name: String, emoji: String, colorToken: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        tags.append(EditableTag(
            id: "custom.\(UUID().uuidString)",
            name: trimmed,
            emoji: emoji,
            colorToken: colorToken,
            enabled: true,
            isCustom: true
        ))
    }
}
