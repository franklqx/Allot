//
//  DesignTokens.swift
//  Allot
//
//  Design system color + font tokens. Single source of truth for the warm-paper aesthetic.
//  All raw values from DESIGN.md §3.

import SwiftUI

// MARK: Colors

extension Color {
    // Accent
    static let accentPrimary    = Color(hex: "#E5544A")  // coral, light mode
    static let accentDark       = Color(hex: "#FF6B5C")  // coral, dark mode

    // Backgrounds
    static let bgPrimary        = Color(hex: "#FBF7F1")
    static let bgSecondary      = Color(hex: "#F4EFE6")
    static let bgElevated       = Color(hex: "#FFFFFF")

    // Text
    static let textPrimary      = Color(hex: "#1C1814")
    static let textSecondary    = Color(hex: "#6B6359")
    static let textTertiary     = Color(hex: "#A39A8C")

    // States
    static let stateSuccess     = Color(hex: "#6F8F5C")
    static let stateWarning     = Color(hex: "#C9853D")
    static let stateDestructive = Color(hex: "#B84A3E")

    // Tag palette (light mode base colors)
    static let tagCoral         = Color(hex: "#E5544A")
    static let tagMarigold      = Color(hex: "#E08A3C")
    static let tagMustard       = Color(hex: "#C9A227")
    static let tagSage          = Color(hex: "#7A9272")
    static let tagOlive         = Color(hex: "#6F7A3D")
    static let tagTeal          = Color(hex: "#3E8079")
    static let tagPowder        = Color(hex: "#7896A8")
    static let tagPeriwinkle    = Color(hex: "#7C7BB0")
    static let tagMauve         = Color(hex: "#A574A0")
    static let tagTerracotta    = Color(hex: "#B0593F")
    static let tagRose          = Color(hex: "#C76A7A")
    static let tagStone         = Color(hex: "#9C928A")

    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let int = UInt64(h, radix: 16) ?? 0
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >>  8) & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: Tag color lookup

extension Color {
    /// Returns the base color for a tag color token (e.g. "coral" → .tagCoral).
    static func tagColor(_ token: String) -> Color {
        switch token {
        case "coral":       return .tagCoral
        case "marigold":    return .tagMarigold
        case "mustard":     return .tagMustard
        case "sage":        return .tagSage
        case "olive":       return .tagOlive
        case "teal":        return .tagTeal
        case "powder":      return .tagPowder
        case "periwinkle":  return .tagPeriwinkle
        case "mauve":       return .tagMauve
        case "terracotta":  return .tagTerracotta
        case "rose":        return .tagRose
        default:            return .tagStone  // "stone" + unknown
        }
    }

    /// Soft (background) variant — 10% opacity of base.
    static func tagColorSoft(_ token: String) -> Color {
        tagColor(token).opacity(0.12)
    }
}

// MARK: Corner radii

enum Radius {
    static let xs:  CGFloat =  6
    static let sm:  CGFloat = 10
    static let md:  CGFloat = 14
    static let lg:  CGFloat = 20
    static let xl:  CGFloat = 28
}

// MARK: Duration formatting

func formatDuration(_ seconds: Int) -> String {
    guard seconds >= 60 else { return "0m" }
    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    if h == 0 { return "\(m)m" }
    if m == 0 { return "\(h)h" }
    return "\(h)h \(m)m"
}

func formatClock(_ seconds: Int) -> String {
    let h  = seconds / 3600
    let m  = (seconds % 3600) / 60
    let s  = seconds % 60
    return String(format: "%02d:%02d:%02d", h, m, s)
}

/// Convert startTime (minutes from midnight) to display string, e.g. 420 → "07:00".
func formatStartTime(_ minutesFromMidnight: Int) -> String {
    let h = minutesFromMidnight / 60
    let m = minutesFromMidnight % 60
    return String(format: "%02d:%02d", h, m)
}
