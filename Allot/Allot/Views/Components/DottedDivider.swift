//
//  DottedDivider.swift
//  Allot
//

import SwiftUI

struct DottedDivider: View {
    var color: Color = Color.textPrimary.opacity(0.18)
    var horizontalPadding: CGFloat = 16

    var body: some View {
        GeometryReader { geo in
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0.5))
                p.addLine(to: CGPoint(x: geo.size.width, y: 0.5))
            }
            .stroke(style: StrokeStyle(lineWidth: 1, lineCap: .round,
                                       dash: [1.5, 4]))
            .foregroundStyle(color)
        }
        .frame(height: 1)
        .padding(.horizontal, horizontalPadding)
    }
}
