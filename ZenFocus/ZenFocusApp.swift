//
//  ZenFocusApp.swift
//  ZenFocus
//
//  Created by Jayanta Adhikary on 11/06/25.
//

import SwiftUI
import SwiftData

@main
struct ZenFocusApp: App {
        var body: some Scene {
            WindowGroup {
                ContentView()
            }
            .modelContainer(for: [FocusSession.self])
        }
    }

