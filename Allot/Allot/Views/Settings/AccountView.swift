//
//  AccountView.swift
//  Allot

import AuthenticationServices
import SwiftUI

struct AccountView: View {
    @Bindable private var auth = AuthManager.shared
    @Bindable private var cloud = CloudKitAvailability.shared
    @State private var showSignOutConfirm = false

    var body: some View {
        List {
            Section {
                if auth.isSignedIn {
                    signedInRow
                    syncStatusRow
                } else {
                    signedOutRow
                }
            }

            if auth.isSignedIn {
                Section {
                    Button(role: .destructive) {
                        showSignOutConfirm = true
                    } label: {
                        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } footer: {
                    Text("Signing out keeps your data on this device. iCloud sync will pause until you sign in again.")
                }
            } else {
                Section {
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
                    .frame(height: 48)
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                } footer: {
                    Text("Your Apple ID identifies your data. Allot stores nothing on its servers — your sessions live in your private iCloud database.")
                }
            }

            if let error = auth.lastError {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(Color.stateDestructive)
                        .font(.system(size: 13))
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Sign out of Allot?",
            isPresented: $showSignOutConfirm,
            titleVisibility: .visible
        ) {
            Button("Sign out", role: .destructive) { auth.signOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your tracked data stays on this device. iCloud backup will pause.")
        }
    }

    // MARK: Rows

    private var signedInRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color.textPrimary)
            VStack(alignment: .leading, spacing: 2) {
                Text(auth.displayName ?? "Signed in")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                if let email = auth.email {
                    Text(email)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                } else {
                    Text("Apple ID linked")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var syncStatusRow: some View {
        HStack(spacing: 10) {
            Image(systemName: cloud.isAvailable ? "checkmark.icloud" : "icloud.slash")
                .foregroundStyle(cloud.isAvailable ? Color.textPrimary : Color.stateDestructive)
            VStack(alignment: .leading, spacing: 2) {
                Text(cloud.isAvailable ? "iCloud · Synced" : "iCloud unavailable")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                Text(cloud.isAvailable
                     ? "Your data backs up automatically."
                     : "Open Settings → iCloud to enable.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
        }
    }

    private var signedOutRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Back up your data", systemImage: "exclamationmark.icloud")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            Text("Without an account, deleting Allot will erase your history. Sign in below to keep everything safe.")
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.vertical, 4)
    }
}
