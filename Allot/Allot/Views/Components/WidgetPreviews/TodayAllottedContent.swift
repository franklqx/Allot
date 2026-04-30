//
//  TodayAllottedContent.swift
//  Allot
//
//  Shared rendering for the Today Allotted widget. Used by widget extension
//  and Settings preview.

import SwiftUI

struct TodayAllottedContent: View {
    let snapshot: WidgetSnapshot
    let prefs: WidgetPreferences

    private var p: WidgetPreferences.TodayAllottedPrefs { prefs.todayAllotted }

    /// Buckets to render after applying (range, axis) and bucketCount cap.
    /// Anything past the cap collapses into a single "Others" gray bucket.
    private var sourceBuckets: [WidgetSnapshot.TodayBucket] {
        let raw: [WidgetSnapshot.TodayBucket]
        switch (p.range, p.view) {
        case (.today, .byTag):  raw = snapshot.todayBucketsByTag
        case (.today, .byTask): raw = snapshot.todayBucketsByTask
        case (.week,  .byTag):  raw = snapshot.weekBucketsByTag
        case (.week,  .byTask): raw = snapshot.weekBucketsByTask
        }
        let cap = max(1, min(5, p.bucketCount))
        guard raw.count > cap else { return raw }
        let head = Array(raw.prefix(cap))
        let othersSeconds = raw.dropFirst(cap).reduce(0) { $0 + $1.seconds }
        return head + [
            WidgetSnapshot.TodayBucket(id: "others", label: "Others", colorToken: "gray", seconds: othersSeconds)
        ]
    }

    private var totalSeconds: Int {
        switch p.range {
        case .today: return snapshot.todayTotalSeconds
        case .week:  return snapshot.weekTotalSeconds
        }
    }

    private var rangeLabel: String {
        switch p.range {
        case .today: return "Today"
        case .week:  return "This week"
        }
    }

    private var miniBuckets: [PrismMiniBucket] {
        let total = max(1, totalSeconds)
        return sourceBuckets.map { b in
            PrismMiniBucket(
                id: b.id,
                label: b.label,
                colorToken: b.colorToken,
                fraction: Double(b.seconds) / Double(total)
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(rangeLabel)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text(formatDurationCompact(totalSeconds))
                        .font(.system(size: 26, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.primary)
                }
                Spacer()
                if let active = snapshot.activeSession {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.tagColor(active.tagColorToken))
                            .frame(width: 7, height: 7)
                        Text("Focusing")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if sourceBuckets.isEmpty {
                emptyChart
            } else {
                PrismMiniView(buckets: miniBuckets, barHeight: 36, depthX: 10, depthY: 6)
                    .frame(height: 50)
                legend
            }
        }
        .padding(12)
    }

    private var emptyChart: some View {
        VStack(spacing: 4) {
            Spacer()
            Text("No data yet")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Start tracking to see patterns")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var legend: some View {
        HStack(spacing: 12) {
            ForEach(sourceBuckets.prefix(3)) { b in
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.tagColor(b.colorToken))
                        .frame(width: 8, height: 8)
                    Text(b.label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
    }
}
