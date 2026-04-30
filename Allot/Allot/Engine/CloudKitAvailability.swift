//
//  CloudKitAvailability.swift
//  Allot
//
//  Lightweight check for whether the device has an active iCloud account.
//  Used to decide ModelConfiguration.cloudKitDatabase + whether to show the
//  "sign in to back up" banner.

import Foundation
import Observation

@Observable
@MainActor
final class CloudKitAvailability {
    static let shared = CloudKitAvailability()

    private(set) var isAvailable: Bool

    private init() {
        self.isAvailable = FileManager.default.ubiquityIdentityToken != nil
        observeIdentityChanges()
    }

    func refresh() {
        isAvailable = FileManager.default.ubiquityIdentityToken != nil
    }

    private func observeIdentityChanges() {
        // Modern AsyncSequence form. Captures self weakly at Task creation; each
        // iteration awaits on MainActor (this type is @MainActor-isolated).
        // Task ends naturally when self deinitializes — no manual unregister.
        Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .NSUbiquityIdentityDidChange) {
                await self?.refresh()
            }
        }
    }
}
