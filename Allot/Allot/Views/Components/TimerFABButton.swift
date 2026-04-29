//
//  TimerFABButton.swift
//  Allot
//
//  iOS 26 Liquid Glass circle button that sits on the same baseline as
//  the TabView pill — the right-hand sibling of the tab bar.

import SwiftUI

struct TimerFABButton: View {
    let isRunning: Bool
    var isViewingToday: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Group {
                    if isViewingToday {
                        Image(systemName: isRunning ? "timer" : "plus")
                            .font(.system(size: 20, weight: .semibold))
                    } else {
                        Text("Today")
                            .font(.system(size: 13, weight: .semibold))
                    }
                }
                .foregroundStyle(Color.textPrimary)
            }
            .frame(width: 50, height: 50)
            .modifier(TimerFABSurfaceModifier())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRunning ? "Timer running — tap to open" : "Add task")
    }
}

private struct TimerFABSurfaceModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.interactive(), in: .circle)
        } else {
            content
                .background(Color.bgElevated, in: Circle())
                .overlay {
                    Circle()
                        .stroke(Color.textPrimary.opacity(0.08), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        }
    }
}

#Preview {
    ZStack(alignment: .bottomTrailing) {
        Color.bgSecondary.ignoresSafeArea()
        VStack(spacing: 20) {
            TimerFABButton(isRunning: false, action: {})
            TimerFABButton(isRunning: true, action: {})
            TimerFABButton(isRunning: false, isViewingToday: false, action: {})
        }
        .padding()
    }
}
