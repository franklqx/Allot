//
//  DesignTokens.swift
//  Allot
//
//  Design system v0.2 — Apple-native minimal (inspired by Robinhood 2024 + Origin).
//  Single source of truth for colors, fonts, radii. See DESIGN.md §2.

import SwiftUI

// MARK: Colors

extension Color {
    // ── Neutrals: system-adaptive ────────────────────────
    // bgPrimary   : Light #FFFFFF / Dark #000000
    // bgSecondary : grouped grays
    // bgElevated  : sheet / card surface
    static let bgPrimary   = Color(UIColor.systemBackground)
    static let bgSecondary = Color(UIColor.secondarySystemBackground)
    static let bgElevated  = Color(UIColor.systemBackground)
    static let bgGrouped   = Color(UIColor.systemGroupedBackground)

    // ── Text: alpha-based system labels ──────────────────
    static let textPrimary   = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)
    static let textTertiary  = Color(UIColor.tertiaryLabel)
    static let textQuaternary = Color(UIColor.quaternaryLabel)

    // ── "Accent" is just system chrome (black on light, white on dark) ──
    // No global accent color. These aliases remain so old call-sites compile.
    static let accentPrimary = Color(UIColor.label)
    static let accentDark    = Color(UIColor.label)

    // ── States ───────────────────────────────────────────
    // Red lives ONLY on Destructive buttons. Don't use anywhere else.
    static let stateDestructive = Color(UIColor.systemRed)
    static let stateSuccess     = Color(UIColor.label)   // neutral chrome
    static let stateWarning     = Color(UIColor.label)   // neutral chrome

    // ── Data palette (12 colors, DESIGN.md §2.3) ─────────
    // Preset tag mapping:
    //   Work     → Sky
    //   Health   → Lime
    //   Learn    → Lilac
    //   Life     → Marigold
    //   Hobby    → Rose
    //   Leisure  → Teal
    //   Untagged → Gray
    static let tagSky      = Color(hex: "#5BB2E8")
    static let tagAmber    = Color(hex: "#F89C58")
    static let tagRose     = Color(hex: "#EFB0C0")
    static let tagLilac    = Color(hex: "#B084F5")
    static let tagLime     = Color(hex: "#A8C66C")
    static let tagMarigold = Color(hex: "#F5B950")
    static let tagTeal     = Color(hex: "#7DB6B0")
    static let tagCoral    = Color(hex: "#E3472C")
    static let tagPlum     = Color(hex: "#5F2C82")
    static let tagMustard  = Color(hex: "#D9B64A")
    static let tagSage     = Color(hex: "#8FB089")
    static let tagGray     = Color(hex: "#8A8F96")

    // ── Legacy aliases (v0.1 → v0.2) so existing tag data doesn't break ──
    static let tagOlive       = tagSage
    static let tagPowder      = tagSky
    static let tagPeriwinkle  = tagLilac
    static let tagMauve       = tagLilac
    static let tagTerracotta  = tagCoral
    static let tagStone       = tagGray

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
    /// Returns the base color for a tag color token (e.g. "sky" → .tagSky).
    /// Backward-compatible with v0.1 tokens.
    static func tagColor(_ token: String) -> Color {
        switch token {
        // v0.2 tokens
        case "sky":         return .tagSky
        case "amber":       return .tagAmber
        case "rose":        return .tagRose
        case "lilac":       return .tagLilac
        case "lime":        return .tagLime
        case "marigold":    return .tagMarigold
        case "teal":        return .tagTeal
        case "coral":       return .tagCoral
        case "plum":        return .tagPlum
        case "mustard":     return .tagMustard
        case "sage":        return .tagSage
        case "gray":        return .tagGray
        // v0.1 legacy tokens
        case "powder":      return .tagSky
        case "periwinkle":  return .tagLilac
        case "mauve":       return .tagLilac
        case "olive":       return .tagSage
        case "terracotta":  return .tagCoral
        case "stone":       return .tagGray
        default:            return .tagGray
        }
    }

    /// Soft (background) variant — 12% opacity of base.
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
    guard seconds > 0 else { return "0s" }
    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    let s = seconds % 60
    var parts: [String] = []
    if h > 0 { parts.append("\(h)h") }
    if m > 0 { parts.append("\(m)m") }
    if s > 0 { parts.append("\(s)s") }
    return parts.joined(separator: " ")
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
