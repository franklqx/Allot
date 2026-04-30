//
//  OnboardingPrismDemoStep.swift
//  Allot
//
//  The pitch: tap a brick, see where time goes. Same Prism as the main app,
//  same haptic, same selection behavior — let users feel the product before
//  they have any data of their own.

import SwiftUI
import UIKit

struct OnboardingPrismDemoStep: View {

    @Bindable var state: OnboardingState
    let onNext: () -> Void

    @State private var selectedId: UUID?

    private struct DemoBrick: Identifiable {
        let id = UUID()
        let label: String
        let seconds: Int
        let colorToken: String
        let insight: String
    }

    private let bricks: [DemoBrick] = [
        .init(label: "Work",   seconds: 18 * 3600 + 32 * 60, colorToken: "sky",
              insight: "Most of your week."),
        .init(label: "Health", seconds:  9 * 3600 + 12 * 60, colorToken: "lime",
              insight: "Half an hour a day. Solid."),
        .init(label: "Learn",  seconds:  6 * 3600 +  5 * 60, colorToken: "lilac",
              insight: "Learning compounds. Keep stacking."),
        .init(label: "Hobby",  seconds:  4 * 3600 + 47 * 60, colorToken: "rose",
              insight: "Time on what you love."),
        .init(label: "Life",   seconds:  3 * 3600 + 42 * 60, colorToken: "marigold",
              insight: "The rest of life."),
    ]

    private var totalSeconds: Int { bricks.reduce(0) { $0 + $1.seconds } }

    private var segments: [DonutSegment] {
        let total = Double(totalSeconds)
        return bricks.map { brick in
            DonutSegment(
                id: brick.id,
                color: Color.tagColor(brick.colorToken),
                fraction: Double(brick.seconds) / total,
                label: brick.label,
                sublabel: formatDurationCompact(brick.seconds)
            )
        }
    }

    private var selectedBrick: DemoBrick? {
        guard let id = selectedId else { return nil }
        return bricks.first { $0.id == id }
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Tap a brick.")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text("See where time goes.")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.top, 40)

            VStack(spacing: 4) {
                Text("This week")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
                Text(formatDurationCompact(totalSeconds))
                    .font(.system(size: 44, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)
            }
            .padding(.top, 12)

            PrismChartView(
                segments: segments,
                highlightId: selectedId,
                onTapSegment: { id in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                        selectedId = (selectedId == id) ? nil : id
                    }
                    state.didExplorePrism = true
                }
            )
            .frame(height: 180)

            insightPanel
                .frame(height: 92)
                .padding(.horizontal, 28)

            Spacer(minLength: 0)
        }
        .padding(.bottom, 24)
    }

    @ViewBuilder
    private var insightPanel: some View {
        if let brick = selectedBrick {
            let pct = Int(round(Double(brick.seconds) / Double(totalSeconds) * 100))
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.tagColor(brick.colorToken))
                        .frame(width: 14, height: 14)
                    Text(brick.label)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text("·")
                        .foregroundStyle(Color.textTertiary)
                    Text(formatDurationCompact(brick.seconds))
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(Color.textPrimary)
                    Text("·")
                        .foregroundStyle(Color.textTertiary)
                    Text("\(pct)%")
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(Color.textSecondary)
                    Spacer()
                }
                Text(brick.insight)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        } else {
            VStack(spacing: 6) {
                Text("Pick any brick to see the breakdown.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textSecondary)
                Text("After a few weeks of tracking, this is your real life on a page.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
