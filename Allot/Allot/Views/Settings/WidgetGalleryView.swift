//
//  WidgetGalleryView.swift
//  Allot
//
//  Settings → Widgets entry point. Lists the 5 widgets with a one-line summary
//  of the user's current settings; tapping a card pushes into the per-widget
//  customization view.
//
//  Pro feature: customization options below are intended to be paywalled in v2
//  when StoreKit integration ships. For v1.1, all options remain freely accessible.

import SwiftUI
import WidgetKit

enum WidgetKind: String, CaseIterable, Identifiable {
    case liveFocus
    case todayAllotted
    case todayCircular
    case focusInline
    case quickStart

    var id: String { rawValue }

    var title: String {
        switch self {
        case .liveFocus:     return "Live Focus"
        case .todayAllotted: return "Today"
        case .todayCircular: return "Today (Circular)"
        case .focusInline:   return "Focus Inline"
        case .quickStart:    return "Quick Start"
        }
    }

    var subtitle: String {
        switch self {
        case .liveFocus:     return "Lock screen + Home small"
        case .todayAllotted: return "Home medium · Prism chart"
        case .todayCircular: return "Lock screen circular"
        case .focusInline:   return "Lock screen inline"
        case .quickStart:    return "Home small · 4 task cells"
        }
    }

    var symbol: String {
        switch self {
        case .liveFocus:     return "timer"
        case .todayAllotted: return "rectangle.split.3x1"
        case .todayCircular: return "circle.dotted"
        case .focusInline:   return "text.alignleft"
        case .quickStart:    return "square.grid.2x2"
        }
    }
}

struct WidgetGalleryView: View {
    @State private var prefs: WidgetPreferences = WidgetPreferences.load()

    /// Real snapshot if available, else placeholder. Same logic as
    /// WidgetCustomizationView so thumbnails match the customization preview.
    private var thumbSnapshot: WidgetSnapshot {
        let s = WidgetSnapshot.load()
        return s.updatedAt == .distantPast ? .placeholder : s
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(WidgetKind.allCases) { kind in
                    NavigationLink {
                        WidgetCustomizationView(kind: kind, prefs: $prefs)
                    } label: {
                        card(for: kind)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.bgPrimary)
        .navigationTitle("Widgets")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Pull from disk in case another tab edited prefs while away.
            prefs = WidgetPreferences.load()
        }
    }

    // MARK: Card

    private func card(for kind: WidgetKind) -> some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: kind.symbol)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                    Text(kind.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                }
                Text(kind.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
                Text(summary(for: kind))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
                    .lineLimit(1)
                    .padding(.top, 2)
            }
            Spacer(minLength: 8)
            thumbnail(for: kind)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(14)
        .background(Color.bgSecondary, in: RoundedRectangle(cornerRadius: Radius.md))
    }

    // MARK: Thumbnail (live mini render of widget)

    @ViewBuilder
    private func thumbnail(for kind: WidgetKind) -> some View {
        // Render at full pt size, scale down. ~80pt wide cap so the row stays
        // tight. Different aspect ratios per family.
        let snapshot = thumbSnapshot

        Group {
            switch kind {
            case .liveFocus:
                miniWrap(width: 80, height: 80, scale: 80.0 / 170.0) {
                    LiveFocusContent(snapshot: snapshot, prefs: prefs, family: .systemSmall)
                        .frame(width: 170, height: 170)
                }
            case .todayAllotted:
                miniWrap(width: 100, height: 50, scale: 100.0 / 338.0) {
                    TodayAllottedContent(snapshot: snapshot, prefs: prefs)
                        .frame(width: 338, height: 158)
                }
            case .todayCircular:
                miniWrap(width: 50, height: 50, scale: 50.0 / 72.0) {
                    TodayCircularContent(snapshot: snapshot, prefs: prefs)
                        .frame(width: 72, height: 72)
                }
            case .focusInline:
                miniWrap(width: 100, height: 30, scale: 100.0 / 280.0) {
                    FocusInlineContent(snapshot: snapshot, prefs: prefs)
                        .frame(width: 280, height: 28)
                }
            case .quickStart:
                miniWrap(width: 80, height: 80, scale: 80.0 / 170.0) {
                    QuickStartContent(snapshot: snapshot, prefs: prefs, interactive: false)
                        .frame(width: 170, height: 170)
                }
            }
        }
    }

    /// Scale a full-size widget render down to thumbnail size. We render at
    /// real pt then `.scaleEffect` so layout stays correct (widgets don't
    /// re-flow well at arbitrary smaller frames).
    private func miniWrap<Content: View>(
        width: CGFloat,
        height: CGFloat,
        scale: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: width, height: height, alignment: .topLeading)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.textTertiary.opacity(0.15), lineWidth: 0.5)
            )
    }

    // MARK: Summary text (kept short, single line)

    private func summary(for kind: WidgetKind) -> String {
        switch kind {
        case .liveFocus:
            return prefs.liveFocus.hideWhenIdle ? "Hide when idle" : "Always visible"
        case .todayAllotted:
            return "\(prefs.todayAllotted.range.displayName) · \(prefs.todayAllotted.view.displayName)"
        case .todayCircular:
            return prefs.todayCircular.center.displayName
        case .focusInline:
            return prefs.focusInline.format.displayName
        case .quickStart:
            switch prefs.quickStart.source {
            case .autoRecent: return "Most recent 4"
            case .pinned:     return "Pinned · \(prefs.quickStart.pinnedTaskIds.count)"
            }
        }
    }
}
