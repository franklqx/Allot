//
//  OnboardingSignInStep.swift
//  Allot

import AuthenticationServices
import SwiftUI

struct OnboardingSignInStep: View {

    let onContinue: () -> Void

    @Bindable private var auth = AuthManager.shared

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            Image(systemName: "icloud.and.arrow.up")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Color.textPrimary)
                .padding(.bottom, 24)

            VStack(spacing: 12) {
                Text("Save your data.")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text("Sign in to back up everything to your iCloud — your data, only on your devices, never on Allot servers.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 36)
            }

            Spacer()

            VStack(spacing: 14) {
                if auth.isSignedIn {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.textPrimary)
                        Text("Signed in as \(auth.displayName ?? "iCloud user")")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.textPrimary)
                    }
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .fill(Color.bgSecondary)
                    )
                    .padding(.horizontal, 32)
                } else {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            auth.handleAuthorization(authorization)
                        case .failure(let error):
                            auth.handleAuthorizationError(error)
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .clipShape(Capsule())
                    .padding(.horizontal, 32)
                }

                Button {
                    onContinue()
                } label: {
                    Text(auth.isSignedIn ? "Start tracking" : "Maybe later")
                        .font(.system(size: 15, weight: auth.isSignedIn ? .semibold : .regular))
                        .foregroundStyle(auth.isSignedIn ? Color.bgPrimary : Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, auth.isSignedIn ? 16 : 10)
                        .background(
                            Group {
                                if auth.isSignedIn {
                                    Capsule().fill(Color.accentPrimary)
                                } else {
                                    Color.clear
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)

                if let error = auth.lastError {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.stateDestructive)
                        .padding(.horizontal, 32)
                }
            }
            .padding(.bottom, 80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
