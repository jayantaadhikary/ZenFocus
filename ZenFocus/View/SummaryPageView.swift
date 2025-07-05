import SwiftUI
import SwiftData
import Charts

struct SummaryPageView: View {
    @Binding var selectedTab: Int
    @Query var allSessions: [FocusSession]
    
    // MARK: - Computed Properties
    var totalSeconds: Int {
        allSessions.map { $0.duration }.reduce(0, +)
    }
    
    var focusDays: [Date: Int] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: allSessions) { session in
            calendar.startOfDay(for: session.date)
        }
        return grouped.mapValues { $0.map(\.duration).reduce(0, +) }
    }
    
    var streak: Int {
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: Date())
        var streakCount = 0

        // If there's no session today, backtrack to yesterday
        if !focusDays.keys.contains(currentDate) {
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }

        while focusDays.keys.contains(currentDate) {
            streakCount += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }

        return streakCount
    }
    
    var longestStreak: Int {
        let sortedDates = focusDays.keys.sorted()
        let calendar = Calendar.current
        
        var longest = 0
        var currentStreak = 0
        var previousDate: Date?
        
        for date in sortedDates {
            if let prev = previousDate {
                let nextExpected = calendar.date(byAdding: .day, value: 1, to: prev)!
                if calendar.isDate(date, inSameDayAs: nextExpected) {
                    currentStreak += 1
                } else {
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            
            longest = max(longest, currentStreak)
            previousDate = date
        }
        
        return longest
    }
    
    var averageSessionLength: Int {
        guard !allSessions.isEmpty else { return 0 }
        return totalSeconds / allSessions.count
    }
    
    var taskDurations: [String: Int] {
        Dictionary(grouping: allSessions, by: \.taskName)
            .mapValues { $0.map(\.duration).reduce(0, +) }
    }
    
    var topTask: (name: String, duration: Int)? {
        taskDurations.max(by: { $0.value < $1.value }).map { (name: $0.key, duration: $0.value) }
    }
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        } else {
            return "\(remainingSeconds)s"
        }
    }
    
    @ViewBuilder
    func StatRow(icon: String, label: String, value: String, color: Color = .primary) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(label)
            Spacer()
            Text(value)
                .bold()
        }
        .font(.subheadline)
    }

    
    var SummaryView: some View {
        VStack(alignment: .leading, spacing: 24) {
            
            // 🔥 Focus Summary Card
            GroupBox(label: Label("Your Focus Stats", systemImage: "flame.fill")) {
                VStack(alignment: .leading, spacing: 12) {
                    StatRow(icon: "flame", label: "Current streak", value: "\(streak) days", color: .orange)
                    StatRow(icon: "medal.fill", label: "Longest streak", value: "\(longestStreak) days")
                    StatRow(icon: "clock", label: "Total focus time", value: formatDuration(totalSeconds))
                    StatRow(icon: "chart.bar", label: "Avg. session", value: formatDuration(averageSessionLength))
                }
                .padding(.top, 4)
            }
            
            // ⭐ Top Task
            if let top = topTask {
                GroupBox(label: Label("Most Focused Task", systemImage: "star.fill")) {
                    HStack {
                        Text(top.name)
                        Spacer()
                        Text(formatDuration(top.duration))
                    }
                    .font(.subheadline)
                }
            }
            
            // � Enhanced Weekly View
            GroupBox(label: Label("This Week", systemImage: "calendar.badge.clock")) {
                WeeklyCalendarView(sessions: allSessions)
            }
            
            // 📅 Recent Focus Days
            if !focusDays.isEmpty {
                GroupBox(label: Label("Recent Days", systemImage: "calendar")) {
                    ForEach(focusDays.keys.sorted(by: >).prefix(7), id: \.self) { day in
                        HStack {
                            Text(dateFormatter.string(from: day))
                            Spacer()
                            Text(formatDuration(focusDays[day] ?? 0))
                        }
                        .font(.subheadline)
                    }
                }
            }

            // 🧠 Focus by Task
            if !taskDurations.isEmpty {
                GroupBox(label: Label("Focus by Task", systemImage: "list.bullet")) {
                    ForEach(taskDurations.sorted(by: { $0.value > $1.value }), id: \.key) { task, duration in
                        HStack {
                            Text(task)
                            Spacer()
                            Text(formatDuration(duration))
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
        .padding()
    }

    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                if allSessions.isEmpty {
                    VStack {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "apple.meditate")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundStyle(.gray)
                            
                            Text("No sessions yet")
                                .font(.title2)
                                .bold()
                            
                            Text("Start your first focus session to see your stats here.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(action: {
                                selectedTab = 0
                            }) {
                                Text("Start Focusing")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height * 0.8)
                } else {
                    SummaryView
                }
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}



#Preview ("Mock View") {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    
    let mockSessions = [
        FocusSession(date: calendar.date(byAdding: .day, value: -2, to: today)!, taskName: "Study", duration: 1800),
        FocusSession(date: calendar.date(byAdding: .day, value: -1, to: today)!, taskName: "Work", duration: 2700),
        FocusSession(date: calendar.date(byAdding: .day, value: 0, to: today)!, taskName: "Read", duration: 3600),
        FocusSession(date: calendar.date(byAdding: .day, value: -3, to: today)!, taskName: "Study", duration: 900),
        FocusSession(date: calendar.date(byAdding: .day, value: -5, to: today)!, taskName: "Work", duration: 1500)
    ]
    
    let container = try! ModelContainer(for: FocusSession.self, configurations: .init(isStoredInMemoryOnly: true))
    let context = ModelContext(container)
    
    mockSessions.forEach {
        context.insert($0)
    }
    return SummaryPageView(selectedTab: .constant(1))
        .modelContainer(container)
}

#Preview("Empty View"){
    SummaryPageView(selectedTab: .constant(1))
}
