//
//  WeeklyCalendarView.swift
//  ZenFocus
//
//  Created by Jayanta Adhikary on 04/07/25.
//

import SwiftUI
import SwiftData

struct WeeklyCalendarView: View {
    let sessions: [FocusSession]
    
    private var focusDays: [Date: Int] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.date)
        }
        return grouped.mapValues { $0.map(\.duration).reduce(0, +) }
    }
    
    private var weekDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "0m"
        }
    }
    
    private func dayAbbreviation(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    private func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private func sessionCount(for date: Date) -> Int {
        let calendar = Calendar.current
        return sessions.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
    }
    
    private func focusIntensity(for date: Date) -> Double {
        let duration = focusDays[date] ?? 0
        let maxDuration = focusDays.values.max() ?? 1
        return maxDuration > 0 ? Double(duration) / Double(maxDuration) : 0
    }
    
    private var maxWeekDuration: Int {
        weekDays.compactMap { focusDays[$0] }.max() ?? 1
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Week header
            HStack {
                Text("This Week")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text(weekTotal)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Calendar grid
            HStack(spacing: 8) {
                ForEach(weekDays, id: \.self) { date in
                    DayView(
                        date: date,
                        isToday: isToday(date),
                        sessionCount: sessionCount(for: date),
                        duration: focusDays[date] ?? 0,
                        maxDuration: maxWeekDuration
                    )
                }
            }
            
            // Week summary stats
            HStack(spacing: 20) {
                WeekStat(
                    icon: "calendar",
                    label: "Days",
                    value: "\(activeDaysCount)/7"
                )
                
                WeekStat(
                    icon: "target",
                    label: "Sessions",
                    value: "\(weekSessionsCount)"
                )
                
                WeekStat(
                    icon: "clock",
                    label: "Avg/Day",
                    value: formatDuration(averageDailyDuration)
                )
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper computed properties
    private var weekTotal: String {
        let totalSeconds = weekDays.compactMap { focusDays[$0] }.reduce(0, +)
        return formatDuration(totalSeconds)
    }
    
    private var activeDaysCount: Int {
        weekDays.filter { focusDays[$0] != nil && focusDays[$0]! > 0 }.count
    }
    
    private var weekSessionsCount: Int {
        weekDays.map { sessionCount(for: $0) }.reduce(0, +)
    }
    
    private var averageDailyDuration: Int {
        let totalSeconds = weekDays.compactMap { focusDays[$0] }.reduce(0, +)
        return activeDaysCount > 0 ? totalSeconds / activeDaysCount : 0
    }
}

// MARK: - Day View Component
struct DayView: View {
    let date: Date
    let isToday: Bool
    let sessionCount: Int
    let duration: Int
    let maxDuration: Int
    
    private func dayAbbreviation(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    private func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var barHeight: CGFloat {
        guard maxDuration > 0, duration > 0 else { return 4 }
        let ratio = Double(duration) / Double(maxDuration)
        return max(4, CGFloat(ratio * 40)) // Min 4px, max 40px
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Day abbreviation
            Text(dayAbbreviation(date))
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            // Session count (if any)
            if sessionCount > 0 {
                Text("\(sessionCount)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentColor)
                    .frame(height: 12)
            } else {
                Spacer()
                    .frame(height: 12)
            }
            
            // Bar chart container
            VStack {
                Spacer()
                
                // Mini bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(duration > 0 ? Color.accentColor : Color.secondary.opacity(0.2))
                    .frame(width: 16, height: barHeight)
                    .animation(.easeInOut(duration: 0.6), value: barHeight)
                
                // Base line
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 20, height: 1)
            }
            .frame(height: 44) // Fixed container height
            
            // Day number
            Text(dayNumber(date))
                .font(.caption2)
                .fontWeight(isToday ? .bold : .medium)
                .foregroundStyle(isToday ? .primary : .secondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isToday ? Color.accentColor.opacity(0.2) : Color.clear)
                        .stroke(isToday ? Color.accentColor : Color.clear, lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Week Stat Component
struct WeekStat: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    
    let mockSessions = [
        FocusSession(date: calendar.date(byAdding: .day, value: -2, to: today)!, taskName: "Study", duration: 1800),
        FocusSession(date: calendar.date(byAdding: .day, value: -1, to: today)!, taskName: "Work", duration: 2700),
        FocusSession(date: today, taskName: "Read", duration: 3600),
        FocusSession(date: calendar.date(byAdding: .day, value: -3, to: today)!, taskName: "Study", duration: 900),
    ]
    
    return WeeklyCalendarView(sessions: mockSessions)
        .padding()
}
