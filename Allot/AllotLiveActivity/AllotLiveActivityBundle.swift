//
//  AllotLiveActivityBundle.swift
//  AllotLiveActivity
//
//  Widget bundle entry point. Registers the focus session Live Activity.

import SwiftUI
import WidgetKit

@main
struct AllotLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        FocusActivityWidget()
    }
}
