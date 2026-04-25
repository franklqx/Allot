//
//  AllottedView.swift
//  Allot
//
//  Insights: mode-coupled time range, prism chart, Pareto-aggregated legend.

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

enum AllotMode: String, CaseIterable {
    case task = "Task"
    case tag  = "Tag"

    /// The two time-range tabs shown for this mode.
    var ranges: [TimeRange] {
        switch self {
        case .task: return [.day, .week]
        case .tag:  return [.month, .year]
        }
    }

    var defaultRange: TimeRange {
        switch self {
        case .task: return .week
        case .tag:  return .month
        }
    }
}

struct AllotStat: Identifiable {
    let id: UUID
    let tag: Tag?
    let task: WorkTask?
    let name: String
    var colorToken: String
    var seconds: Int
    var fraction: Double = 0
    let isOthers: Bool
}

// Fixed IDs for synthetic categories
private let untaggedStatId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
private let unboundStatId  = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
private let othersStatId   = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!

/// Max individual segments before rest is bucketed into "Others".
private let kMaxIndividualSegments = 5

/// Palette used in Task mode so each task gets a distinct color
/// (tasks may share a tag color, which would render the prism as one blob).
private let kTaskPalette: [String] = ["sky", "marigold", "rose", "lilac", "lime", "teal"]

// MARK: - AllottedView

struct AllottedView: View {

    @Query private var allSessions: [TimeSession]

    @State private var mode: AllotMode = .task
    @State private var taskRange: TimeRange = .week
    @State private var tagRange:  TimeRange = .month
    @State private var showFilter = false
    @State private var hiddenTagIds:    Set<UUID> = []
    @State private var taskTypeFilter:  TaskType? = nil
    @State private var highlightId:     UUID?     = nil

    private var timeRange: TimeRange {
        mode == .task ? taskRange : tagRange
    }

    // MARK: Computed — sessions

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

    // MARK: Computed — aggregation

    /// Aggregate filtered sessions by tag or task, then bucket rest into Others.
    var stats: [AllotStat] {
        switch mode {
        case .tag:  return aggregateByTag(filteredSessions)
        case .task: return aggregateByTask(filteredSessions)
        }
    }

    private func aggregateByTag(_ sessions: [TimeSession]) -> [AllotStat] {
        var dict: [UUID: (Tag?, String, String, Int)] = [:]
        for s in sessions {
            guard let endAt = s.endAt else { continue }
            let dur = max(0, Int(endAt.timeIntervalSince(s.startAt)) - s.totalPausedSeconds)
            guard dur > 0 else { continue }

            let key: UUID; let tag: Tag?; let name: String; let token: String
            if let task = s.workTask {
                let t = task.tag
                key = t?.id ?? untaggedStatId
                tag = t; name = t?.name ?? "Untagged"; token = t?.colorToken ?? "gray"
            } else {
                key = unboundStatId; tag = nil; name = "Unbound"; token = "gray"
            }
            if let ex = dict[key] { dict[key] = (ex.0, ex.1, ex.2, ex.3 + dur) }
            else { dict[key] = (tag, name, token, dur) }
        }
        let raw = dict.map { (k, v) in
            AllotStat(id: k, tag: v.0, task: nil, name: v.1,
                      colorToken: v.2, seconds: v.3, isOthers: false)
        }
        return paretoCap(raw)
    }

    private func aggregateByTask(_ sessions: [TimeSession]) -> [AllotStat] {
        var dict: [UUID: (WorkTask?, String, String, Int)] = [:]
        for s in sessions {
            guard let endAt = s.endAt else { continue }
            let dur = max(0, Int(endAt.timeIntervalSince(s.startAt)) - s.totalPausedSeconds)
            guard dur > 0 else { continue }

            let key: UUID; let task: WorkTask?; let name: String; let token: String
            if let t = s.workTask {
                key = t.id; task = t; name = t.title
                token = t.tag?.colorToken ?? "gray"
            } else {
                key = unboundStatId; task = nil; name = "Unbound"; token = "gray"
            }
            if let ex = dict[key] { dict[key] = (ex.0, ex.1, ex.2, ex.3 + dur) }
            else { dict[key] = (task, name, token, dur) }
        }
        let raw = dict.map { (k, v) in
            AllotStat(id: k, tag: nil, task: v.0, name: v.1,
                      colorToken: v.2, seconds: v.3, isOthers: false)
        }
        var capped = paretoCap(raw)
        // Re-color non-Others rows from the task palette by sorted position so
        // the prism always shows distinct segments.
        var paletteIdx = 0
        for i in capped.indices where !capped[i].isOthers {
            capped[i].colorToken = kTaskPalette[paletteIdx % kTaskPalette.count]
            paletteIdx += 1
        }
        return capped
    }

    /// Sort descending, keep top 5 individual; if 6+ items exist, bucket rest as "Others".
    /// Fractions computed over grand total (never renormalized) so bar widths stay true.
    private func paretoCap(_ items: [AllotStat]) -> [AllotStat] {
        let sorted = items.sorted { $0.seconds > $1.seconds }
        let total = sorted.reduce(0) { $0 + $1.seconds }
        guard total > 0 else { return [] }

        if sorted.count <= kMaxIndividualSegments {
            return sorted.map { s in
                var out = s; out.fraction = Double(s.seconds) / Double(total); return out
            }
        }

        let head = sorted.prefix(kMaxIndividualSegments)
        let tail = sorted.dropFirst(kMaxIndividualSegments)
        let othersSec = tail.reduce(0) { $0 + $1.seconds }
        var result: [AllotStat] = head.map { s in
            var out = s; out.fraction = Double(s.seconds) / Double(total); return out
        }
        result.append(AllotStat(
            id: othersStatId, tag: nil, task: nil,
            name: "Others", colorToken: "gray",
            seconds: othersSec,
            fraction: Double(othersSec) / Double(total),
            isOthers: true
        ))
        return result
    }

    private var totalSeconds: Int { stats.reduce(0) { $0 + $1.seconds } }

    var segments: [DonutSegment] {
        stats.map { s in
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
                } else {
                    chartContent
                }
            }
            .background(Color.bgPrimary)
            .navigationTitle("Allotted")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showFilter = true } label: {
                        Image(systemName: hasActiveFilter
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease")
                            .foregroundStyle(hasActiveFilter ? Color.accentPrimary : Color.textSecondary)
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

    // MARK: Time range picker (2 tabs, mode-aware)

    private var timeRangePicker: some View {
        let ranges = mode.ranges
        return HStack(spacing: 0) {
            ForEach(ranges, id: \.self) { range in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        setRange(range)
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
                let w = geo.size.width / CGFloat(ranges.count)
                let idx = CGFloat(ranges.firstIndex(of: timeRange) ?? 0)
                Capsule()
                    .fill(Color.accentPrimary)
                    .frame(width: w * 0.36, height: 2)
                    .offset(x: w * idx + w * 0.32)
                    .animation(.easeInOut(duration: 0.18), value: timeRange)
            }
            .frame(height: 2)
        }
    }

    private func setRange(_ range: TimeRange) {
        if mode == .task { taskRange = range } else { tagRange = range }
    }

    private func setMode(_ newMode: AllotMode) {
        guard newMode != mode else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            mode = newMode
            highlightId = nil
        }
    }

    // MARK: Chart content

    private var chartContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerRow
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)

                PrismChartView(
                    segments: segments,
                    highlightId: highlightId,
                    onTapSegment: { id in
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                            highlightId = (highlightId == id) ? nil : id
                        }
                    }
                )
                .frame(height: 180)
                .padding(.bottom, 24)

                legendSection
                    .padding(.bottom, mode == .task ? 24 : 120)

                if mode == .task && !tagOverviewStats.isEmpty {
                    tagOverviewSection
                        .padding(.top, 8)
                        .padding(.bottom, 120)
                }
            }
        }
    }

    // MARK: Header row — big duration + Task/Tag pill

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDuration(totalSeconds))
                    .font(.system(size: 34, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)
                Text(timeRange.rawValue)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textTertiary)
            }
            Spacer()
            modePill
        }
    }

    private var modePill: some View {
        HStack(spacing: 0) {
            ForEach(AllotMode.allCases, id: \.self) { m in
                Button {
                    setMode(m)
                } label: {
                    Text(m.rawValue)
                        .font(.system(size: 12, weight: mode == m ? .semibold : .regular))
                        .foregroundStyle(mode == m ? Color.bgPrimary : Color.textSecondary)
                        .frame(minWidth: 44)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            ZStack {
                                if mode == m {
                                    Capsule().fill(Color.textPrimary)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            Capsule().fill(Color.textPrimary.opacity(0.06))
        )
    }

    // MARK: Legend (Pareto rows with per-row progress bar)

    private var legendSection: some View {
        VStack(spacing: 0) {
            ForEach(stats) { stat in
                legendRow(stat: stat)
                Divider()
                    .padding(.leading, 44)
                    .foregroundStyle(Color.textPrimary.opacity(0.06))
            }
        }
    }

    @ViewBuilder
    private func legendRow(stat: AllotStat) -> some View {
        let dimmed = highlightId != nil && highlightId != stat.id

        // Only tags (in tag mode) navigate to drill page.
        if mode == .tag, let tag = stat.tag {
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

    private func legendLabel(stat: AllotStat, dimmed: Bool, showChevron: Bool) -> some View {
        let color = Color.tagColor(stat.colorToken)
        return HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color.opacity(dimmed ? 0.25 : 1))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 0) {
                    Text(stat.name)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textPrimary.opacity(dimmed ? 0.35 : 1))
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(String(format: "%.0f%%", stat.fraction * 100))
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary.opacity(dimmed ? 0.35 : 1))
                        .frame(width: 40, alignment: .trailing)
                    Text(formatDuration(stat.seconds))
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.textPrimary.opacity(dimmed ? 0.35 : 1))
                        .frame(width: 68, alignment: .trailing)
                }
                progressBar(color: color, fraction: stat.fraction, dimmed: dimmed)
            }
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textTertiary.opacity(0.5))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 11)
    }

    private func progressBar(color: Color, fraction: Double, dimmed: Bool) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.textPrimary.opacity(0.06))
                Capsule()
                    .fill(color.opacity(dimmed ? 0.25 : 1))
                    .frame(width: max(2, geo.size.width * CGFloat(fraction)))
            }
        }
        .frame(height: 3)
    }

    // MARK: Tag overview (Task mode supplement)

    private var tagOverviewStats: [AllotStat] {
        // Reuse tag aggregation for the current filtered sessions.
        aggregateByTag(filteredSessions)
    }

    private var tagOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Tag")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(tagOverviewStats) { stat in
                    tagOverviewRow(stat: stat)
                    Divider()
                        .padding(.leading, 44)
                        .foregroundStyle(Color.textPrimary.opacity(0.06))
                }
            }
        }
    }

    private func tagOverviewRow(stat: AllotStat) -> some View {
        let color = Color.tagColor(stat.colorToken)
        let clickable = stat.tag != nil
        let content = HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(stat.name)
                .font(.system(size: 14))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 8)
            Text(String(format: "%.0f%%", stat.fraction * 100))
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)
                .frame(width: 40, alignment: .trailing)
            Text(formatDuration(stat.seconds))
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 68, alignment: .trailing)
            if clickable {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textTertiary.opacity(0.5))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 11)

        return Group {
            if let tag = stat.tag {
                NavigationLink {
                    AllottedDrillView(tag: tag, timeRange: timeRange, sessions: filteredSessions)
                } label: { content }
            } else {
                content
            }
        }
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
