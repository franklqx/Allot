//
//  TaskBox.swift
//  Allot
//
//  Shared rounded-square shape used to represent a Task everywhere in the UI.
//  Rule: tasks are always squares. Tags are always circles (see TagDot).
//
//  Three Home-row variants distinguish task type by border treatment so the
//  interior stays empty for a checkmark to show through:
//    .solid   → once         (continuous border)
//    .dashed  → recurring    (dashed border)
//    .dotted  → longTerm     (dotted border)
//  .filled is for compact legend / chart use where a solid block reads better.
//

import SwiftUI

enum BoxStyle {
    case filled
    case solid
    case dashed
    case dotted
}

struct TaskBox: View {
    let color: Color
    var style: BoxStyle = .filled
    var size: CGFloat = 14
    var cornerRadius: CGFloat = 4
    var lineWidth: CGFloat = 1.5

    var body: some View {
        switch style {
        case .filled:
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(color)
                .frame(width: size, height: size)
        case .solid:
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(color, lineWidth: lineWidth)
                .frame(width: size, height: size)
        case .dashed:
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(color, style: StrokeStyle(lineWidth: lineWidth, dash: [3, 2.5]))
                .frame(width: size, height: size)
        case .dotted:
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, dash: [0.1, 2.6]))
                .frame(width: size, height: size)
        }
    }

    /// Map a TaskType to its canonical Home-row border style.
    static func style(for type: TaskType) -> BoxStyle {
        switch type {
        case .once:      return .solid
        case .recurring: return .dashed
        }
    }
}
