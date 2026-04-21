//
//  GrabberView.swift
//  Allot

import SwiftUI

struct GrabberView: View {
    var body: some View {
        HStack {
            Spacer()
            RoundedRectangle(cornerRadius: 99)
                .fill(Color.textTertiary.opacity(0.4))
                .frame(width: 36, height: 4)
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
