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
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2     // Monday — week always runs Mon→Sun.
        switch self {
        case .day:
            let s = cal.startOfDay(for: now)
            return (s, cal.date(byAdding: .day, value: 1, to: s)!)
        case .week:
            let s = cal.dateInterval(of: .weekOfYear, for: now)?.start
                ?? cal.startOfDay(for: now)
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

    /// Time-range tabs shown for this mode.
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
    /// Source items that were merged into this Others bucket (only set on the
    /// synthetic Others stat). Each element mirrors a top-level AllotStat.
    var othersChildren: [OthersChild]? = nil
}

struct OthersChild: Identifiable {
    let id: UUID
    let name: String
    let colorToken: String
    let seconds: Int
    let isTagItem: Bool   // true → render circle; false → render box
}

private let untaggedStatId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
private let unboundStatId  = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
private let othersStatId   = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!

private let kMaxIndividualSegments = 5

private let kTaskPalette: [String] = ["sky", "marigold", "rose", "lilac", "lime", "teal"]

// MARK: - AllottedView

struct AllottedView: View {

    /// Single shared date, owned by ContentView. Home strip and Allotted anchor
    /// read/write the same value so navigating one updates the other and the
    /// FAB-to-today action can reset both at once.
    @Binding var anchorDate: Date

    @Query private var allSessions: [TimeSession]

    @State private var mode: AllotMode = .task
    @State private var taskRange: TimeRange = .week
    @State private var tagRange:  TimeRange = .month
    @State private var showFilter = false
    @State private var hiddenTagIds:    Set<UUID> = []
    @State private var taskTypeFilter:  TaskType? = nil
    @State private var highlightId:     UUID?     = nil
    @State private var expandedLegendId: UUID?    = nil   // legend (tag mode) expansion
    @State private var expandedByTagId:  UUID?    = nil   // "By Tag" supplementary section (task mode)

    init(anchorDate: Binding<Date>) {
        self._anchorDate = anchorDate
    }

    private var timeRange: TimeRange {
        mode == .task ? taskRange : tagRange
    }

    // MARK: Computed — sessions

    var filteredSessions: [TimeSession] {
        let (start, end) = timeRange.interval(from: anchorDate)
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

    // MARK: Period navigation

    private var periodLabel: String {
        let cal = Calendar.current
        let (start, end) = timeRange.interval(from: anchorDate)
        switch timeRange {
        case .day:
            return start.formatted(.dateTime.month(.abbreviated).day())
        case .week:
            let last = cal.date(byAdding: .day, value: -1, to: end) ?? end
            let s = start.formatted(.dateTime.month(.abbreviated).day())
            let e = last.formatted(.dateTime.month(.abbreviated).day())
            return "\(s) – \(e)"
        case .month:
            return start.formatted(.dateTime.month(.wide).year())
        case .year:
            return start.formatted(.dateTime.year())
        }
    }

    private func shiftPeriod(by offset: Int) {
        let cal = Calendar.current
        let component: Calendar.Component
        switch timeRange {
        case .day:   component = .day
        case .week:  component = .weekOfYear
        case .month: component = .month
        case .year:  component = .year
        }
        if let next = cal.date(byAdding: component, value: offset, to: anchorDate) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeInOut(duration: 0.18)) {
                anchorDate = next
                highlightId = nil
                expandedLegendId = nil
                expandedByTagId = nil
            }
        }
    }

    // MARK: Computed — aggregation

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
        var paletteIdx = 0
        for i in capped.indices where !capped[i].isOthers {
            capped[i].colorToken = kTaskPalette[paletteIdx % kTaskPalette.count]
            paletteIdx += 1
        }
        return capped
    }

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
        let children = tail.map { s in
            OthersChild(
                id: s.id,
                name: s.name,
                colorToken: s.colorToken,
                seconds: s.seconds,
                isTagItem: s.tag != nil || s.id == untaggedStatId || s.id == unboundStatId
            )
        }
        var others = AllotStat(
            id: othersStatId, tag: nil, task: nil,
            name: "Others", colorToken: "gray",
            seconds: othersSec,
            fraction: Double(othersSec) / Double(total),
            isOthers: true
        )
        others.othersChildren = children
        result.append(others)
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
                periodHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                if totalSeconds == 0 {
                    emptyState
                } else {
                    chartContent
                }
            }
            .background(Color.bgPrimary)
            // Horizontal swipe shifts the period — works in empty state too.
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        if value.translation.width < -threshold {
                            shiftPeriod(by: 1)
                        } else if value.translation.width > threshold {
                            shiftPeriod(by: -1)
                        }
                    }
            )
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
                FilterDrawerView(mode: $mode,
                                 hiddenTagIds: $hiddenTagIds,
                                 taskTypeFilter: $taskTypeFilter)
                    .presentationDetents([.medium])
                    .presentationBackground(Color.bgElevated)
            }
            .onChange(of: mode) { _, _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    highlightId = nil
                    expandedLegendId = nil
                    expandedByTagId = nil
                }
            }
            .onChange(of: timeRange) { _, _ in
                expandedLegendId = nil
                expandedByTagId = nil
            }
        }
    }

    // MARK: Time range picker

    private var timeRangePicker: some View {
        let ranges = mode.ranges
        return HStack(spacing: 0) {
            ForEach(ranges, id: \.self) { range in
                Button {
                    if range != timeRange {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    withAnimation(.easeInOut(duration: 0.18)) {
                        setRange(range)
                        highlightId = nil
                        expandedLegendId = nil
                        expandedByTagId = nil
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

    // MARK: Chart content

    private var chartContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                totalRow
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 20)

                PrismChartView(
                    segments: segments,
                    highlightId: highlightId,
                    onTapSegment: { id in
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                            highlightId = (highlightId == id) ? nil : id
                            // In tag mode (or for the Others bucket in either
                            // mode), also pop the legend row open so the user
                            // can read the breakdown without scrolling-and-tapping.
                            let stat = stats.first(where: { $0.id == id })
                            let canExpand = stat?.isOthers == true ||
                                (mode == .tag && stat != nil)
                            if canExpand {
                                expandedLegendId = (expandedLegendId == id) ? nil : id
                            }
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

    // MARK: Period header

    private var periodHeader: some View {
        HStack(spacing: 4) {
            Button { shiftPeriod(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 36, height: 32)
            }
            .buttonStyle(.plain)

            Text(periodLabel)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity)
                .contentTransition(.numericText())

            Button { shiftPeriod(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 36, height: 32)
            }
            .buttonStyle(.plain)
            .disabled(isFutureDisabled)
            .opacity(isFutureDisabled ? 0.3 : 1)
        }
    }

    private var isFutureDisabled: Bool {
        let cal = Calendar.current
        let component: Calendar.Component
        switch timeRange {
        case .day:   component = .day
        case .week:  component = .weekOfYear
        case .month: component = .month
        case .year:  component = .year
        }
        guard let next = cal.date(byAdding: component, value: 1, to: anchorDate) else { return true }
        let (start, _) = timeRange.interval(from: next)
        return start > Date()
    }

    private var totalRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(formatDuration(totalSeconds))
                .font(.system(size: 34, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
            Text(mode.rawValue)
                .font(.system(size: 13))
                .foregroundStyle(Color.textTertiary)
                .padding(.leading, 4)
            Spacer()
        }
    }

    // MARK: Legend (Pareto rows with per-row progress bar)

    private var legendSection: some View {
        VStack(spacing: 0) {
            ForEach(stats) { stat in
                legendRow(stat: stat)
                if expandedLegendId == stat.id {
                    inlineBreakdown(stat: stat)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                DottedDivider()
            }
        }
    }

    /// Expandable when there's something useful to drill into:
    ///   • tag mode legend: real tag / Untagged / Others (any stat with content)
    ///   • Others row in either mode (shows merged source items)
    @ViewBuilder
    private func legendRow(stat: AllotStat) -> some View {
        let dimmed = highlightId != nil && highlightId != stat.id
        let expandable: Bool = {
            if stat.isOthers, let kids = stat.othersChildren, !kids.isEmpty { return true }
            if mode == .tag { return !legendBreakdownEntries(for: stat).isEmpty }
            return false
        }()
        let isExpanded = expandable && expandedLegendId == stat.id

        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeInOut(duration: 0.22)) {
                if expandable {
                    expandedLegendId = (expandedLegendId == stat.id) ? nil : stat.id
                    highlightId = (expandedLegendId == stat.id) ? stat.id : nil
                } else {
                    highlightId = (highlightId == stat.id) ? nil : stat.id
                }
            }
        } label: {
            legendLabel(stat: stat, dimmed: dimmed, isExpanded: isExpanded, expandable: expandable)
        }
        .buttonStyle(.plain)
    }

    private func legendLabel(stat: AllotStat, dimmed: Bool, isExpanded: Bool, expandable: Bool) -> some View {
        let color = Color.tagColor(stat.colorToken)
        // Others row stays visually identical to non-expandable rows — just an
        // ordinary line item that happens to expand on tap.
        let showChevron = expandable && !stat.isOthers
        return HStack(spacing: 12) {
            indicator(stat: stat, color: color, dimmed: dimmed)

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
                        .frame(width: 80, alignment: .trailing)
                }
                progressBar(color: color, fraction: stat.fraction, dimmed: dimmed)
            }
            if showChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textTertiary.opacity(0.6))
                    .rotationEffect(.degrees(isExpanded ? 0 : -90))
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func indicator(stat: AllotStat, color: Color, dimmed: Bool) -> some View {
        let fade = color.opacity(dimmed ? 0.25 : 1)
        if mode == .tag {
            TagDot(color: fade, style: .filled, size: 12)
        } else {
            TaskBox(color: fade, style: .filled, size: 12, cornerRadius: 3)
        }
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

    // MARK: Inline tag → task breakdown (shared by legend & By-Tag section)

    /// Tasks aggregated under a given stat (real tag, Untagged synthetic, or
    /// Unbound synthetic). Returns empty if there's nothing to drill into.
    private func legendBreakdownEntries(for stat: AllotStat) -> [(task: WorkTask, seconds: Int)] {
        var dict: [UUID: (WorkTask, Int)] = [:]
        for s in filteredSessions {
            guard let endAt = s.endAt, let task = s.workTask else { continue }
            let belongs: Bool
            if let tag = stat.tag {
                belongs = task.tag?.id == tag.id
            } else if stat.id == untaggedStatId {
                belongs = task.tag == nil || (task.tag?.isSystem ?? false)
            } else {
                belongs = false   // Unbound / Others — no per-task drill
            }
            guard belongs else { continue }
            let dur = max(0, Int(endAt.timeIntervalSince(s.startAt)) - s.totalPausedSeconds)
            guard dur > 0 else { continue }
            if let ex = dict[task.id] { dict[task.id] = (ex.0, ex.1 + dur) }
            else { dict[task.id] = (task, dur) }
        }
        return dict.values.map { ($0.0, $0.1) }.sorted { $0.1 > $1.1 }
    }

    @ViewBuilder
    private func inlineBreakdown(stat: AllotStat) -> some View {
        // Others row → render the merged source items directly.
        if stat.isOthers, let kids = stat.othersChildren, !kids.isEmpty {
            othersChildrenBreakdown(kids)
        } else {
            tagTaskBreakdown(for: stat)
        }
    }

    @ViewBuilder
    private func othersChildrenBreakdown(_ kids: [OthersChild]) -> some View {
        let total = kids.reduce(0) { $0 + $1.seconds }
        VStack(spacing: 0) {
            ForEach(kids) { kid in
                let frac = total > 0 ? Double(kid.seconds) / Double(total) : 0
                HStack(spacing: 12) {
                    if kid.isTagItem {
                        TagDot(color: Color.tagColor(kid.colorToken), style: .filled, size: 10)
                    } else {
                        TaskBox(color: Color.tagColor(kid.colorToken), style: .filled, size: 10, cornerRadius: 2.5)
                    }
                    Text(kid.name)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(String(format: "%.0f%%", frac * 100))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textTertiary)
                        .frame(width: 40, alignment: .trailing)
                    Text(formatDuration(kid.seconds))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.textSecondary)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.leading, 44)
                .padding(.trailing, 20)
                .padding(.vertical, 7)
            }
        }
        .padding(.bottom, 6)
        .background(Color.textPrimary.opacity(0.025))
    }

    @ViewBuilder
    private func tagTaskBreakdown(for stat: AllotStat) -> some View {
        let entries = legendBreakdownEntries(for: stat)
        let total = entries.reduce(0) { $0 + $1.seconds }
        let baseColor = stat.tag.map { Color.tagColor($0.colorToken) } ?? Color.textTertiary
        if entries.isEmpty {
            Text("No tasks here yet")
                .font(.system(size: 13))
                .foregroundStyle(Color.textTertiary)
                .padding(.horizontal, 44)
                .padding(.vertical, 10)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.task.id) { idx, entry in
                    let frac = total > 0 ? Double(entry.seconds) / Double(total) : 0
                    let denom = Double(max(1, entries.count - 1))
                    let opacity = entries.count > 1
                        ? 0.4 + 0.6 * Double(entries.count - 1 - idx) / denom
                        : 1.0
                    HStack(spacing: 12) {
                        TaskBox(
                            color: baseColor.opacity(opacity),
                            style: .filled,
                            size: 10,
                            cornerRadius: 2.5
                        )
                        Text(entry.task.title)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(String(format: "%.0f%%", frac * 100))
                            .font(.system(size: 12))
                            .foregroundStyle(Color.textTertiary)
                            .frame(width: 40, alignment: .trailing)
                        Text(formatDuration(entry.seconds))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.textSecondary)
                            .frame(width: 68, alignment: .trailing)
                    }
                    .padding(.leading, 44)
                    .padding(.trailing, 20)
                    .padding(.vertical, 7)
                }
            }
            .padding(.bottom, 6)
            .background(Color.textPrimary.opacity(0.025))
        }
    }

    // MARK: Tag overview (Task mode supplement)

    private var tagOverviewStats: [AllotStat] {
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
                    if expandedByTagId == stat.id {
                        inlineBreakdown(stat: stat)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    Divider()
                        .padding(.leading, 44)
                        .foregroundStyle(Color.textPrimary.opacity(0.06))
                }
            }
        }
    }

    @ViewBuilder
    private func tagOverviewRow(stat: AllotStat) -> some View {
        let color = Color.tagColor(stat.colorToken)
        let expandable = !legendBreakdownEntries(for: stat).isEmpty
        let isExpanded = expandable && expandedByTagId == stat.id

        Button {
            guard expandable else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeInOut(duration: 0.22)) {
                expandedByTagId = isExpanded ? nil : stat.id
            }
        } label: {
            HStack(spacing: 12) {
                TagDot(color: color, style: .filled, size: 10)
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
                if expandable {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.textTertiary.opacity(0.6))
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
