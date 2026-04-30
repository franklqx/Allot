//
//  AllotWidgetBundle.swift
//  AllotWidget

import SwiftUI
import WidgetKit

@main
struct AllotWidgetBundle: WidgetBundle {
    var body: some Widget {
        LiveFocusWidget()
        TodayAllottedWidget()
        TodayCircularWidget()
        FocusInlineWidget()
        QuickStartWidget()
    }
}
