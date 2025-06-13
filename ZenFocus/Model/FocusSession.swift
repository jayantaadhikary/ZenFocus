//
//  FocusSession.swift
//  ZenFocus
//
//  Created by Jayanta Adhikary on 13/06/25.
//


import Foundation
import SwiftData

@Model
class FocusSession {
    var id: UUID
    var date: Date
    var taskName: String
    var duration: Int // in seconds
    
    init(date: Date = .now, taskName: String, duration: Int) {
        self.id = UUID()
        self.date = date
        self.taskName = taskName
        self.duration = duration
    }
}
