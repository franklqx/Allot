//
//  OnboardingView.swift
//  Allot
//
//  6-step first-launch flow:
//    Welcome → Prism demo → Pick tags → Pre-populate tasks → Try timer → Sign in
//  Completion seeds Tag + Task data and flips hasCompletedOnboarding.

import SwiftData
import SwiftUI

struct OnboardingView: View {

    let onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var step: Step = .welcome
    @State private var state = OnboardingState()

    enum Step: Int, CaseIterable, Comparable {
        case welcome
        case prismDemo
        case pickTags
        case presetTasks
        case tryTimer
        case signIn

        static func < (lhs: Step, rhs: Step) -> Bool { lhs.rawValue < rhs.rawValue }

        var ctaTitle: String {
            switch self {
            case .welcome:      return "Get started"
            case .prismDemo:    return "Next"
            case .pickTags:     return "Continue"
            case .presetTasks:  return "Continue"
            case .tryTimer:     return "Almost done"
            case .signIn:       return "Start tracking"
            }
        }

        var showsBack: Bool { self != .welcome }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bgPrimary.ignoresSafeArea()

            ZStack {
                ForEach(Step.allCases, id: \.rawValue) { s in
                    if s == step {
                        currentStepView
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal:   .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                }
            }
            .animation(.easeInOut(duration: 0.28), value: step)
            .padding(.bottom, 130)

            VStack(spacing: 22) {
                progressDots
                actionRow
            }
            .padding(.bottom, 48)
        }
        .overlay(alignment: .topLeading) {
            if step.showsBack {
                Button {
                    advance(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                        .frame(width: 40, height: 40)
                }
                .padding(.top, 12)
                .padding(.leading, 8)
            }
        }
    }

    // MARK: - Step views

    @ViewBuilder
    private var currentStepView: some View {
        switch step {
        case .welcome:      welcomeView
        case .prismDemo:    OnboardingPrismDemoStep(state: state, onNext: { advance(by: 1) })
        case .pickTags:     OnboardingTagsStep(state: state)
        case .presetTasks:  OnboardingTasksStep(state: state)
        case .tryTimer:     OnboardingTimerStep()
        case .signIn:       OnboardingSignInStep(onContinue: { complete() })
        }
    }

    private var welcomeView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "clock.badge.checkmark.fill")
                .font(.system(size: 88, weight: .light))
                .foregroundStyle(Color.textPrimary)
            VStack(spacing: 14) {
                Text("Where did your time go?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Allot helps you see — without judgment.")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 36)
            }
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Progress + actions

    private var progressDots: some View {
        HStack(spacing: 7) {
            ForEach(Step.allCases, id: \.rawValue) { s in
                Capsule()
                    .fill(s == step ? Color.accentPrimary : Color.textTertiary.opacity(0.3))
                    .frame(width: s == step ? 22 : 7, height: 7)
                    .animation(.easeInOut(duration: 0.2), value: step)
            }
        }
    }

    @ViewBuilder
    private var actionRow: some View {
        // The SignIn step has its own primary buttons, so omit the global CTA there.
        if step == .signIn {
            EmptyView()
        } else {
            Button {
                primaryAction()
            } label: {
                Text(step.ctaTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(primaryEnabled ? Color.bgPrimary : Color.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule().fill(
                            primaryEnabled ? Color.accentPrimary : Color.bgSecondary
                        )
                    )
                    .padding(.horizontal, 32)
            }
            .buttonStyle(.plain)
            .disabled(!primaryEnabled)
        }
    }

    private var primaryEnabled: Bool {
        switch step {
        case .prismDemo:    return state.didExplorePrism
        case .pickTags:     return !state.tags.filter(\.enabled).isEmpty
        default:            return true
        }
    }

    private func primaryAction() {
        if step == .tryTimer {
            // Last informational step before SignIn (which has its own CTAs).
            advance(by: 1)
        } else {
            advance(by: 1)
        }
    }

    private func advance(by delta: Int) {
        let nextRaw = step.rawValue + delta
        guard let next = Step(rawValue: nextRaw) else { return }
        withAnimation(.easeInOut(duration: 0.28)) { step = next }
    }

    // MARK: - Completion

    private func complete() {
        // Seed selected preset tags + custom tags.
        let presetSelected = state.enabledPresetTags
        Seed.installPresetTags(selected: presetSelected, in: modelContext)
        for custom in state.enabledCustomTags {
            modelContext.insert(Tag(
                name: custom.name,
                colorToken: custom.colorToken,
                emoji: custom.emoji
            ))
        }
        try? modelContext.save()

        // Seed selected tasks under each enabled tag.
        let scoped = state.selectedTasksByTag.filter { entry in
            state.enabledPresetTags.contains { $0.name == entry.key }
        }
        Seed.installPresetTasks(selectedByTag: scoped, in: modelContext)

        onComplete()
    }
}
