//
//  OnboardingTagsStep.swift
//  Allot

import SwiftUI

struct OnboardingTagsStep: View {

    @Bindable var state: OnboardingState

    @State private var editingEmoji: String?  // tag id whose emoji is being edited
    @State private var emojiDraft: String = ""
    @State private var editingColor: String?  // tag id whose color picker is open
    @State private var showAddCustom = false
    @State private var customName = ""
    @State private var customEmoji = "✨"
    @State private var customColor = "sky"

    private let palette: [String] = [
        "sky", "amber", "rose", "lilac", "lime", "marigold",
        "teal", "coral", "plum", "mustard", "sage", "gray",
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Pick your tags.")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text("These categorize your time. Edit anytime.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textSecondary)
            }
            .multilineTextAlignment(.center)
            .padding(.top, 40)
            .padding(.horizontal, 28)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach($state.tags) { $tag in
                        tagRow(tag: $tag)
                    }

                    Button {
                        showAddCustom = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle")
                                .foregroundStyle(Color.textSecondary)
                            Text("Add custom tag")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                .stroke(Color.textTertiary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 16)
            }
        }
        .sheet(isPresented: $showAddCustom) {
            addCustomSheet
                .presentationDetents([.height(360)])
        }
    }

    private func tagRow(tag: Binding<OnboardingState.EditableTag>) -> some View {
        HStack(spacing: 10) {
            Toggle(isOn: tag.enabled) { EmptyView() }
                .labelsHidden()
                .tint(Color.accentPrimary)

            Button {
                editingEmoji = tag.wrappedValue.id
                emojiDraft = tag.wrappedValue.emoji
            } label: {
                Text(tag.wrappedValue.emoji)
                    .font(.system(size: 22))
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.bgSecondary)
                    )
            }
            .buttonStyle(.plain)

            Text(tag.wrappedValue.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(tag.wrappedValue.enabled ? Color.textPrimary : Color.textTertiary)
            Spacer()

            Button {
                editingColor = (editingColor == tag.wrappedValue.id) ? nil : tag.wrappedValue.id
            } label: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.tagColor(tag.wrappedValue.colorToken))
                    .frame(width: 22, height: 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color.textTertiary.opacity(0.2), lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.bgSecondary)
        )
        .opacity(tag.wrappedValue.enabled ? 1 : 0.55)
        .overlay(alignment: .bottom) {
            if editingColor == tag.wrappedValue.id {
                colorPalette(selected: tag.colorToken)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                    .background(Color.bgSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                    .offset(y: 110)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: editingColor)
        .alert("Edit emoji",
               isPresented: Binding(
                get: { editingEmoji == tag.wrappedValue.id },
                set: { if !$0 { editingEmoji = nil } }
               )
        ) {
            TextField("Emoji", text: $emojiDraft)
                .textInputAutocapitalization(.never)
            Button("Save") {
                let cleaned = emojiDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleaned.isEmpty {
                    tag.emoji.wrappedValue = String(cleaned.prefix(2))
                }
                editingEmoji = nil
            }
            Button("Cancel", role: .cancel) { editingEmoji = nil }
        } message: {
            Text("Pick a single emoji to identify this tag.")
        }
    }

    private func colorPalette(selected: Binding<String>) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
            ForEach(palette, id: \.self) { token in
                Button {
                    selected.wrappedValue = token
                    editingColor = nil
                } label: {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.tagColor(token))
                        .frame(height: 28)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(
                                    token == selected.wrappedValue
                                        ? Color.textPrimary
                                        : Color.clear,
                                    lineWidth: 2
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 8)
    }

    private var addCustomSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("New tag")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .padding(.top, 16)

            HStack(spacing: 12) {
                TextField("Emoji", text: $customEmoji)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 22))
                    .frame(width: 56, height: 56)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.bgSecondary))

                TextField("Tag name", text: $customName)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.bgSecondary))
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(palette, id: \.self) { token in
                    Button {
                        customColor = token
                    } label: {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.tagColor(token))
                            .frame(height: 32)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(
                                        token == customColor ? Color.textPrimary : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            Button {
                state.addCustomTag(name: customName, emoji: customEmoji, colorToken: customColor)
                customName = ""
                customEmoji = "✨"
                customColor = "sky"
                showAddCustom = false
            } label: {
                Text("Add tag")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.bgPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentPrimary, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(customName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .background(Color.bgPrimary)
    }
}
