//
//  PrismMiniView.swift
//  Allot
//
//  Static (non-interactive) Prism Chart for widgets. Same visual language as
//  the main app's PrismChartView — horizontal isometric bricks, top + side
//  faces — but without explode/animation logic. Cheap enough for the widget
//  render budget.

import SwiftUI

struct PrismMiniBucket: Identifiable, Hashable {
    let id: String
    let label: String
    let colorToken: String
    let fraction: Double  // 0.0–1.0
}

struct PrismMiniView: View {

    let buckets: [PrismMiniBucket]
    var barHeight: CGFloat = 40
    var depthX: CGFloat = 12
    var depthY: CGFloat = 7
    var horizontalPadding: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            let avail = max(0, geo.size.width - horizontalPadding * 2 - depthX)
            let widths = buckets.map { CGFloat(max(0, $0.fraction)) * avail }
            ZStack(alignment: .topLeading) {
                ForEach(Array(buckets.enumerated()), id: \.element.id) { idx, bucket in
                    let w = max(widths[idx], 6)
                    let x = horizontalPadding + widths.prefix(idx).reduce(0, +)
                    let isLast = idx == buckets.count - 1
                    PrismMiniSegment(
                        width: w,
                        height: barHeight,
                        dx: depthX,
                        dy: depthY,
                        color: Color.tagColor(bucket.colorToken),
                        showCap: isLast,
                        strokeColor: Color.bgPrimary
                    )
                    .frame(width: w + (isLast ? depthX : 0),
                           height: barHeight + depthY,
                           alignment: .topLeading)
                    .offset(x: x, y: (geo.size.height - (barHeight + depthY)) / 2)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
    }
}

private struct PrismMiniSegment: View {
    let width: CGFloat
    let height: CGFloat
    let dx: CGFloat
    let dy: CGFloat
    let color: Color
    let showCap: Bool
    let strokeColor: Color

    var body: some View {
        ZStack(alignment: .topLeading) {
            TopMiniFace(width: width, height: height, dx: dx, dy: dy)
                .fill(color.opacity(0.85))
            TopMiniFace(width: width, height: height, dx: dx, dy: dy)
                .stroke(strokeColor, lineWidth: 0.8)

            FrontMiniFace(width: width, height: height, dy: dy)
                .fill(color)
            FrontMiniFace(width: width, height: height, dy: dy)
                .stroke(strokeColor, lineWidth: 0.8)

            if showCap {
                CapMiniFace(width: width, height: height, dx: dx, dy: dy)
                    .fill(color.opacity(0.7))
                CapMiniFace(width: width, height: height, dx: dx, dy: dy)
                    .stroke(strokeColor, lineWidth: 0.8)
            }
        }
    }
}

private struct TopMiniFace: Shape {
    let width: CGFloat; let height: CGFloat; let dx: CGFloat; let dy: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: dy))
        p.addLine(to: CGPoint(x: width, y: dy))
        p.addLine(to: CGPoint(x: width + dx, y: 0))
        p.addLine(to: CGPoint(x: dx, y: 0))
        p.closeSubpath()
        return p
    }
}

private struct FrontMiniFace: Shape {
    let width: CGFloat; let height: CGFloat; let dy: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: dy))
        p.addLine(to: CGPoint(x: width, y: dy))
        p.addLine(to: CGPoint(x: width, y: dy + height))
        p.addLine(to: CGPoint(x: 0, y: dy + height))
        p.closeSubpath()
        return p
    }
}

private struct CapMiniFace: Shape {
    let width: CGFloat; let height: CGFloat; let dx: CGFloat; let dy: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: width, y: dy))
        p.addLine(to: CGPoint(x: width + dx, y: 0))
        p.addLine(to: CGPoint(x: width + dx, y: height))
        p.addLine(to: CGPoint(x: width, y: dy + height))
        p.closeSubpath()
        return p
    }
}
