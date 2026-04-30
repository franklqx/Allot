//
//  OnboardingTimerStep.swift
//  Allot

import SwiftUI

struct OnboardingTimerStep: View {

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer().frame(height: 8)

            VStack(spacing: 8) {
                Text("Tap Focus to start.")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text("Long-press any task on Home to start instantly.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 40)

            VStack(spacing: 4) {
                Text("00:00")
                    .font(.system(size: 88, weight: .light, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)
                    .scaleEffect(pulse ? 1.012 : 1.0)
                Text("Stopwatch")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.top, 16)

            Spacer()

            VStack(spacing: 18) {
                Image(systemName: "timer")
                    .font(.system(size: 36, weight: .regular))
                    .foregroundStyle(Color.textPrimary)
                    .opacity(pulse ? 1.0 : 0.45)
                    .scaleEffect(pulse ? 1.18 : 1.0)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
                Text("Focus tab — middle of the bar")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.bottom, 80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { pulse = true }
    }
}
