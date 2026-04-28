//
//  TagEditSheet.swift
//  Allot
//
//  Create or edit a tag: name field + 12-color swatch grid.

import SwiftUI
import SwiftData

private let tagColorTokens: [String] = [
    "coral", "marigold", "mustard", "sage",
    "olive", "teal", "powder", "periwinkle",
    "mauve", "terracotta", "rose", "stone",
]

/// Curated focus emojis. "Other" tap-to-type covers everything else.
private let tagEmojiPresets: [String] = [
    "💻", "📚", "🏋️", "🧘", "🎨",
    "✍️", "🛠️", "🍳", "☕️", "🎮",
    "📝", "🎧",
]

struct TagEditSheet: View {

    let tag: Tag?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var selectedToken: String
    @State private var emoji: String
    @State private var showCustomEmojiField = false
    @State private var showDeleteConfirm = false
    @FocusState private var nameFieldFocused: Bool
    @FocusState private var emojiFieldFocused: Bool

    init(tag: Tag? = nil) {
        self.tag = tag
        _name         = State(wrappedValue: tag?.name       ?? "")
        _selectedToken = State(wrappedValue: tag?.colorToken ?? "coral")
        _emoji        = State(wrappedValue: tag?.emoji      ?? "")
    }

    private var isEditing: Bool { tag != nil }
    private var canSave: Bool   { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Name
                VStack(alignment: .leading, spacing: 6) {
                    Text("Name")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                    TextField("Tag name", text: $name)
                        .font(.system(size: 17))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .background(Color.bgSecondary, in: RoundedRectangle(cornerRadius: Radius.md))
                        .focused($nameFieldFocused)
                        .submitLabel(.done)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 24)

                // Color grid
                VStack(alignment: .leading, spacing: 10) {
                    Text("Color")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                        .padding(.horizontal, 20)

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 6),
                        spacing: 14
                    ) {
                        ForEach(tagColorTokens, id: \.self) { token in
                            colorSwatch(token)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 24)

                // Emoji
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Emoji")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.textSecondary)
                        Spacer()
                        if !emoji.isEmpty {
                            Button("Clear") { emoji = "" }
                                .font(.system(size: 13))
                                .foregroundStyle(Color.textTertiary)
                        }
                    }
                    .padding(.horizontal, 20)

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 6),
                        spacing: 12
                    ) {
                        ForEach(tagEmojiPresets, id: \.self) { e in
                            emojiSwatch(e)
                        }
                        otherEmojiSwatch
                    }
                    .padding(.horizontal, 20)

                    if showCustomEmojiField {
                        TextField("Type any emoji", text: $emoji)
                            .font(.system(size: 22))
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 10)
                            .background(Color.bgSecondary, in: RoundedRectangle(cornerRadius: Radius.md))
                            .focused($emojiFieldFocused)
                            .padding(.horizontal, 20)
                            .onChange(of: emoji) { _, new in
                                // Clamp to first grapheme so we never store more than one glyph.
                                if let first = new.first {
                                    let s = String(first)
                                    if s != new { emoji = s }
                                }
                            }
                    }
                }

                Spacer()

                if isEditing {
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Text("Delete Tag")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.stateDestructive)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
            }
            .background(Color.bgPrimary)
            .navigationTitle(isEditing ? "Edit Tag" : "New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: save)
                        .foregroundStyle(canSave ? Color.accentPrimary : Color.textTertiary)
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear { nameFieldFocused = true }
            .confirmationDialog(
                "Delete \"\(tag?.name ?? "")\"?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete Tag", role: .destructive) {
                    if let t = tag { modelContext.delete(t) }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Tasks using this tag will become untagged.")
            }
        }
    }

    private func emojiSwatch(_ e: String) -> some View {
        let selected = emoji == e
        return Text(e)
            .font(.system(size: 26))
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(selected ? Color.tagColor(selectedToken).opacity(0.18) : Color.bgSecondary)
            )
            .overlay {
                if selected {
                    Circle().stroke(Color.tagColor(selectedToken), lineWidth: 2)
                }
            }
            .onTapGesture {
                emoji = e
                showCustomEmojiField = false
                emojiFieldFocused = false
            }
    }

    private var otherEmojiSwatch: some View {
        let selected = showCustomEmojiField || (!emoji.isEmpty && !tagEmojiPresets.contains(emoji))
        return Image(systemName: "ellipsis")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Color.textSecondary)
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(selected ? Color.tagColor(selectedToken).opacity(0.18) : Color.bgSecondary)
            )
            .overlay {
                if selected {
                    Circle().stroke(Color.tagColor(selectedToken), lineWidth: 2)
                }
            }
            .onTapGesture {
                showCustomEmojiField = true
                emojiFieldFocused = true
            }
    }

    private func colorSwatch(_ token: String) -> some View {
        let selected = selectedToken == token
        return Circle()
            .fill(Color.tagColor(token))
            .frame(width: 38, height: 38)
            .overlay {
                if selected {
                    Circle()
                        .stroke(Color.tagColor(token), lineWidth: 3)
                        .padding(-5)
                        .opacity(0.4)
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .onTapGesture { selectedToken = token }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let cleanedEmoji: String? = {
            let trimmedEmoji = emoji.trimmingCharacters(in: .whitespaces)
            return trimmedEmoji.isEmpty ? nil : trimmedEmoji
        }()
        if let existing = tag {
            existing.name       = trimmed
            existing.colorToken = selectedToken
            existing.emoji      = cleanedEmoji
        } else {
            modelContext.insert(Tag(name: trimmed, colorToken: selectedToken, emoji: cleanedEmoji))
        }
        dismiss()
    }
}
