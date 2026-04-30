//
//  SheetChrome.swift
//  Allot
//
//  Unified sheet header — every modal in the app goes through this so the
//  grabber, title, and top-bar buttons all look identical. Modeled after the
//  DateJumpSheet (Calendar) pattern: NavigationStack + inline title + toolbar.

import SwiftUI

struct SheetAction {
    let label: String
    var role: ButtonRole? = nil
    var isDisabled: Bool = false
    let action: () -> Void
}

extension View {
    /// Wrap a sheet body in the canonical NavigationStack chrome:
    /// inline title, optional left button (Cancel/Discard/etc.) in textSecondary
    /// regular, optional right button (Done/Save) in accentPrimary semibold.
    /// Pair with `.presentationDragIndicator(.visible)` on the sheet site.
    func sheetChrome(
        title: String,
        leading: SheetAction? = nil,
        trailing: SheetAction? = nil
    ) -> some View {
        NavigationStack {
            self
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if let leading {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(leading.label, role: leading.role) {
                                leading.action()
                            }
                            .foregroundStyle(
                                leading.isDisabled
                                    ? Color.textTertiary
                                    : (leading.role == .destructive
                                        ? Color.stateDestructive
                                        : Color.textSecondary)
                            )
                            .disabled(leading.isDisabled)
                        }
                    }
                    if let trailing {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(trailing.label) { trailing.action() }
                                .foregroundStyle(
                                    trailing.isDisabled
                                        ? Color.textTertiary
                                        : Color.accentPrimary
                                )
                                .fontWeight(.semibold)
                                .disabled(trailing.isDisabled)
                        }
                    }
                }
        }
    }
}
