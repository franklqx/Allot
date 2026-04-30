//
//  TodayCircularContent.swift
//  Allot
//
//  Shared rendering for the lock-screen circular widget.

import SwiftUI

struct TodayCircularContent: View {
    let snapshot: WidgetSnapshot
    let prefs: WidgetPreferences

    private var byTagBuckets: [WidgetSnapshot.TodayBucket] {
        // Circular ring is always today by-tag — by-task labels are
        // unreadable at this size.
        snapshot.todayBucketsByTag
    }

    var body: some View {
        let total = max(1, snapshot.todayTotalSeconds)
        let buckets = byTagBuckets.prefix(4)
        ZStack {
            ForEach(Array(buckets.enumerated()), id: \.element.id) { idx, b in
                let prior = buckets.prefix(idx).reduce(0) { $0 + $1.seconds }
                let start = Double(prior) / Double(total)
                let end   = Double(prior + b.seconds) / Double(total)
                Circle()
                    .trim(from: start, to: end)
                    .stroke(Color.tagColor(b.colorToken), lineWidth: 4)
                    .rotationEffect(.degrees(-90))
            }
            if byTagBuckets.isEmpty {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
            }
            centerView
        }
        .padding(2)
    }

    @ViewBuilder
    private var centerView: some View {
        switch prefs.todayCircular.center {
        case .totalTime:
            Text(centerTotalLabel(seconds: snapshot.todayTotalSeconds))
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
        case .topTagPercentage:
            if let top = byTagBuckets.first, snapshot.todayTotalSeconds > 0 {
                let pct = Int(round(Double(top.seconds) / Double(snapshot.todayTotalSeconds) * 100))
                Text("\(pct)%")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
            } else {
                Text("—")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        case .topTagEmoji:
            // Emoji-per-bucket isn't carried in TodayBucket today (snapshot
            // stores tag name + colorToken but not emoji). Fall back to a
            // colored dot of the top tag — emoji per bucket is a follow-up.
            if let top = byTagBuckets.first {
                Circle()
                    .fill(Color.tagColor(top.colorToken))
                    .frame(width: 18, height: 18)
            } else {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func centerTotalLabel(seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}
