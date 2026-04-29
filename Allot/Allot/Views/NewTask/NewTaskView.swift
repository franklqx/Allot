//
//  NewTaskView.swift
//  Allot
//
//  Full-screen page. Tab: [Task | Recurring] (default Task).
//  Title-first capture with a vertical settings flow.
//  Big Add button stays at bottom above keyboard.

import SwiftUI
import SwiftData
import UIKit

struct NewTaskView: View {

    /// Pre-filled date (from the selected Home date when FAB is tapped).
    let prefilledDate: Date

    /// When non-nil, the form edits this task instead of creating a new one.
    let editingTask: WorkTask?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    // MARK: State

    private enum TaskTab: Hashable { case task, recurring }
    private struct WeekdayOption: Identifiable {
        let day: Int
        let label: String
        var id: Int { day }
    }

    @State private var activeTab: TaskTab
    @State private var title: String
    @State private var taskEmoji: String
    @State private var taskEmojiCustomized: Bool

    // Shared fields
    @State private var selectedTag: Tag?
    @State private var timerMode: TimerMode
    @State private var startTimeMinutes: Int?
    @State private var countdownMinutes: Int

    // Once-task fields
    @State private var scheduledDate: Date

    // Recurring fields
    @State private var recurringWeekdays: Set<Int>

    // Sheet presentations
    @State private var showTimePicker    = false
    @State private var showDurationPicker = false
    @State private var showTagPicker     = false
    @State private var showEmojiPicker   = false

    init(prefilledDate: Date = Date(), editingTask: WorkTask? = nil) {
        self.prefilledDate = prefilledDate
        self.editingTask = editingTask

        if let t = editingTask {
            let titleParts = Self.splitEmojiPrefix(from: t.title)
            _activeTab          = State(initialValue: t.type == .recurring ? .recurring : .task)
            _title              = State(initialValue: titleParts.title)
            _taskEmoji          = State(initialValue: titleParts.emoji)
            _taskEmojiCustomized = State(initialValue: titleParts.hasEmoji)
            _selectedTag        = State(initialValue: t.tag?.isSystem == true ? nil : t.tag)
            _timerMode          = State(initialValue: t.timerMode)
            _startTimeMinutes   = State(initialValue: t.startTime)
            _countdownMinutes   = State(initialValue: max(1, t.countdownDuration / 60))
            _scheduledDate      = State(initialValue: t.scheduledDate ?? prefilledDate)
            _recurringWeekdays  = State(initialValue: Self.weekdays(for: t.repeatRule, customDays: t.repeatCustomDays))
        } else {
            _activeTab          = State(initialValue: .task)
            _title              = State(initialValue: "")
            _taskEmoji          = State(initialValue: Self.defaultTaskEmoji)
            _taskEmojiCustomized = State(initialValue: false)
            _selectedTag        = State(initialValue: nil)
            _timerMode          = State(initialValue: .stopwatch)
            _startTimeMinutes   = State(initialValue: nil)
            _countdownMinutes   = State(initialValue: 25)
            _scheduledDate      = State(initialValue: prefilledDate)
            _recurringWeekdays  = State(initialValue: [])
        }
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            tabBar
                .padding(.top, 12)

            ScrollView {
                VStack(spacing: 0) {
                    titleField

                    settingsFlow
                        .padding(.horizontal, 20)
                        .padding(.top, 28)
                }
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)

            VStack(spacing: 0) {
                addButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        }
        .background(Color.bgPrimary)
        .animation(.easeInOut(duration: 0.18), value: activeTab)
        .animation(.easeInOut(duration: 0.18), value: timerMode)
        // Sheets
        .sheet(isPresented: $showTimePicker) {
            WheelTimePickerSheet(
                title: "Start time",
                minutes: $startTimeMinutes,
                onDismiss: { showTimePicker = false }
            )
            .presentationDetents([.height(340)])
            .presentationBackground(Color.bgElevated)
        }
        .sheet(isPresented: $showDurationPicker) {
            HorizontalSliderView(
                mode: .duration,
                title: "Countdown duration",
                valueMinutes: $countdownMinutes,
                onDismiss: { showDurationPicker = false }
            )
            .presentationDetents([.height(260)])
            .presentationBackground(Color.black)
        }
        .sheet(isPresented: $showTagPicker) {
            TagPickerSheet(selectedTag: $selectedTag)
        }
        .sheet(isPresented: $showEmojiPicker) {
            EmojiPickerSheet(
                emoji: $taskEmoji,
                onPick: { taskEmojiCustomized = true }
            )
            .presentationDetents([.height(360)])
            .presentationBackground(Color.bgElevated)
        }
    }

    // MARK: Tab bar — pill segmented buttons (white-with-shadow when active)

    private var tabBar: some View {
        HStack(spacing: 6) {
            ForEach([TaskTab.task, TaskTab.recurring], id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { activeTab = tab }
                } label: {
                    Text(tab == .task ? "Task" : "Recurring")
                        .font(.system(size: 14, weight: activeTab == tab ? .semibold : .regular))
                        .foregroundStyle(activeTab == tab ? Color.textPrimary : Color.textTertiary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 18)
                        .background(
                            ZStack {
                                if activeTab == tab {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.bgElevated)
                                        .shadow(color: Color.black.opacity(0.08),
                                                radius: 4, x: 0, y: 1)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
                .disabled(editingTask != nil)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.bgSecondary)
        )
        .padding(.horizontal, 20)
    }

    // MARK: Title field

    private var titleField: some View {
        HStack(spacing: 10) {
            Button {
                showEmojiPicker = true
                taskEmojiCustomized = true
            } label: {
                Text(taskEmoji.isEmpty ? Self.defaultTaskEmoji : taskEmoji)
                    .font(.system(size: 27))
                    .frame(width: 42, height: 42)
                    .background(Color.bgSecondary, in: Circle())
            }
            .buttonStyle(.plain)

            AutoFocusTextField(
                text: $title,
                placeholder: titleFieldPlaceholder,
                font: UIFont.systemFont(ofSize: 28, weight: .medium)
            )
        }
        .frame(height: 44)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var titleFieldPlaceholder: String {
        activeTab == .task ? "Task title" : "Habit title"
    }

    private var whenFootnote: String {
        if startTimeMinutes == nil { return "No scheduled start" }
        return activeTab == .recurring
            ? "Applies on selected days"
            : "Starts on \(scheduledDate.formatted(.dateTime.month(.abbreviated).day()))"
    }

    // MARK: Settings flow

    private var settingsFlow: some View {
        VStack(spacing: 14) {
            SettingRow(
                label: "Tag",
                value: selectedTag.map(\.name) ?? "Untagged",
                systemImage: selectedTag == nil ? "tag" : nil,
                dotColor: selectedTag.map { Color.tagColor($0.colorToken) },
                action: { showTagPicker = true }
            )

            SettingRow(
                label: "When",
                value: startTimeMinutes.map { formatStartTime($0) } ?? "Anytime",
                systemImage: "clock",
                footnote: whenFootnote,
                action: { showTimePicker = true }
            )

            if activeTab == .recurring {
                recurringDaysSection
            }

            timerModeSection

            if timerMode == .countdown {
                durationSection
            }
        }
    }

    private var recurringDaysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Repeat on")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.textTertiary)

            HStack(spacing: 8) {
                ForEach(Self.weekdayOptions) { option in
                    WeekdayButton(
                        title: option.label,
                        isSelected: recurringWeekdays.contains(option.day)
                    ) {
                        toggleRecurringWeekday(option.day)
                    }
                }
            }
        }
    }

    private var timerModeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Timer")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.textTertiary)

            HStack(spacing: 8) {
                TimerModeButton(
                    title: "Stopwatch",
                    systemImage: "timer",
                    isSelected: timerMode == .stopwatch
                ) {
                    timerMode = .stopwatch
                }

                TimerModeButton(
                    title: "Countdown",
                    systemImage: "hourglass",
                    isSelected: timerMode == .countdown
                ) {
                    timerMode = .countdown
                }
            }
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Duration")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)

                Spacer()

                Text(formatDuration(countdownMinutes * 60))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
            }

            HStack(spacing: 8) {
                ForEach([5, 15, 25], id: \.self) { minutes in
                    DurationButton(
                        title: "\(minutes)m",
                        isSelected: countdownMinutes == minutes
                    ) {
                        countdownMinutes = minutes
                    }
                }

                DurationButton(
                    title: "Custom",
                    isSelected: ![5, 15, 25].contains(countdownMinutes)
                ) {
                    showDurationPicker = true
                }
            }
        }
    }

    // MARK: Add button

    private var addButton: some View {
        Button(action: saveTask) {
            Text(addButtonTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.bgPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    !canSave
                        ? Color.accentPrimary.opacity(0.4)
                        : Color.accentPrimary,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
            && (activeTab == .task || !recurringWeekdays.isEmpty)
    }

    private var addButtonTitle: String {
        if editingTask != nil { return "Save" }
        return activeTab == .recurring ? "Add recurring" : "Add"
    }

    // MARK: Save

    private func saveTask() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard canSave else { return }

        let resolvedType: TaskType = activeTab == .task ? .once : .recurring
        let resolvedRepeatRule = activeTab == .recurring ? repeatRuleForSelectedWeekdays : nil
        let resolvedCustomDays = activeTab == .recurring ? repeatCustomDaysForSelectedWeekdays : []
        let decoratedTitle = Self.decoratedTitle(emoji: taskEmoji, title: trimmed)

        if let task = editingTask {
            task.title = decoratedTitle
            task.timerMode = timerMode
            task.countdownDuration = countdownMinutes * 60
            task.scheduledDate = activeTab == .task ? scheduledDate : nil
            task.startTime = startTimeMinutes
            task.repeatRule = resolvedRepeatRule
            task.repeatCustomDays = resolvedCustomDays
            task.tag = selectedTag
        } else {
            let task = WorkTask(
                title: decoratedTitle,
                type: resolvedType,
                timerMode: timerMode,
                countdownDuration: countdownMinutes * 60,
                scheduledDate: activeTab == .task ? scheduledDate : nil,
                startTime: startTimeMinutes,
                repeatRule: resolvedRepeatRule,
                repeatCustomDays: resolvedCustomDays,
                tag: selectedTag
            )
            modelContext.insert(task)
        }
        try? modelContext.save()
        dismiss()
    }

    // MARK: Title emoji

    fileprivate static let defaultTaskEmoji = "💻"

    private static func splitEmojiPrefix(from rawTitle: String) -> (emoji: String, title: String, hasEmoji: Bool) {
        let trimmed = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first, first.isEmojiGlyph else {
            return (defaultTaskEmoji, rawTitle, false)
        }
        let remaining = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
        return (String(first), remaining, true)
    }

    private static func decoratedTitle(emoji: String, title: String) -> String {
        let cleanEmoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanEmoji.isEmpty else { return title }
        return "\(cleanEmoji)\(title)"
    }

    // MARK: Recurring day mapping

    private static let allWeekdays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
    private static let weekdaySet: Set<Int> = [2, 3, 4, 5, 6]
    private static let weekend: Set<Int> = [1, 7]
    private static let weekdayOptions: [WeekdayOption] = [
        WeekdayOption(day: 2, label: "M"),
        WeekdayOption(day: 3, label: "T"),
        WeekdayOption(day: 4, label: "W"),
        WeekdayOption(day: 5, label: "T"),
        WeekdayOption(day: 6, label: "F"),
        WeekdayOption(day: 7, label: "S"),
        WeekdayOption(day: 1, label: "S")
    ]

    private static func weekdays(for rule: RepeatRule?, customDays: [Int]) -> Set<Int> {
        switch rule {
        case .everyDay:
            return allWeekdays
        case .everyWeekday:
            return weekdaySet
        case .everyWeekend:
            return weekend
        case .weekly, .custom:
            let selectedDays = Set(customDays).intersection(allWeekdays)
            return selectedDays.isEmpty ? allWeekdays : selectedDays
        default:
            return allWeekdays
        }
    }

    private var repeatRuleForSelectedWeekdays: RepeatRule {
        if recurringWeekdays == Self.allWeekdays { return .everyDay }
        if recurringWeekdays == Self.weekdaySet { return .everyWeekday }
        if recurringWeekdays == Self.weekend { return .everyWeekend }
        return .custom
    }

    private var repeatCustomDaysForSelectedWeekdays: [Int] {
        switch repeatRuleForSelectedWeekdays {
        case .custom:
            return Self.weekdayOptions
                .map(\.day)
                .filter { recurringWeekdays.contains($0) }
        default:
            return []
        }
    }

    private func toggleRecurringWeekday(_ day: Int) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if recurringWeekdays.contains(day) {
            recurringWeekdays.remove(day)
        } else {
            recurringWeekdays.insert(day)
        }
    }
}

// MARK: Wheel time picker sheet

private struct WheelTimePickerSheet: View {
    let title: String
    @Binding var minutes: Int?
    let onDismiss: () -> Void

    @State private var pickerDate: Date = Date()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { onDismiss() }
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Button("Done") {
                    let cal = Calendar.current
                    let comps = cal.dateComponents([.hour, .minute], from: pickerDate)
                    minutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
                    onDismiss()
                }
                .foregroundStyle(Color.accentPrimary)
                .fontWeight(.semibold)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Button {
                minutes = nil
                onDismiss()
            } label: {
                HStack {
                    Image(systemName: "clock.badge.xmark")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Anytime")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    if minutes == nil {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(Color.bgSecondary, in: RoundedRectangle(cornerRadius: Radius.md))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 18)

            DatePicker(
                "",
                selection: $pickerDate,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .background(Color.bgElevated)
        .onAppear {
            let cal = Calendar.current
            let resolvedMinutes = minutes ?? 9 * 60
            let h = resolvedMinutes / 60
            let m = resolvedMinutes % 60
            pickerDate = cal.date(bySettingHour: h, minute: m, second: 0, of: Date()) ?? Date()
        }
    }
}

// MARK: Emoji picker sheet

private struct EmojiPickerSheet: View {
    @Binding var emoji: String
    let onPick: () -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var customFocused: Bool
    @State private var showCustomEmojiField = false
    @State private var customEmojiDraft = ""

    private let presets = [
        "💻", "📚", "🏋️", "🧘", "🎨", "✍️",
        "🛠️", "🍳", "☕️", "🎮", "🎧", "💎"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Text("Task emoji")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Button("Done") {
                    commitCustomEmojiDraft()
                    onPick()
                    dismiss()
                }
                .foregroundStyle(Color.accentPrimary)
                .fontWeight(.semibold)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 6),
                spacing: 12
            ) {
                ForEach(presets, id: \.self) { preset in
                    Button {
                        emoji = preset
                        onPick()
                        dismiss()
                    } label: {
                        Text(preset)
                            .font(.system(size: 28))
                            .frame(width: 44, height: 44)
                            .background(Color.bgSecondary, in: Circle())
                            .overlay {
                                if emoji == preset {
                                    Circle().stroke(Color.textPrimary, lineWidth: 2)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)

            Button {
                showCustomEmojiField = true
                customEmojiDraft = emoji
                DispatchQueue.main.async {
                    customFocused = true
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(Color.bgSecondary, in: Circle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .center)

            if showCustomEmojiField {
                TextField("Type any emoji", text: $customEmojiDraft)
                    .font(.system(size: 28))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 11)
                    .background(Color.bgSecondary, in: RoundedRectangle(cornerRadius: Radius.md))
                    .focused($customFocused)
                    .padding(.horizontal, 20)
                    .onChange(of: customEmojiDraft) { _, newValue in
                        updateCustomEmoji(from: newValue)
                    }
            }

            Spacer(minLength: 0)
        }
        .background(Color.bgElevated)
    }

    private func updateCustomEmoji(from value: String) {
        guard let selected = lastEmojiGlyph(in: value) else { return }
        let normalized = String(selected)
        emoji = normalized
        onPick()
        if customEmojiDraft != normalized {
            customEmojiDraft = normalized
        }
    }

    private func commitCustomEmojiDraft() {
        if let selected = lastEmojiGlyph(in: customEmojiDraft) {
            emoji = String(selected)
        }
    }

    private func lastEmojiGlyph(in value: String) -> Character? {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .reversed()
            .first { $0.isEmojiGlyph }
    }
}

// MARK: Auto-focus text field
//
// Goal: keyboard should rise *together with* the sheet, not lag 0.4s behind.
//
// The reliable hook is UIViewController's `viewIsAppearing(_:)` (iOS 13+):
// it fires after `viewWillAppear` and `viewWillLayoutSubviews` but BEFORE
// `viewDidAppear` — i.e. while the sheet's transition animation is still
// running, with the view already in the window hierarchy. This is exactly
// the right moment to claim first responder so iOS coalesces the keyboard
// animation with the sheet animation.
//
// We also have a `viewDidAppear` fallback in case the first attempt fails
// for any reason (rare but recoverable instead of silently broken).

private final class AutoFocusVC: UIViewController, UITextFieldDelegate {
    let textField = UITextField()
    private var hasAutoFocused = false
    var onTextChange: ((String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        textField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textField)
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textField.topAnchor.constraint(equalTo: view.topAnchor),
            textField.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        textField.delegate = self
        textField.returnKeyType = .done
        textField.contentVerticalAlignment = .top
        textField.addTarget(self, action: #selector(editingChanged(_:)), for: .editingChanged)
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        guard !hasAutoFocused else { return }
        if textField.becomeFirstResponder() {
            hasAutoFocused = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasAutoFocused {
            hasAutoFocused = textField.becomeFirstResponder()
        }
    }

    @objc private func editingChanged(_ tf: UITextField) {
        onTextChange?(tf.text ?? "")
    }

    func textFieldShouldReturn(_ tf: UITextField) -> Bool {
        tf.resignFirstResponder()
        return true
    }
}

private struct AutoFocusTextField: UIViewControllerRepresentable {
    @Binding var text: String
    let placeholder: String
    let font: UIFont

    func makeUIViewController(context: Context) -> AutoFocusVC {
        let vc = AutoFocusVC()
        vc.textField.placeholder = placeholder
        vc.textField.font = font
        vc.textField.text = text
        vc.onTextChange = { newValue in
            if newValue != text { text = newValue }
        }
        return vc
    }

    func updateUIViewController(_ vc: AutoFocusVC, context: Context) {
        if vc.textField.text != text { vc.textField.text = text }
        vc.onTextChange = { newValue in
            if newValue != text { text = newValue }
        }
    }
}

// MARK: Setting controls

private struct SettingRow: View {
    let label: String
    let value: String
    var systemImage: String?
    var dotColor: Color?
    var footnote: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                leadingIcon

                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)

                    Text(value)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)

                    if let footnote {
                        Text(footnote)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.textTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 12)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, footnote == nil ? 12 : 10)
            .background(Color.bgSecondary, in: RoundedRectangle(cornerRadius: Radius.md))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var leadingIcon: some View {
        if let dotColor {
            Circle()
                .fill(dotColor)
                .frame(width: 10, height: 10)
                .frame(width: 24, height: 24)
        } else if let systemImage {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .frame(width: 24, height: 24)
        }
    }
}

private struct WeekdayButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isSelected ? Color.bgPrimary : Color.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    isSelected ? Color.textPrimary : Color.bgElevated,
                    in: Circle()
                )
                .overlay {
                    Circle()
                        .strokeBorder(Color.textQuaternary, lineWidth: isSelected ? 0 : 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private struct TimerModeButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? Color.bgPrimary : Color.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                isSelected ? Color.textPrimary : Color.bgSecondary,
                in: RoundedRectangle(cornerRadius: Radius.md)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct DurationButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? Color.bgPrimary : Color.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    isSelected ? Color.textPrimary : Color.bgSecondary,
                    in: RoundedRectangle(cornerRadius: Radius.md)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: RepeatRule display name

extension RepeatRule {
    var displayName: String {
        switch self {
        case .everyDay:     return "Every day"
        case .everyWeekday: return "Weekdays"
        case .everyWeekend: return "Weekends"
        case .weekly:       return "Weekly"
        case .monthly:      return "Monthly"
        case .yearly:       return "Yearly"
        case .custom:       return "Custom"
        }
    }
}

private extension Character {
    var isEmojiGlyph: Bool {
        unicodeScalars.contains { scalar in
            scalar.properties.isEmojiPresentation
                || (scalar.properties.isEmoji && scalar.value > 0x238C)
        }
    }
}
