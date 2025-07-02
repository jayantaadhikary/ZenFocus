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
    var pauseCount: Int // number of times session was paused
    var totalPausedTime: Int // total time spent in pause state (seconds)
    var completionDate: Date // exact time when session completed
    
    init(
        date: Date = .now, 
        taskName: String, 
        duration: Int,
        pauseCount: Int = 0,
        totalPausedTime: Int = 0,
        completionDate: Date = .now
    ) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.taskName = taskName
        self.duration = duration
        self.pauseCount = pauseCount
        self.totalPausedTime = totalPausedTime
        self.completionDate = completionDate
    }

}
