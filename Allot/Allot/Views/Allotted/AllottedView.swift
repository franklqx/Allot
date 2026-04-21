//
//  AllottedView.swift
//  Allot
//
//  Insights: time-range picker, donut chart, list/chart toggle, filter drawer, drill-down.

import SwiftUI
import SwiftData

// MARK: - Supporting types

enum TimeRange: String, CaseIterable {
    case day   = "Day"
    case week  = "Week"
    case month = "Month"
    case year  = "Year"

    func interval(from now: Date = Date()) -> (start: Date, end: Date) {
        let cal = Calendar.current
        switch self {
        case .day:
            let s = cal.startOfDay(for: now)
            return (s, cal.date(byAdding: .day, value: 1, to: s)!)
        case .week:
            let s = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            return (s, cal.date(byAdding: .weekOfYear, value: 1, to: s)!)
        case .month:
            let s = cal.date(from: cal.dateComponents([.year, .month], from: now))!
            return (s, cal.date(byAdding: .month, value: 1, to: s)!)
        case .year:
            let s = cal.date(from: cal.dateComponents([.year], from: now))!
            return (s, cal.date(byAdding: .year, value: 1, to: s)!)
        }
    }
}

struct TagStat: Identifiable {
    let id: UUID
    let tag: Tag?
    let name: String
    let colorToken: String
    var seconds: Int
    var fraction: Double = 0
}

// Fixed IDs for synthetic categories
private let untaggedStatId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
private let unboundStatId  = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

// MARK: - AllottedView

struct AllottedView: View {

    @Query private var allSessions: [TimeSession]

    @State private var timeRange: TimeRange = .week
    @State private var showList    = false
    @State private var showFilter  = false
    @State private var hiddenTagIds:    Set<UUID> = []
    @State private var taskTypeFilter:  TaskType? = nil
    @State private var highlightId:     UUID?     = nil

    // MARK: Computed

    var filteredSessions: [TimeSession] {
        let (start, end) = timeRange.interval()
        return allSessions.filter { s in
            guard s.endAt != nil else { return false }
            guard s.startAt >= start && s.startAt < end else { return false }
            if let f = taskTypeFilter {
                guard let task = s.workTask, task.type == f else { return false }
            }
            if let tagId = s.workTask?.tag?.id, hiddenTagIds.contains(tagId) { return false }
            return true
        }
    }

    var tagStats: [TagStat] {
        var dict: [UUID: (Tag?, String, String, Int)] = [:]
        for s in filteredSessions {
            guard let endAt = s.endAt else { continue }
            let dur = max(0, Int(endAt.timeIntervalSince(s.startAt)) - s.totalPausedSeconds)
            guard dur > 0 else { continue }

            let key: UUID; let tag: Tag?; let name: String; let token: String
            if let task = s.workTask {
                let t = task.tag
                key = t?.id ?? untaggedStatId
                tag = t; name = t?.name ?? "Untagged"; token = t?.colorToken ?? "stone"
            } else {
                key = unboundStatId; tag = nil; name = "Unbound"; token = "stone"
            }

            if let ex = dict[key] { dict[key] = (ex.0, ex.1, ex.2, ex.3 + dur) }
            else { dict[key] = (tag, name, token, dur) }
        }
        let total = dict.values.reduce(0) { $0 + $1.3 }
        guard total > 0 else { return [] }
        return dict.map { (k, v) in
            TagStat(id: k, tag: v.0, name: v.1, colorToken: v.2,
                    seconds: v.3, fraction: Double(v.3) / Double(total))
        }.sorted { $0.seconds > $1.seconds }
    }

    private var totalSeconds: Int { tagStats.reduce(0) { $0 + $1.seconds } }

    var segments: [DonutSegment] {
        tagStats.map { s in
            DonutSegment(id: s.id, color: Color.tagColor(s.colorToken),
                         fraction: s.fraction,
                         label: s.name, sublabel: formatDuration(s.seconds))
        }
    }

    private var hasActiveFilter: Bool { !hiddenTagIds.isEmpty || taskTypeFilter != nil }

    // MARK: Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                timeRangePicker
                Divider().foregroundStyle(Color.textPrimary.opacity(0.06))
                if totalSeconds == 0 {
                    emptyState
                } else if showList {
                    listContent
                } else {
                    chartContent
                }
            }
            .background(Color.bgPrimary)
            .navigationTitle("Allotted")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 14) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { showList.toggle() }
                        } label: {
                            Image(systemName: showList ? "chart.pie" : "list.bullet")
                                .foregroundStyle(Color.textSecondary)
                        }
                        Button { showFilter = true } label: {
                            Image(systemName: hasActiveFilter
                                  ? "line.3.horizontal.decrease.circle.fill"
                                  : "line.3.horizontal.decrease")
                                .foregroundStyle(hasActiveFilter ? Color.accentPrimary : Color.textSecondary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showFilter) {
                FilterDrawerView(hiddenTagIds: $hiddenTagIds, taskTypeFilter: $taskTypeFilter)
                    .presentationDetents([.medium])
                    .presentationBackground(Color.bgElevated)
            }
        }
    }

    // MARK: Time range picker

    private var timeRangePicker: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        timeRange = range
                        highlightId = nil
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 14, weight: timeRange == range ? .semibold : .regular))
                        .foregroundStyle(timeRange == range ? Color.textPrimary : Color.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .overlay(alignment: .bottom) {
            GeometryReader { geo in
                let w = geo.size.width / CGFloat(TimeRange.allCases.count)
                let idx = CGFloat(TimeRange.allCases.firstIndex(of: timeRange) ?? 0)
                Capsule()
                    .fill(Color.accentPrimary)
                    .frame(width: w * 0.36, height: 2)
                    .offset(x: w * idx + w * 0.32)
                    .animation(.easeInOut(duration: 0.18), value: timeRange)
            }
            .frame(height: 2)
        }
    }

    // MARK: Chart content

    private var chartContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                DonutChartView(
                    segments: segments,
                    centerTitle: formatDuration(totalSeconds),
                    centerSubtitle: timeRange.rawValue,
                    highlightId: highlightId,
                    onTapSegment: { id in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            highlightId = (highlightId == id) ? nil : id
                        }
                    }
                )
                .frame(height: 300)
                .padding(.vertical, 16)

                legendSection
                    .padding(.bottom, 120)
            }
        }
    }

    // MARK: Legend rows

    private var legendSection: some View {
        VStack(spacing: 0) {
            ForEach(tagStats) { stat in
                legendRow(stat: stat)
                Divider()
                    .padding(.leading, 44)
                    .foregroundStyle(Color.textPrimary.opacity(0.06))
            }
        }
    }

    @ViewBuilder
    private func legendRow(stat: TagStat) -> some View {
        let dimmed = highlightId != nil && highlightId != stat.id
        if let tag = stat.tag {
            NavigationLink {
                AllottedDrillView(tag: tag, timeRange: timeRange, sessions: filteredSessions)
            } label: {
                legendLabel(stat: stat, dimmed: dimmed, showChevron: true)
            }
        } else {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    highlightId = (highlightId == stat.id) ? nil : stat.id
                }
            } label: {
                legendLabel(stat: stat, dimmed: dimmed, showChevron: false)
            }
            .buttonStyle(.plain)
        }
    }

    private func legendLabel(stat: TagStat, dimmed: Bool, showChevron: Bool) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.tagColor(stat.colorToken).opacity(dimmed ? 0.25 : 1))
                .frame(width: 12, height: 12)
            Text(stat.name)
                .font(.system(size: 14))
                .foregroundStyle(Color.textPrimary.opacity(dimmed ? 0.35 : 1))
            Spacer()
            Text(String(format: "%.0f%%", stat.fraction * 100))
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary.opacity(dimmed ? 0.35 : 1))
                .frame(width: 40, alignment: .trailing)
            Text(formatDuration(stat.seconds))
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.textPrimary.opacity(dimmed ? 0.35 : 1))
                .frame(width: 68, alignment: .trailing)
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textTertiary.opacity(0.5))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 11)
    }

    // MARK: List content

    private var listContent: some View {
        List {
            ForEach(tagStats) { stat in
                if let tag = stat.tag {
                    NavigationLink {
                        AllottedDrillView(tag: tag, timeRange: timeRange, sessions: filteredSessions)
                    } label: {
                        listLabel(stat: stat)
                    }
                } else {
                    listLabel(stat: stat)
                }
            }
            .listRowBackground(Color.bgPrimary)
            .listRowSeparatorTint(Color.textPrimary.opacity(0.06))
        }
        .listStyle(.plain)
        .background(Color.bgPrimary)
    }

    private func listLabel(stat: TagStat) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.tagColor(stat.colorToken))
                .frame(width: 10, height: 10)
            Text(stat.name)
                .font(.system(size: 15))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDuration(stat.seconds))
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)
                Text(String(format: "%.0f%%", stat.fraction * 100))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 44))
                .foregroundStyle(Color.textTertiary.opacity(0.35))
                .padding(.bottom, 8)
            Text("No sessions this \(timeRange.rawValue.lowercased())")
                .font(.system(size: 16))
                .foregroundStyle(Color.textTertiary)
            Text("Start a timer to see your time breakdown")
                .font(.system(size: 14))
                .foregroundStyle(Color.textTertiary.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 100)
    }
}
