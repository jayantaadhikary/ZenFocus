//
//  UserSettings.swift
//  ZenFocus
//
//  Created by Jayanta Adhikary on 15/06/25.
//


import Foundation
import SwiftData

enum AppTheme: String, Codable, CaseIterable {
    case system, light, dark
}



@Model
final class UserSettings {
    var defaultFocusDuration: Int
    var dailyTargetSessions: Int
    var theme: AppTheme

    init(defaultFocusDuration: Int = 1500, dailyTargetSessions: Int = 3, theme: AppTheme = .system) {
        self.defaultFocusDuration = defaultFocusDuration
        self.dailyTargetSessions = dailyTargetSessions
        self.theme = theme
    }
}

