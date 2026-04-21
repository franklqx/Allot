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

    private let tickSpacing: CGFloat = 18  // px per 5-min step
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
                .frame(height: 72)
                .gesture(dragGesture)
                .padding(.top, 12)

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
            let cy = size.height / 2
            let currentStep = valueMinutes / 5
            let visible = Int(size.width / tickSpacing) + 6

            for i in 0..<visible {
                let step = currentStep - visible / 2 + i
                guard step >= (minMinutes / 5) && step <= (maxMinutes / 5) else { continue }

                let x = cx + CGFloat(i - visible / 2) * tickSpacing + pixelOffset
                let isHour: Bool
                switch mode {
                case .timeOfDay: isHour = (step * 5) % 60 == 0
                case .duration:  isHour = (step * 5) % 60 == 0
                }
                let h: CGFloat = isHour ? 22 : 10

                var p = Path()
                p.move(to: CGPoint(x: x, y: cy - h / 2))
                p.addLine(to: CGPoint(x: x, y: cy + h / 2))
                ctx.stroke(p, with: .color(.white.opacity(isHour ? 0.45 : 0.18)), lineWidth: 1)
            }

            // Red cursor
            var cursor = Path()
            cursor.move(to: CGPoint(x: cx, y: 4))
            cursor.addLine(to: CGPoint(x: cx, y: size.height - 4))
            ctx.stroke(cursor, with: .color(Color.accentPrimary), lineWidth: 2)

            // Bottom dot on cursor
            ctx.fill(
                Path(ellipseIn: CGRect(x: cx - 4, y: size.height - 10, width: 8, height: 8)),
                with: .color(Color.accentPrimary)
            )
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
