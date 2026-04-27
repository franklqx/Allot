//
//  TagDot.swift
//  Allot
//
//  Shared circular shape used to represent a Tag everywhere in the UI.
//  Rule: tags are always circles. Tasks are always squares (see TaskBox).
//

import SwiftUI

enum DotStyle {
    case filled         // solid disc
    case solid          // empty circle, solid stroke
    case dashed         // empty circle, dashed stroke
    case dotted         // empty circle, tight dotted stroke
}

struct TagDot: View {
    let color: Color
    var style: DotStyle = .filled
    var size: CGFloat = 10
    var lineWidth: CGFloat = 1.5

    var body: some View {
        switch style {
        case .filled:
            Circle()
                .fill(color)
                .frame(width: size, height: size)
        case .solid:
            Circle()
                .strokeBorder(color, lineWidth: lineWidth)
                .frame(width: size, height: size)
        case .dashed:
            Circle()
                .strokeBorder(color, style: StrokeStyle(lineWidth: lineWidth, dash: [3, 2.5]))
                .frame(width: size, height: size)
        case .dotted:
            Circle()
                .strokeBorder(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, dash: [0.1, 2.6]))
                .frame(width: size, height: size)
        }
    }
}
