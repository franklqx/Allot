//
//  TimerFABButton.swift
//  Allot
//
//  The floating action button that opens the Timer panel.
//  Plus icon when viewing today; "Today" label when viewing another date.

import SwiftUI

struct TimerFABButton: View {
    let isRunning: Bool
    var isViewingToday: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.accentPrimary)
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.accentPrimary.opacity(0.35), radius: 12, x: 0, y: 4)

                if isRunning {
                    // Pulse ring while timer is active
                    Circle()
                        .stroke(Color.accentPrimary.opacity(0.4), lineWidth: 2)
                        .frame(width: 64, height: 64)
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: isRunning)
                }

                if isViewingToday {
                    Image(systemName: isRunning ? "timer" : "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                } else {
                    Text("Today")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRunning ? "Timer running — tap to open" : "Start timer")
    }
}

#Preview {
    VStack(spacing: 20) {
        TimerFABButton(isRunning: false, action: {})
        TimerFABButton(isRunning: true, action: {})
        TimerFABButton(isRunning: false, isViewingToday: false, action: {})
    }
    .padding()
    .background(Color.bgPrimary)
}
