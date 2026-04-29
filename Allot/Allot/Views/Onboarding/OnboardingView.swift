//
//  OnboardingView.swift
//  Allot
//
//  4-step first-launch flow. Shown once; completion sets hasCompletedOnboarding = true.

import SwiftUI

struct OnboardingView: View {

    let onComplete: () -> Void

    @State private var page = 0

    private struct PageData {
        let icon: String
        let iconColor: Color
        let title: String
        let subtitle: String
    }

    private let pages: [PageData] = [
        .init(icon: "clock.badge.checkmark.fill",
              iconColor: Color.accentPrimary,
              title: "Welcome to Allot",
              subtitle: "Your personal time tracker. Simple, focused, and beautifully designed."),
        .init(icon: "checklist",
              iconColor: Color.tagTeal,
              title: "Plan Your Day",
              subtitle: "Add one-time or recurring tasks. Tag them, schedule them, and see everything at a glance."),
        .init(icon: "timer",
              iconColor: Color.tagMustard,
              title: "Track in Real Time",
              subtitle: "Long-press any task to start a timer instantly. Focus mode keeps your screen on while you work."),
        .init(icon: "chart.pie.fill",
              iconColor: Color.tagSage,
              title: "See Where It Goes",
              subtitle: "The Allotted tab breaks down your time by tag — day, week, month, or year."),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bgPrimary.ignoresSafeArea()

            // Slide pages
            ZStack {
                ForEach(Array(pages.enumerated()), id: \.offset) { i, p in
                    if i == page {
                        pageContent(p)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal:   .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: page)

            // Dots + button
            VStack(spacing: 28) {
                HStack(spacing: 7) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Color.accentPrimary : Color.textTertiary.opacity(0.35))
                            .frame(width: i == page ? 22 : 7, height: 7)
                            .animation(.easeInOut(duration: 0.2), value: page)
                    }
                }

                Button {
                    if page < pages.count - 1 {
                        withAnimation(.easeInOut(duration: 0.3)) { page += 1 }
                    } else {
                        onComplete()
                    }
                } label: {
                    Text(page == pages.count - 1 ? "Get Started" : "Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.bgPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentPrimary, in: Capsule())
                        .padding(.horizontal, 32)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 56)
        }
    }

    private func pageContent(_ p: PageData) -> some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: p.icon)
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(p.iconColor)
                .padding(.bottom, 4)
            VStack(spacing: 12) {
                Text(p.title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)
                Text(p.subtitle)
                    .font(.system(size: 17))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 44)
            }
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
