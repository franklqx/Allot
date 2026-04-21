//
//  SessionSource.swift
//  Allot

import Foundation

enum SessionSource: String, Codable, CaseIterable {
    case liveTimer      // started/stopped in-app
    case manualEntry    // manual time entry
    case quickLog       // slider-based quick log (no live session)
}
