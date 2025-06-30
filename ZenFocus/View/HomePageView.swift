//
//  HomePageView.swift
//  ZenFocus
//
//  Created by Jayanta Adhikary on 11/06/25.
//

import SwiftUI
import AVFoundation
import SwiftData

struct HomePageView: View {
    

    
    @Environment(\.modelContext) private var modelContext
    @Query var allSessions: [FocusSession]
    @Query var userSettings: [UserSettings]
    @Query var focusTasks: [FocusTask]
    
    
    @StateObject private var audioManager = AmbientAudioManager.shared
    
    var sessionDays: [Date] {
        let calendar = Calendar.current
        let uniqueDays = Set(allSessions.map { calendar.startOfDay(for: $0.date) })
        return Array(uniqueDays).sorted(by: >)
    }
    
    var streak: Int {
        let calendar = Calendar.current
        var streakCount = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        let sessionDaysSet = Set(sessionDays)
        
        while sessionDaysSet.contains(currentDate) {
            streakCount += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        return streakCount
    }
    
    
    @State private var showAmbientPicker = false
    @State private var selectedAmbient: AmbientOption = ambientOptions[0]
    
    @State private var totalTime: Int = 0
    @State private var timeRemaining: Int = 0
    @State private var hasInitializedTime = false
    
    @State private var isPlaying: Bool = false
    @State private var isPaused: Bool = false
    
    @State private var hasCompletedSession = false
    @State private var showAmbientPickerWarning = false
    @State private var showTaskWarning = false
    @State private var showCompletionSheet = false
    @State private var completedTaskName = ""
    @State private var completedDuration = 0
    
    @State private var selectedTask: FocusTask?
    
    var focusSessionsToday: Int {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return allSessions.filter { $0.date >= startOfToday }.count
    }
    
    private func resetTime() {
        timeRemaining = totalTime
        isPlaying = false
        isPaused = false
        hasCompletedSession = false
        audioManager.stop()
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    private func updateTimer() {
        // Handle countdown logic
        if isPlaying && !isPaused && timeRemaining > 0 {
            timeRemaining -= 1
        }
        
        // Check for session completion
        checkSessionCompletion()
    }
    
    private func checkSessionCompletion() {
        // Only proceed if timer has reached zero and session is active
        if timeRemaining != 0 || !isPlaying || hasCompletedSession {
            return
        }
        
        // Mark session as complete
        hasCompletedSession = true
        isPlaying = false
        
        // Stop audio and play alert
        audioManager.stop()
        AudioServicesPlayAlertSound(1106)
        
        // Only save session if a task was selected
        if let task = selectedTask {
            saveCompletedSession(task: task)
        }
    }
    
    private func saveCompletedSession(task: FocusTask) {
        // Create and save the session
        let session = FocusSession(taskName: task.name, duration: totalTime)
        modelContext.insert(session)
        try? modelContext.save()
        
        // Prepare completion sheet data
        completedTaskName = task.name
        completedDuration = totalTime
        showCompletionSheet = true
    }
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                Text("Focus • \(focusSessionsToday) of \(userSettings.first?.dailyTargetSessions ?? 4)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .animation(.easeInOut(duration: 0.3), value: focusSessionsToday)
                
                Spacer()
                
                if totalTime > 0 {
                    TimerView(timeRemaining: timeRemaining, totalTime: totalTime)
                        .scaleEffect(isPlaying && !isPaused ? 1.02 : 1.0)
                        .animation(isPlaying && !isPaused ? 
                                  .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : 
                                  .easeOut(duration: 0.3), 
                                  value: isPlaying)
                        .id(isPlaying ? "playing-\(UUID().uuidString)" : "stopped")  // Now both are strings
                        //MARK:- Remove the triple tap gesture for test mode
                        .onTapGesture(count: 3) {  // Triple tap to set 10-second test timer
                            totalTime = 10
                            timeRemaining = 10
                        }
                }
                
                Spacer()
                
                Text("🎯 \(focusSessionsToday) focus session\(focusSessionsToday <= 1 ? "" : "s") completed today")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .animation(.bouncy(duration: 0.6), value: focusSessionsToday)
                
                Spacer()
                
                HStack {
                    Button {
                        if selectedTask == nil {
                            showTaskWarning = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showTaskWarning = false
                            }
                            return
                        }
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if !isPlaying {
                                isPlaying = true
                                isPaused = false
                                hasCompletedSession = false
                                UIApplication.shared.isIdleTimerDisabled = true
                                if let sound = selectedAmbient.audioFileName {
                                    audioManager.playSound(named: sound)
                                }
                            } else {
                                isPaused.toggle()
                                isPaused ? audioManager.pause() : audioManager.resume()
                                if isPaused {
                                    UIApplication.shared.isIdleTimerDisabled = false
                                } else {
                                    UIApplication.shared.isIdleTimerDisabled = true
                                }
                            }
                        }
                    } label: {
                        Image(systemName: !isPlaying || isPaused ? "play" : "pause")
                            .font(.title2)
                            .symbolEffect(.bounce, value: isPlaying)
                        Text(!isPlaying || isPaused ? "Start" : "Pause")
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal)
                    .scaleEffect(selectedTask == nil ? 0.95 : 1.0)
                    .opacity(selectedTask == nil ? 0.6 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: selectedTask)
                    
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            resetTime()
                        }
                    } label: {
                        Image(systemName: "arrow.trianglehead.clockwise.rotate.90")
                            .font(.title2)
                        Text("Reset")
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal)
                }
                
                Spacer()

                VStack {
                    Text("What are you focusing on?")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(focusTasks) { item in
                                Button {
                                    if !isPlaying {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            selectedTask = selectedTask == item ? nil : item
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: item.icon)
                                            .symbolEffect(.pulse, value: selectedTask == item)
                                        Text(item.name)
                                    }
                                    .padding(.horizontal, 8)
                                }
                                .padding(6)
                                .buttonStyle(.bordered)
                                .foregroundStyle(
                                    selectedTask == item ? .teal :
                                    isPlaying ? .gray.opacity(0.6) : .secondary
                                )
                                .disabled(isPlaying)
                                .scaleEffect(selectedTask == item ? 1.05 : 1.0)
                                .shadow(color: selectedTask == item ? .teal.opacity(0.3) : .clear, radius: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTask)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .opacity(isPlaying ? 0.6 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isPlaying)

                
                Spacer()
                
                Text("“Do what you can, with what you have, where you are.”")
                    .font(.footnote)
                    .italic()
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        print("Streak Button tapped")
                    } label: {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(streak > 0 ? .orange : .gray)
                            if streak > 1 {
                                Text("\(streak)")
                                    .font(.callout)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    .disabled(true)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if isPlaying {
                            showAmbientPickerWarning = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showAmbientPickerWarning = false
                            }
                        } else {
                            showAmbientPicker.toggle()
                        }
                    } label: {
                        Image(systemName: selectedAmbient.icon)
                        Text(selectedAmbient.name)
                    }
                    .foregroundStyle(isPlaying ? .gray : .primary)
                    .sheet(isPresented: $showAmbientPicker) {
                        AmbientSheet(selected: $selectedAmbient)
                            .presentationDragIndicator(.visible)
                    }
                }
            }
            .onReceive(timer) { _ in
                // Handle countdown logic
                updateTimer()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                if isPlaying {
                    isPaused = true
                    audioManager.pause()
                }
            }
            .overlay(
                VStack(spacing: 8) {
                    if showTaskWarning {
                        Text("Please select a focus task first.")
                            .font(.footnote)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.red.opacity(0.9))
                            .clipShape(Capsule())
                            .transition(.opacity.combined(with: .scale))
                    }
                    
                    if showAmbientPickerWarning {
                        Text("Stop the timer to change ambient sound.")
                            .font(.footnote)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.gray.opacity(0.9))
                            .clipShape(Capsule())
                            .transition(.opacity.combined(with: .scale))
                    }
                }
                    .padding(.bottom, 50),
                alignment: .top
            )
            .animation(.easeInOut, value: showTaskWarning || showAmbientPickerWarning)
            .sheet(isPresented: $showCompletionSheet, onDismiss: {
                // Called when sheet is dismissed
                resetTime()
                hasCompletedSession = false
            }) {
                SessionCompletionSheet(
                    taskName: completedTaskName,
                    duration: completedDuration,
                    streakCount: streak,
                    dailyCount: focusSessionsToday
                )
                .presentationDragIndicator(.visible)
            }
        }
        .padding(8)
        .onAppear {
            if userSettings.isEmpty {
                let settings = UserSettings(defaultFocusDuration: 600, dailyTargetSessions: 4)
                modelContext.insert(settings)
                try? modelContext.save()
                totalTime = settings.defaultFocusDuration
                timeRemaining = settings.defaultFocusDuration
            } else if let settings = userSettings.first {
                totalTime = settings.defaultFocusDuration
                timeRemaining = settings.defaultFocusDuration
            }
            
            if focusTasks.isEmpty {
                let defaultTasks = [
                    FocusTask(name: "Work", icon: "desktopcomputer"),
                    FocusTask(name: "Study", icon: "book"),
                    FocusTask(name: "Coding", icon: "apple.terminal"),
                    FocusTask(name: "Reading", icon: "book.closed")
                ]
                defaultTasks.forEach { modelContext.insert($0) }
                try? modelContext.save()
            }
        }
        .onChange(of: userSettings.first?.defaultFocusDuration) { oldValue, newValue in
            if !isPlaying, let newVal = newValue {
                totalTime = newVal
                timeRemaining = newVal
            }
        }
        .onDisappear {
            resetTime()
        }

    }
}

#Preview("Light") {
    let container = try! ModelContainer(for: UserSettings.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    
    // Insert a mock user settings object
    let context = container.mainContext
    context.insert(UserSettings(defaultFocusDuration: 600, dailyTargetSessions: 5))
    
    return HomePageView()
        .modelContainer(container)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    let container = try! ModelContainer(for: UserSettings.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    
    let context = container.mainContext
    context.insert(UserSettings(defaultFocusDuration: 500, dailyTargetSessions: 4))
    
    return HomePageView()
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
