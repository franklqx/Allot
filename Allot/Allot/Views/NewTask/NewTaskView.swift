//
//  NewTaskView.swift
//  Allot
//
//  Full-screen page. Tab: [Recurring | Task] (default Task).
//  Pill row → date / time / timer-mode / tag pickers.
//  Big Add button at bottom above keyboard.

import SwiftUI
import SwiftData

struct NewTaskView: View {

    /// Pre-filled date (from the selected Home date when FAB is tapped).
    let prefilledDate: Date

    /// When non-nil, the form edits this task instead of creating a new one.
    let editingTask: WorkTask?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    // MARK: State

    private enum TaskTab { case task, recurring }
    @State private var activeTab: TaskTab
    @State private var title: String

    // Shared fields
    @State private var selectedTag: Tag?
    @State private var timerMode: TimerMode
    @State private var startTimeMinutes: Int?
    @State private var countdownMinutes: Int

    // Once-task fields
    @State private var scheduledDate: Date

    // Recurring fields
    @State private var repeatRule: RepeatRule

    // Sheet presentations
    @State private var showDatePicker    = false
    @State private var showTimePicker    = false
    @State private var showDurationPicker = false
    @State private var showTagPicker     = false
    @State private var showRepeatPicker  = false

    init(prefilledDate: Date = Date(), editingTask: WorkTask? = nil) {
        self.prefilledDate = prefilledDate
        self.editingTask = editingTask

        if let t = editingTask {
            _activeTab          = State(initialValue: t.type == .recurring ? .recurring : .task)
            _title              = State(initialValue: t.title)
            _selectedTag        = State(initialValue: t.tag?.isSystem == true ? nil : t.tag)
            _timerMode          = State(initialValue: t.timerMode)
            _startTimeMinutes   = State(initialValue: t.startTime)
            _countdownMinutes   = State(initialValue: max(1, t.countdownDuration / 60))
            _scheduledDate      = State(initialValue: t.scheduledDate ?? prefilledDate)
            _repeatRule         = State(initialValue: t.repeatRule ?? .everyDay)
        } else {
            _activeTab          = State(initialValue: .task)
            _title              = State(initialValue: "")
            _selectedTag        = State(initialValue: nil)
            _timerMode          = State(initialValue: .stopwatch)
            _startTimeMinutes   = State(initialValue: nil)
            _countdownMinutes   = State(initialValue: 25)
            _scheduledDate      = State(initialValue: prefilledDate)
            _repeatRule         = State(initialValue: .everyDay)
        }
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            tabBar
                .padding(.top, 12)

            // Title input — fills remaining space
            titleField

            Spacer(minLength: 16)

            VStack(spacing: 0) {
                pillRow
                    .padding(.bottom, 16)

                addButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        }
        .background(Color.bgPrimary)
        // Sheets
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                DatePicker("", selection: $scheduledDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(Color.accentPrimary)
                    .padding()
                    .navigationTitle("Pick a date")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showDatePicker = false }
                                .foregroundStyle(Color.accentPrimary)
                        }
                    }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showTimePicker) {
            WheelTimePickerSheet(
                title: "Start time",
                minutes: Binding(
                    get: { startTimeMinutes ?? 9 * 60 },
                    set: { startTimeMinutes = $0 }
                ),
                onDismiss: { showTimePicker = false }
            )
            .presentationDetents([.height(280)])
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
        .sheet(isPresented: $showRepeatPicker) {
            RepeatRuleSheet(selectedRule: $repeatRule)
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
        AutoFocusTextField(
            text: $title,
            placeholder: titleFieldPlaceholder,
            font: UIFont.systemFont(ofSize: 28, weight: .medium)
        )
        .frame(height: 44)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var titleFieldPlaceholder: String {
        activeTab == .task ? "Task title" : "Habit title"
    }

    // MARK: Pill row

    private var pillRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if activeTab == .task {
                    PillButton(
                        label: scheduledDate.formatted(.dateTime.month(.abbreviated).day()),
                        systemImage: "calendar",
                        action: { showDatePicker = true }
                    )
                } else {
                    PillButton(
                        label: repeatRule.displayName,
                        systemImage: "arrow.clockwise",
                        action: { showRepeatPicker = true }
                    )
                }

                // Start time pill
                PillButton(
                    label: startTimeMinutes.map { formatStartTime($0) } ?? "Add time",
                    systemImage: startTimeMinutes == nil ? "clock" : nil,
                    isActive: startTimeMinutes != nil,
                    action: { showTimePicker = true }
                )

                // Timer mode pill
                PillButton(
                    label: timerMode == .stopwatch ? "Stopwatch" : "Countdown",
                    systemImage: timerMode == .stopwatch ? "timer" : "hourglass",
                    action: {
                        timerMode = timerMode == .stopwatch ? .countdown : .stopwatch
                    }
                )

                // Duration pill (only when countdown)
                if timerMode == .countdown {
                    PillButton(
                        label: formatDuration(countdownMinutes * 60),
                        systemImage: nil,
                        isActive: true,
                        action: { showDurationPicker = true }
                    )
                    .transition(.scale.combined(with: .opacity))
                }

                // Tag pill
                PillButton(
                    label: selectedTag.map(\.name) ?? "Tag",
                    systemImage: selectedTag == nil ? "tag" : nil,
                    dotColor: selectedTag.map { Color.tagColor($0.colorToken) },
                    isActive: selectedTag != nil,
                    action: { showTagPicker = true }
                )
            }
            .padding(.horizontal, 20)
            .animation(.easeInOut(duration: 0.2), value: timerMode)
        }
    }

    // MARK: Add button

    private var addButton: some View {
        Button(action: saveTask) {
            Text(editingTask == nil ? "Add" : "Save")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    title.trimmingCharacters(in: .whitespaces).isEmpty
                        ? Color.accentPrimary.opacity(0.4)
                        : Color.accentPrimary,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    // MARK: Save

    private func saveTask() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let resolvedType: TaskType = activeTab == .task ? .once : .recurring

        if let task = editingTask {
            task.title = trimmed
            task.timerMode = timerMode
            task.countdownDuration = countdownMinutes * 60
            task.scheduledDate = activeTab == .task ? scheduledDate : nil
            task.startTime = startTimeMinutes
            task.repeatRule = activeTab == .recurring ? repeatRule : nil
            task.tag = selectedTag
        } else {
            let task = WorkTask(
                title: trimmed,
                type: resolvedType,
                timerMode: timerMode,
                countdownDuration: countdownMinutes * 60,
                scheduledDate: activeTab == .task ? scheduledDate : nil,
                startTime: startTimeMinutes,
                repeatRule: activeTab == .recurring ? repeatRule : nil,
                tag: selectedTag
            )
            modelContext.insert(task)
        }
        try? modelContext.save()
        dismiss()
    }
}

// MARK: Wheel time picker sheet

private struct WheelTimePickerSheet: View {
    let title: String
    @Binding var minutes: Int
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
            let h = minutes / 60
            let m = minutes % 60
            pickerDate = cal.date(bySettingHour: h, minute: m, second: 0, of: Date()) ?? Date()
        }
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

// MARK: Pill button

private struct PillButton: View {
    let label: String
    var systemImage: String?
    var dotColor: Color? = nil
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let dot = dotColor {
                    Circle().fill(dot).frame(width: 8, height: 8)
                } else if let icon = systemImage {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                }
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(isActive ? Color.accentPrimary : Color.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isActive
                    ? Color.accentPrimary.opacity(0.1)
                    : Color.bgSecondary,
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isActive ? Color.accentPrimary.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
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
