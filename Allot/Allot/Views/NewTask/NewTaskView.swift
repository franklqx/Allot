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

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    // MARK: State

    private enum TaskTab { case task, recurring }
    @State private var activeTab: TaskTab = .task
    @State private var title = ""
    @FocusState private var titleFocused: Bool

    // Shared fields
    @State private var selectedTag: Tag? = nil
    @State private var timerMode: TimerMode = .stopwatch
    @State private var startTimeMinutes: Int? = nil    // nil = no time set
    @State private var countdownMinutes: Int = 25

    // Once-task fields
    @State private var scheduledDate: Date

    // Recurring fields
    @State private var repeatRule: RepeatRule = .everyDay

    // Sheet presentations
    @State private var showDatePicker    = false
    @State private var showTimePicker    = false
    @State private var showDurationPicker = false
    @State private var showTagPicker     = false
    @State private var showRepeatPicker  = false

    init(prefilledDate: Date = Date()) {
        self.prefilledDate = prefilledDate
        _scheduledDate = State(initialValue: prefilledDate)
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tabBar

                Divider()
                    .foregroundStyle(Color.textPrimary.opacity(0.06))

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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { closeButton }
        }
        .onAppear { titleFocused = true }
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
            HorizontalSliderView(
                mode: .timeOfDay,
                title: "Start time",
                valueMinutes: Binding(
                    get: { startTimeMinutes ?? 9 * 60 },
                    set: { startTimeMinutes = $0 }
                ),
                onDismiss: { showTimePicker = false }
            )
            .presentationDetents([.height(260)])
            .presentationBackground(Color.black)
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

    // MARK: Tab bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach([TaskTab.recurring, TaskTab.task], id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { activeTab = tab }
                } label: {
                    Text(tab == .task ? "Task" : "Recurring")
                        .font(.system(size: 15, weight: activeTab == tab ? .semibold : .regular))
                        .foregroundStyle(activeTab == tab ? Color.textPrimary : Color.textTertiary)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(alignment: .bottom) {
            // Sliding underline
            GeometryReader { geo in
                let tabWidth = geo.size.width / 2
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.accentPrimary)
                    .frame(width: 28, height: 3)
                    .offset(x: activeTab == .recurring
                            ? tabWidth / 2 - 14
                            : tabWidth * 1.5 - 14)
                    .animation(.easeInOut(duration: 0.15), value: activeTab)
            }
            .frame(height: 3)
        }
    }

    // MARK: Title field

    private var titleField: some View {
        TextField(
            activeTab == .task ? "Task title" : "Habit title",
            text: $title,
            axis: .vertical
        )
        .font(.system(size: 28, weight: .medium))
        .foregroundStyle(Color.textPrimary)
        .focused($titleFocused)
        .submitLabel(.done)
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: Pill row

    private var pillRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if activeTab == .task {
                    // Date pill
                    PillButton(
                        label: scheduledDate.formatted(.dateTime.month(.abbreviated).day()),
                        systemImage: "calendar",
                        action: { showDatePicker = true }
                    )
                } else {
                    // Repeat rule pill
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
            Text("Add")
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

    // MARK: Close button

    private var closeButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .padding(8)
                    .background(Color.bgSecondary, in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Save

    private func saveTask() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let task = WorkTask(
            title: trimmed,
            type: activeTab == .task ? .once : .recurring,
            timerMode: timerMode,
            countdownDuration: countdownMinutes * 60,
            scheduledDate: activeTab == .task ? scheduledDate : nil,
            startTime: startTimeMinutes,
            repeatRule: activeTab == .recurring ? repeatRule : nil,
            tag: selectedTag
        )
        modelContext.insert(task)
        try? modelContext.save()
        dismiss()
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
