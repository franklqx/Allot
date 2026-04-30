//
//  OnboardingTasksStep.swift
//  Allot

import SwiftUI

struct OnboardingTasksStep: View {

    @Bindable var state: OnboardingState

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Start with some tasks.")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text("We'll create these. Edit or delete anytime.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textSecondary)
            }
            .multilineTextAlignment(.center)
            .padding(.top, 40)
            .padding(.horizontal, 28)

            ScrollView {
                VStack(spacing: 18) {
                    ForEach(state.enabledPresetTags) { presetTag in
                        tagSection(for: presetTag)
                    }
                    if state.enabledPresetTags.isEmpty {
                        emptyState
                            .padding(.top, 40)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func tagSection(for tag: Seed.PresetTag) -> some View {
        let suggestions = Seed.presetTasks[tag.name] ?? []
        let selectedBinding = Binding<Set<String>>(
            get: { state.selectedTasksByTag[tag.name] ?? [] },
            set: { state.selectedTasksByTag[tag.name] = $0 }
        )

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(tag.emoji).font(.system(size: 18))
                Text(tag.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.tagColor(tag.colorToken))
                    .frame(width: 16, height: 16)
            }
            ForEach(suggestions, id: \.self) { name in
                taskRow(name: name, selected: selectedBinding)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }

    private func taskRow(name: String, selected: Binding<Set<String>>) -> some View {
        let isOn = selected.wrappedValue.contains(name)
        return Button {
            if isOn {
                selected.wrappedValue.remove(name)
            } else {
                selected.wrappedValue.insert(name)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isOn ? Color.textPrimary : Color.textTertiary)
                Text(name)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundStyle(Color.textTertiary)
            Text("Skip back to add a tag — or tap Continue to start fresh.")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
