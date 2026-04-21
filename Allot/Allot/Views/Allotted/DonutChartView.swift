//
//  DonutChartView.swift
//  Allot
//
//  Reusable donut chart. Draws arc segments with Canvas, floats labels outside.
//  Tap a segment → onTapSegment(index).

import SwiftUI

struct DonutSegment: Identifiable {
    let id: UUID
    let color: Color
    let fraction: Double  // 0.0–1.0, sum of all segments = 1.0
    let label: String
    let sublabel: String
}

struct DonutChartView: View {

    let segments: [DonutSegment]
    let centerTitle: String
    let centerSubtitle: String
    var highlightId: UUID? = nil       // nil = all full opacity
    let onTapSegment: (UUID) -> Void

    private let outerFraction: CGFloat = 0.46   // relative to min(width,height)/2
    private let innerFraction: CGFloat = 0.28
    private let gapDegrees: Double = 2.5

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cx   = geo.size.width  / 2
            let cy   = geo.size.height / 2
            let outerR = side * outerFraction
            let innerR = side * innerFraction

            ZStack {
                segmentCanvas(cx: cx, cy: cy, outerR: outerR, innerR: innerR)
                    .contentShape(Circle().scale(outerFraction * 2))
                    .onTapGesture { location in
                        handleTap(location: location, cx: cx, cy: cy,
                                  outerR: outerR, innerR: innerR)
                    }

                centerLabel(cx: cx, cy: cy, innerR: innerR)

                floatingLabels(cx: cx, cy: cy, outerR: outerR)
            }
        }
    }

    // MARK: Segment arcs

    @ViewBuilder
    private func segmentCanvas(cx: CGFloat, cy: CGFloat,
                                outerR: CGFloat, innerR: CGFloat) -> some View {
        Canvas { ctx, _ in
            let info = segmentAngles()

            for (seg, start, end) in info {
                guard end > start else { continue }
                let alpha: Double = (highlightId == nil || highlightId == seg.id) ? 1.0 : 0.25

                var path = Path()
                path.addArc(center: CGPoint(x: cx, y: cy),
                            radius: outerR, startAngle: .degrees(start),
                            endAngle: .degrees(end), clockwise: false)
                path.addArc(center: CGPoint(x: cx, y: cy),
                            radius: innerR, startAngle: .degrees(end),
                            endAngle: .degrees(start), clockwise: true)
                path.closeSubpath()

                ctx.fill(path, with: .color(seg.color.opacity(alpha)))
            }
        }
    }

    // MARK: Center

    @ViewBuilder
    private func centerLabel(cx: CGFloat, cy: CGFloat, innerR: CGFloat) -> some View {
        VStack(spacing: 3) {
            Text(centerTitle)
                .font(.system(size: 26, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
                .minimumScaleFactor(0.6)
            Text(centerSubtitle)
                .font(.system(size: 12))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(width: innerR * 1.6)
        .multilineTextAlignment(.center)
        .position(x: cx, y: cy)
    }

    // MARK: Floating labels

    @ViewBuilder
    private func floatingLabels(cx: CGFloat, cy: CGFloat, outerR: CGFloat) -> some View {
        let labelR = outerR * 1.42
        let info = segmentAngles()

        ForEach(Array(info.enumerated()), id: \.offset) { _, tuple in
            let (seg, start, end) = tuple
            if end > start {
            let mid = (start + end) / 2
            let rad = mid * .pi / 180
            let x = cx + labelR * CGFloat(cos(rad))
            let y = cy + labelR * CGFloat(sin(rad))
            let alpha: Double = (highlightId == nil || highlightId == seg.id) ? 1.0 : 0.3

            VStack(spacing: 2) {
                Text(seg.label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.textPrimary.opacity(alpha))
                Text(seg.sublabel)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.textSecondary.opacity(alpha))
            }
            .multilineTextAlignment(.center)
            .frame(width: 72)
            .position(x: x, y: y)
            }  // end if end > start
        }
    }

    // MARK: Tap detection

    private func handleTap(location: CGPoint, cx: CGFloat, cy: CGFloat,
                           outerR: CGFloat, innerR: CGFloat) {
        let dx = location.x - cx
        let dy = location.y - cy
        let dist = sqrt(dx * dx + dy * dy)
        guard dist >= innerR && dist <= outerR else { return }

        var angle = atan2(dy, dx) * 180 / .pi  // -180..180
        if angle < -90 { angle += 360 }         // normalise to -90..270

        let info = segmentAngles()
        for (seg, start, end) in info {
            if angle >= start && angle <= end {
                onTapSegment(seg.id)
                return
            }
        }
    }

    // MARK: Helpers

    private func segmentAngles() -> [(DonutSegment, Double, Double)] {
        var result: [(DonutSegment, Double, Double)] = []
        var cursor: Double = -90   // start at 12 o'clock
        for seg in segments {
            let sweep = seg.fraction * 360 - gapDegrees
            guard sweep > 0 else { continue }
            result.append((seg, cursor, cursor + sweep))
            cursor += seg.fraction * 360
        }
        return result
    }
}
