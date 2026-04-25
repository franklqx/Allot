//
//  ScrollOffsetPreferenceKey.swift
//  Allot
//
//  Tracks ScrollView content offset for parallax-style header motion.

import SwiftUI

enum ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
