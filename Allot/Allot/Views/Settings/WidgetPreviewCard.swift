//
//  WidgetPreviewCard.swift
//  Allot
//
//  Wraps a widget content view at its real pt size with a soft "home screen"
//  backdrop, rounded corner, and shadow — so the Settings preview looks like
//  the widget actually sitting on the user's home or lock screen.

import SwiftUI

struct WidgetPreviewCard<Content: View>: View {
    let label: String        // "Home small" / "Lock rectangle" / etc.
    let width: CGFloat       // pt — real iPhone widget size
    let height: CGFloat
    let content: () -> Content

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Soft "home screen" backdrop hint — gradient suggesting
                // wallpaper without faking a specific one.
                LinearGradient(
                    colors: [Color.bgSecondary, Color.bgPrimary],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: height + 40)

                content()
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(.regularMaterial)
                    )
                    .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 4)
            }

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}
