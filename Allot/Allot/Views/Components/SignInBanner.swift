//
//  SignInBanner.swift
//  Allot
//
//  Top-of-screen banner shown when the user hasn't signed in. Tap navigates
//  to AccountView. Dismiss snoozes for 7 days via @AppStorage.

import SwiftUI

struct SignInBanner: View {
    @Bindable private var auth = AuthManager.shared
    @AppStorage("signInBanner.dismissedUntil") private var dismissedUntil: Double = 0

    let onTap: () -> Void

    var body: some View {
        if shouldShow {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.icloud")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("Sign in to back up your data")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                Spacer(minLength: 8)
                Button {
                    let weekFromNow = Date().addingTimeInterval(60 * 60 * 24 * 7)
                    dismissedUntil = weekFromNow.timeIntervalSince1970
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .fill(Color.tagMarigold.opacity(0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .strokeBorder(Color.tagMarigold.opacity(0.35), lineWidth: 0.5)
            )
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private var shouldShow: Bool {
        if auth.isSignedIn { return false }
        let now = Date().timeIntervalSince1970
        return now > dismissedUntil
    }
}
