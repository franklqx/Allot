//
//  AuthManager.swift
//  Allot
//
//  Sign in with Apple state. The user identifier is stored in Keychain (not
//  UserDefaults — UserDefaults syncs and we want this to stay device-local
//  so a device losing its iCloud account doesn't accidentally re-auth).

import AuthenticationServices
import Foundation
import Observation
import Security

@Observable
@MainActor
final class AuthManager {
    static let shared = AuthManager()

    private(set) var userIdentifier: String?
    private(set) var displayName: String?
    private(set) var email: String?
    private(set) var lastError: String?

    var isSignedIn: Bool { userIdentifier != nil }

    private let keychainService = "com.EL.fire.Allot1.auth"
    private let keychainAccount = "appleUserIdentifier"
    private let displayNameKey  = "auth.displayName"
    private let emailKey        = "auth.email"

    private init() {}

    // MARK: Public API

    func restore() async {
        guard let stored = readKeychainIdentifier() else { return }
        let provider = ASAuthorizationAppleIDProvider()
        do {
            let state = try await provider.credentialState(forUserID: stored)
            switch state {
            case .authorized:
                userIdentifier = stored
                displayName    = UserDefaults.standard.string(forKey: displayNameKey)
                email          = UserDefaults.standard.string(forKey: emailKey)
            case .revoked, .notFound, .transferred:
                signOut()
            @unknown default:
                signOut()
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func handleAuthorization(_ authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            lastError = "Unexpected credential type"
            return
        }
        let id = credential.user
        writeKeychainIdentifier(id)
        userIdentifier = id

        if let fullName = credential.fullName {
            let formatter = PersonNameComponentsFormatter()
            let name = formatter.string(from: fullName)
            if !name.isEmpty {
                displayName = name
                UserDefaults.standard.set(name, forKey: displayNameKey)
            }
        }
        if let mail = credential.email {
            email = mail
            UserDefaults.standard.set(mail, forKey: emailKey)
        }
        lastError = nil
    }

    func handleAuthorizationError(_ error: Error) {
        if let asError = error as? ASAuthorizationError, asError.code == .canceled {
            lastError = nil
            return
        }
        lastError = error.localizedDescription
    }

    func signOut() {
        deleteKeychainIdentifier()
        UserDefaults.standard.removeObject(forKey: displayNameKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
        userIdentifier = nil
        displayName    = nil
        email          = nil
    }

    // MARK: Keychain

    private func readKeychainIdentifier() -> String? {
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrService as String:      keychainService,
            kSecAttrAccount as String:      keychainAccount,
            kSecReturnData as String:       true,
            kSecMatchLimit as String:       kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func writeKeychainIdentifier(_ value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrService as String:  keychainService,
            kSecAttrAccount as String:  keychainAccount,
        ]
        let attrs: [String: Any] = [
            kSecValueData as String:    data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let updateStatus = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery.merge(attrs) { _, new in new }
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    private func deleteKeychainIdentifier() {
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrService as String:  keychainService,
            kSecAttrAccount as String:  keychainAccount,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
