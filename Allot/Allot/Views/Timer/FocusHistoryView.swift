//
//  FocusHistoryView.swift
//  Allot
//
//  Reverse-chronological list of every completed TimeSession, grouped by day.
//  Each row: start time · task title (or "Untagged session") · duration.
//

import SwiftUI
import SwiftData

struct FocusHistoryView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \TimeSession.startAt, order: .reverse)
    private var sessions: [TimeSession]

    @State private var showJumpToTop = false
    @State private var sessionPendingDelete: TimeSession?

    private static let topAnchorID = "history-top"

    private var completedSessions: [TimeSession] {
        sessions.filter { $0.endAt != nil }
    }

    private struct DayGroup: Identifiable {
        let date: Date
        let items: [TimeSession]
        var id: TimeInterval { date.timeIntervalSince1970 }
    }

    private var grouped: [DayGroup] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: completedSessions) { cal.startOfDay(for: $0.startAt) }
        return dict.keys.sorted(by: >).map { day in
            // Within each day: sessions without a real start time (quickLog /
            // manualEntry) float to the top, then live-timer sessions follow
            // in chronological order.
            let items = dict[day]!.sorted { a, b in
                let aLive = a.source == .liveTimer
                let bLive = b.source == .liveTimer
                if aLive != bLive { return !aLive }
                return a.startAt < b.startAt
            }
            return DayGroup(date: day, items: items)
        }
    }

    var body: some View {
        Group {
            if completedSessions.isEmpty {
                emptyState
            } else {
                listContent
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.bgPrimary)
        .alert(
            deletePromptTitle,
            isPresented: Binding(
                get: { sessionPendingDelete != nil },
                set: { if !$0 { sessionPendingDelete = nil } }
            ),
            presenting: sessionPendingDelete
        ) { session in
            Button("Cancel", role: .cancel) {
                sessionPendingDelete = nil
            }
            Button("Delete", role: .destructive) {
                performDelete(session)
            }
        } message: { _ in
            Text("This can't be undone.")
        }
    }

    private var deletePromptTitle: String {
        guard let s = sessionPendingDelete else { return "Delete session?" }
        let title = s.workTask?.title ?? "Untagged session"
        return "Delete \"\(title)\"?"
    }

    private func performDelete(_ session: TimeSession) {
        modelContext.delete(session)
        try? modelContext.save()
        sessionPendingDelete = nil
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private var listContent: some View {
        ScrollViewReader { proxy in
            List {
                Color.clear.frame(height: 0)
                    .id(Self.topAnchorID)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())

                ForEach(grouped) { group in
                    Section {
                        ForEach(group.items, id: \.id) { session in
                            HistoryRow(session: session)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets())
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        sessionPendingDelete = session
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                            DottedDivider()
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets())
                        }
                    } header: {
                        sectionHeader(group)
                            .listRowInsets(EdgeInsets())
                    }
                    .listRowBackground(Color.clear)
                }
                Color.clear.frame(height: 80)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .listRowSpacing(0)
            .environment(\.defaultMinListRowHeight, 0)
            .scrollContentBackground(.hidden)
            .background(Color.bgPrimary)
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y > 200
            } action: { _, isScrolled in
                if showJumpToTop != isScrolled {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showJumpToTop = isScrolled
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if showJumpToTop {
                    Button {
                        withAnimation(.easeInOut(duration: 0.32)) {
                            proxy.scrollTo(Self.topAnchorID, anchor: .top)
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.bgPrimary)
                            .frame(width: 44, height: 44)
                            .background(Color.textPrimary, in: Circle())
                            .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 20)
                    .padding(.bottom, 24)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    private func sectionHeader(_ group: DayGroup) -> some View {
        let totalSeconds = group.items.reduce(0) { acc, s in
            acc + max(0, Int((s.endAt ?? s.startAt).timeIntervalSince(s.startAt)) - s.totalPausedSeconds)
        }
        return HStack {
            Text(dayLabel(group.date))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer()
            Text(formatDuration(totalSeconds))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
        .background(Color.bgPrimary)
    }

    private func dayLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 44))
                .foregroundStyle(Color.textTertiary.opacity(0.35))
            Text("No focus sessions yet")
                .font(.system(size: 16))
                .foregroundStyle(Color.textTertiary)
            Text("Your timer history will appear here")
                .font(.system(size: 13))
                .foregroundStyle(Color.textTertiary.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct HistoryRow: View {
    @AppStorage("showTaskEmoji") private var showTaskEmoji = true

    let session: TimeSession

    private var duration: Int {
        guard let end = session.endAt else { return 0 }
        return max(0, Int(end.timeIntervalSince(session.startAt)) - session.totalPausedSeconds)
    }

    private var startLabel: String {
        // 24-hour format keeps the leading column compact and prevents
        // "12:00 AM" from wrapping onto two lines.
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: session.startAt)
    }

    var body: some View {
        HStack(spacing: 12) {
            if session.source != .liveTimer {
                // No real start time (quickLog / manualEntry) — leave the
                // column empty so the row reads as "no time recorded" without
                // faking a midnight value.
                Color.clear.frame(width: 48, height: 1)
            } else {
                Text(startLabel)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(width: 48, alignment: .leading)
            }

            if let task = session.workTask {
                if let tag = task.tag, !tag.isSystem {
                    TagDot(color: Color.tagColor(tag.colorToken), style: .filled, size: 8)
                }
                Text(task.displayTitle(showEmoji: showTaskEmoji))
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
            } else {
                Text("Untagged session")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textTertiary)
                    .italic()
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(formatDuration(duration))
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 7)
    }
}

