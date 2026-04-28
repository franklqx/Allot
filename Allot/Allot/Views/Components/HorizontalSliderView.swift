//
//  HorizontalSliderView.swift
//  Allot
//
//  Black-card drag ruler. Two modes:
//  • .timeOfDay  — 00:00 – 23:55, 5-min steps  (startTime)
//  • .duration   — 5 min – 12h,   5-min steps  (countdownDuration / quickLog)

import SwiftUI

struct HorizontalSliderView: View {

    enum Mode { case timeOfDay, duration }

    let mode: Mode
    let title: String
    /// Minutes from midnight (timeOfDay) OR total minutes (duration).
    @Binding var valueMinutes: Int
    let onDismiss: () -> Void

    @State private var dragBaseMinutes: Int = 0
    @State private var isDragging = false
    @State private var pixelOffset: CGFloat = 0

    private let tickSpacing: CGFloat = 14  // px per 5-min step (tighter = denser ruler, easier precise drag)
    private var maxMinutes: Int { mode == .timeOfDay ? 23 * 60 + 55 : 12 * 60 }
    private var minMinutes: Int { mode == .timeOfDay ? 0 : 5 }

    var body: some View {
        VStack(spacing: 0) {
            GrabberView()
                .colorMultiply(.white)

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.top, 4)

            Text(displayValue)
                .font(.system(size: 52, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.none, value: valueMinutes)
                .padding(.top, 8)

            ruler
                .frame(height: 96)
                .gesture(dragGesture)
                .padding(.top, 16)

            Button {
                onDismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.accentPrimary)
            }
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .background(Color.black, in: RoundedRectangle(cornerRadius: Radius.xl))
    }

    // MARK: Display

    private var displayValue: String {
        switch mode {
        case .timeOfDay: return formatStartTime(valueMinutes)
        case .duration:  return formatDuration(valueMinutes * 60)
        }
    }

    // MARK: Ruler Canvas

    private var ruler: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            // Ticks centered vertically in the upper 60% of the canvas; labels
            // sit below. Cursor spans the whole height for visual emphasis.
            let tickCenterY = size.height * 0.42
            let currentStep = valueMinutes / 5
            let visible = Int(size.width / tickSpacing) + 6

            for i in 0..<visible {
                let step = currentStep - visible / 2 + i
                guard step >= (minMinutes / 5) && step <= (maxMinutes / 5) else { continue }

                let minutesAtStep = step * 5
                let x = cx + CGFloat(i - visible / 2) * tickSpacing + pixelOffset
                let isHour = minutesAtStep % 60 == 0
                let isHalf = minutesAtStep % 30 == 0 && !isHour
                let h: CGFloat = isHour ? 26 : (isHalf ? 16 : 8)
                let opacity: CGFloat = isHour ? 0.55 : (isHalf ? 0.32 : 0.16)

                var p = Path()
                p.move(to: CGPoint(x: x, y: tickCenterY - h / 2))
                p.addLine(to: CGPoint(x: x, y: tickCenterY + h / 2))
                ctx.stroke(p, with: .color(.white.opacity(opacity)), lineWidth: 1)

                // Label every hour tick (skip if it would crowd the cursor).
                if isHour {
                    let label = hourLabel(forMinutes: minutesAtStep)
                    let text = Text(label)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.42))
                    let resolved = ctx.resolve(text)
                    ctx.draw(
                        resolved,
                        at: CGPoint(x: x, y: tickCenterY + 22),
                        anchor: .top
                    )
                }
            }

            // Red cursor — true red (#FF3B30-ish) so it stays visible on the
            // black ruler regardless of light/dark color-scheme mapping.
            let cursorColor = Color(red: 1.0, green: 0.27, blue: 0.23)
            var cursor = Path()
            cursor.move(to: CGPoint(x: cx, y: 0))
            cursor.addLine(to: CGPoint(x: cx, y: size.height))
            ctx.stroke(cursor, with: .color(cursorColor), lineWidth: 2.5)

            // Cursor cap — small triangle at top to read as a "selector".
            var cap = Path()
            cap.move(to: CGPoint(x: cx - 5, y: 0))
            cap.addLine(to: CGPoint(x: cx + 5, y: 0))
            cap.addLine(to: CGPoint(x: cx, y: 7))
            cap.closeSubpath()
            ctx.fill(cap, with: .color(cursorColor))
        }
    }

    private func hourLabel(forMinutes m: Int) -> String {
        switch mode {
        case .timeOfDay:
            return String(format: "%02d:00", m / 60)
        case .duration:
            let h = m / 60
            return h == 0 ? "0" : "\(h)h"
        }
    }

    // MARK: Drag

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    dragBaseMinutes = valueMinutes
                }
                let totalPx = value.translation.width
                let stepsChanged = -Int(totalPx / tickSpacing)
                let newMinutes = max(minMinutes, min(maxMinutes, dragBaseMinutes + stepsChanged * 5))
                pixelOffset = -(totalPx.truncatingRemainder(dividingBy: tickSpacing))

                if newMinutes != valueMinutes {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    // Boundary haptic
                    if newMinutes == minMinutes || newMinutes == maxMinutes {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    }
                    valueMinutes = newMinutes
                }
            }
            .onEnded { _ in
                isDragging = false
                withAnimation(.spring(response: 0.18, dampingFraction: 0.8)) { pixelOffset = 0 }
            }
    }
}
