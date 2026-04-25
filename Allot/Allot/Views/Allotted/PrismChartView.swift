//
//  PrismChartView.swift
//  Allot
//
//  Isometric prism chart — horizontal bar sliced into proportional segments.
//  Tap to explode: selected segment centers, neighbors slide outward,
//  opacity falls off with distance, edge fade bleeds distant segments off-screen.
//  Matches preview/allotted-prism.html Variant B.

import SwiftUI
import UIKit

// MARK: - Color helper

private extension Color {
    /// Lighten (amount > 0) or darken (amount < 0) in RGB space. Same semantics
    /// as the HTML preview's `shade(hex, amt)`.
    func shaded(by amount: Double) -> Color {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        func clamp(_ v: Double) -> Double { min(1, max(0, v)) }
        return Color(
            red:     clamp(Double(r) + amount),
            green:   clamp(Double(g) + amount),
            blue:    clamp(Double(b) + amount),
            opacity: Double(a)
        )
    }
}

// MARK: - Face shapes (drawn in segment-local coords; bbox = [0, width+dx] × [0, height+dy])

private struct TopFace: Shape {
    let width: CGFloat; let height: CGFloat; let dx: CGFloat; let dy: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to:    CGPoint(x: 0,         y: dy))
        p.addLine(to: CGPoint(x: width,     y: dy))
        p.addLine(to: CGPoint(x: width + dx, y: 0))
        p.addLine(to: CGPoint(x: dx,        y: 0))
        p.closeSubpath()
        return p
    }
}

private struct FrontFace: Shape {
    let width: CGFloat; let height: CGFloat; let dy: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to:    CGPoint(x: 0,     y: dy))
        p.addLine(to: CGPoint(x: width, y: dy))
        p.addLine(to: CGPoint(x: width, y: dy + height))
        p.addLine(to: CGPoint(x: 0,     y: dy + height))
        p.closeSubpath()
        return p
    }
}

private struct CapFace: Shape {
    let width: CGFloat; let height: CGFloat; let dx: CGFloat; let dy: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to:    CGPoint(x: width,      y: dy))
        p.addLine(to: CGPoint(x: width + dx, y: 0))
        p.addLine(to: CGPoint(x: width + dx, y: height))
        p.addLine(to: CGPoint(x: width,      y: dy + height))
        p.closeSubpath()
        return p
    }
}

// MARK: - Single segment (3 faces + strokes)

private struct PrismSegmentView: View {
    let width: CGFloat
    let height: CGFloat
    let dx: CGFloat
    let dy: CGFloat
    let frontColor: Color
    let topColor: Color
    let capColor: Color
    let strokeColor: Color
    let strokeWidth: CGFloat
    let capOpacity: Double

    var body: some View {
        ZStack(alignment: .topLeading) {
            TopFace(width: width, height: height, dx: dx, dy: dy)
                .fill(topColor)
            TopFace(width: width, height: height, dx: dx, dy: dy)
                .stroke(strokeColor, lineWidth: strokeWidth)

            FrontFace(width: width, height: height, dy: dy)
                .fill(frontColor)
            FrontFace(width: width, height: height, dy: dy)
                .stroke(strokeColor, lineWidth: strokeWidth)

            CapFace(width: width, height: height, dx: dx, dy: dy)
                .fill(capColor)
                .opacity(capOpacity)
            CapFace(width: width, height: height, dx: dx, dy: dy)
                .stroke(strokeColor, lineWidth: strokeWidth)
                .opacity(capOpacity)
        }
        .frame(width: width + dx, height: height + dy, alignment: .topLeading)
    }
}

// MARK: - PrismChartView

struct PrismChartView: View {

    let segments: [DonutSegment]
    var highlightId: UUID? = nil
    let onTapSegment: (UUID) -> Void

    // Geometry — tunable knobs matching the HTML preview
    private let barHeight:     CGFloat = 64
    private let depthX:        CGFloat = 24
    private let depthY:        CGFloat = 14
    private let explodedGap:   CGFloat = 100
    private let strokeWidth:   CGFloat = 1.2
    private let hPadding:      CGFloat = 20
    private let falloff:       Double  = 0.5

    var body: some View {
        GeometryReader { geo in
            // Reserve room on the right for the last segment's cap (+depthX) so it
            // never bleeds past the screen edge.
            let widths    = segments.map { CGFloat(max(0, $0.fraction)) * (geo.size.width - hPadding * 2 - depthX) }
            let selIdx    = segments.firstIndex { $0.id == highlightId }
            let exploded  = selIdx != nil
            let lefts     = computeLefts(widths: widths,
                                         selectedIdx: selIdx,
                                         centerX: geo.size.width / 2)
            let yOffset   = (geo.size.height - (barHeight + depthY)) / 2

            ZStack(alignment: .topLeading) {
                ForEach(Array(segments.enumerated()), id: \.element.id) { idx, seg in
                    let w       = widths[idx]
                    let isHollow = exploded && idx != selIdx
                    let isLast   = idx == segments.count - 1
                    let showCap  = exploded || isLast
                    let dist     = selIdx.map { abs(idx - $0) } ?? 0
                    let op: Double = (exploded && dist > 0)
                        ? max(0.04, pow(1 - falloff, Double(dist)))
                        : 1

                    PrismSegmentView(
                        width: w,
                        height: barHeight,
                        dx: depthX, dy: depthY,
                        frontColor: isHollow ? seg.color.opacity(0.10) : seg.color,
                        topColor:   isHollow ? seg.color.opacity(0.05) : seg.color.shaded(by:  0.12),
                        capColor:   isHollow ? seg.color.opacity(0.14) : seg.color.shaded(by: -0.08),
                        strokeColor: isHollow ? seg.color : Color.bgPrimary,
                        strokeWidth: strokeWidth,
                        capOpacity:  showCap ? 1 : 0
                    )
                    .offset(x: lefts[idx], y: yOffset)
                    .opacity(op)
                    .contentShape(Rectangle())
                    .onTapGesture { onTapSegment(seg.id) }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .mask {
                LinearGradient(
                    stops: exploded
                        ? [.init(color: .clear, location: 0.00),
                           .init(color: .black, location: 0.14),
                           .init(color: .black, location: 0.86),
                           .init(color: .clear, location: 1.00)]
                        : [.init(color: .black, location: 0.00),
                           .init(color: .black, location: 1.00)],
                    startPoint: .leading, endPoint: .trailing
                )
            }
            .animation(.spring(response: 0.55, dampingFraction: 0.82), value: highlightId)
        }
    }

    // Position of each segment's top-left corner (in container coords).
    private func computeLefts(widths: [CGFloat],
                              selectedIdx: Int?,
                              centerX: CGFloat) -> [CGFloat] {
        var result = Array(repeating: CGFloat(0), count: widths.count)
        guard let sel = selectedIdx else {
            var x: CGFloat = hPadding
            for i in 0..<widths.count {
                result[i] = x
                x += widths[i]
            }
            return result
        }
        let selW = widths[sel]
        result[sel] = centerX - selW / 2

        // walk left
        var xL = result[sel]
        if sel > 0 {
            for i in stride(from: sel - 1, through: 0, by: -1) {
                xL -= (widths[i] + explodedGap)
                result[i] = xL
            }
        }

        // walk right
        var xR = result[sel] + selW
        if sel < widths.count - 1 {
            for j in (sel + 1)..<widths.count {
                xR += explodedGap
                result[j] = xR
                xR += widths[j]
            }
        }
        return result
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Prism — unified") {
    PrismChartView(
        segments: [
            .init(id: UUID(), color: .tagSky,      fraction: 0.52, label: "Reading",  sublabel: "7h 24m"),
            .init(id: UUID(), color: .tagMarigold, fraction: 0.28, label: "Coding",   sublabel: "4h 00m"),
            .init(id: UUID(), color: .tagRose,     fraction: 0.10, label: "Walk",     sublabel: "1h 26m"),
            .init(id: UUID(), color: .tagLilac,    fraction: 0.10, label: "Journal",  sublabel: "1h 26m"),
        ],
        onTapSegment: { _ in }
    )
    .frame(height: 180)
    .padding()
}
#endif
