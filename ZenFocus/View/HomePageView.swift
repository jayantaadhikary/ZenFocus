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
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let sessionDaysSet = Set(sessionDays)
        
        // Start from yesterday if no sessions today, otherwise start from today
        let startDate = sessionDaysSet.contains(today) ? today : yesterday
        
        var currentStreak = 0
        var checkDate = startDate
        
        while sessionDaysSet.contains(checkDate) {
            currentStreak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        
        return currentStreak
    }
    
    
    @State private var showAmbientPicker = false
    @State private var selectedAmbient: AmbientOption = ambientOptions[0]
    
    @State private var totalTime: Int = 0
    @State private var timeRemaining: Int = 0
    @State private var hasInitializedTime = false
    @State private var timeElapsed: Int = 0
    
    @State private var isPlaying: Bool = false
    @State private var isPaused: Bool = false
    @State private var pauseCount: Int = 0
    @State private var totalPausedTime: Int = 0
    @State private var lastPauseStartTime: Date? = nil
    
    @State private var hasCompletedSession = false
    @State private var showAmbientPickerWarning = false
    @State private var showTaskWarning = false
    @State private var showCompletionSheet = false
    @State private var showBreakReminder = false
    @State private var completedTaskName = ""
    @State private var completedDuration = 0
    
    @State private var selectedTask: FocusTask?
    
    var focusSessionsToday: Int {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return allSessions.filter { $0.date >= startOfToday }.count
    }
    
    // Motivational message based on daily progress
    private func motivationalMessage(completed: Int, target: Int) -> String {
        let progress = Double(completed) / Double(target)
        
        switch progress {
        case 1...:
            return "🎉 Daily goal achieved! Amazing work!"
        case 0.8..<1:
            return "🔥 Almost there! One more session to go"
        case 0.5..<0.8:
            return "💪 Great progress! Keep it up"
        case 0.25..<0.5:
            return "🌱 Good start! You're building momentum"
        default:
            if completed == 0 {
                return "🚀 Ready to start your focus journey?"
            } else {
                return "✨ Every session counts! Keep going"
            }
        }
    }
    
    private func resetTime() {
        timeRemaining = totalTime
        timeElapsed = 0
        isPlaying = false
        isPaused = false
        hasCompletedSession = false
        pauseCount = 0
        totalPausedTime = 0
        lastPauseStartTime = nil
        audioManager.stop()
        UIApplication.shared.isIdleTimerDisabled = false
        
        // Clear session data using helper function
        clearSessionData()
    }
    
    private func updateTimer() {
        // Handle countdown logic
        if isPlaying && !isPaused && timeRemaining > 0 {
            timeRemaining -= 1
            timeElapsed += 1
            
            // Save current state to UserDefaults for persistence
            UserDefaults.standard.setValue(timeRemaining, forKey: "timeRemaining")
            UserDefaults.standard.setValue(timeElapsed, forKey: "timeElapsed")
            UserDefaults.standard.setValue(true, forKey: "isSessionActive")
        }
        
        // Check for session completion
        checkSessionCompletion()
    }
    
    private func checkSessionCompletion() {
        // Enhanced completion check with race condition protection
        guard timeRemaining <= 0 && !hasCompletedSession && isPlaying else { 
            return 
        }
        
        // Mark session as complete immediately to prevent race conditions
        hasCompletedSession = true
        isPlaying = false
        
        // Stop audio and play alert
        audioManager.stop()
        AudioServicesPlayAlertSound(1106)
        
        // Only save session if a task was selected and session was meaningful
        if let task = selectedTask {
            saveCompletedSession(task: task)
        }
    }
    
    private func saveCompletedSession(task: FocusTask) {
        // Session validation - ensure valid session data
        let actualTimeSpent = totalTime - timeRemaining
        guard totalTime > 0 else {
            print("Invalid session data - not saving")
            return
        }
        
        // Create session with actual time spent, not total time
        let session = FocusSession(
            taskName: task.name,
            duration: actualTimeSpent, // Save actual time spent, not total time
            pauseCount: pauseCount,
            totalPausedTime: totalPausedTime,
            completionDate: Date()
        )
        
        // Enhanced error handling for data persistence
        do {
            modelContext.insert(session)
            try modelContext.save()
            print("Session saved successfully: \(task.name), \(actualTimeSpent)s")
        } catch {
            print("Failed to save session: \(error.localizedDescription)")
            // Could show user notification here in the future
        }
        
        // Prepare completion sheet data with actual time spent
        completedTaskName = task.name
        completedDuration = actualTimeSpent
        showCompletionSheet = true
        
        // Clear session state from UserDefaults
        clearSessionData()
    }
    
    // Enhanced session state restoration with validation
    private func restoreSessionState() {
        guard let savedTime = UserDefaults.standard.object(forKey: "timeRemaining") as? Int,
              let savedTotalTime = UserDefaults.standard.object(forKey: "totalTime") as? Int,
              let savedTaskName = UserDefaults.standard.string(forKey: "selectedTaskName"),
              savedTime > 0, savedTotalTime > 0 else {
            return
        }
        
        // Find the task by name
        if let task = focusTasks.first(where: { $0.name == savedTaskName }) {
            timeRemaining = savedTime
            totalTime = savedTotalTime
            selectedTask = task
            isPlaying = UserDefaults.standard.bool(forKey: "isPlaying")
            isPaused = UserDefaults.standard.bool(forKey: "isPaused")
            hasCompletedSession = UserDefaults.standard.bool(forKey: "hasCompletedSession")
            pauseCount = UserDefaults.standard.integer(forKey: "pauseCount")
            totalPausedTime = UserDefaults.standard.integer(forKey: "totalPausedTime")
            
            // Restore pause timing if needed
            if isPaused {
                lastPauseStartTime = UserDefaults.standard.object(forKey: "pauseStartTime") as? Date
            }
            
            print("Session state restored: \(savedTaskName), \(savedTime)s remaining")
        }
    }
    
    // Enhanced session data cleanup
    private func clearSessionData() {
        let sessionKeys = [
            "timeRemaining", "totalTime", "selectedTaskName", "isPlaying", 
            "isPaused", "hasCompletedSession", "pauseCount", "totalPausedTime", 
            "pauseStartTime"
        ]
        
        sessionKeys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        print("Session data cleared from UserDefaults")
    }
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                // Enhanced Daily Target Tracking
                VStack(spacing: 8) {
                    let dailyTarget = userSettings.first?.dailyTargetSessions ?? 4
                    let progress = min(Double(focusSessionsToday) / Double(dailyTarget), 1.0)
                    let isGoalMet = focusSessionsToday >= dailyTarget
                    
                    // Progress indicator
                    HStack(spacing: 12) {
                        // Progress ring
                        ZStack {
                            Circle()
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 3)
                                .frame(width: 32, height: 32)
                            
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(
                                    isGoalMet ? Color.green : Color.accentColor,
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                )
                                .frame(width: 32, height: 32)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.6), value: progress)
                            
                            if isGoalMet {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.green)
                                    .scaleEffect(isGoalMet ? 1.0 : 0.0)
                                    .animation(.bouncy(duration: 0.6), value: isGoalMet)
                            }
                        }
                        
                        // Progress text and motivational message
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Focus • \(focusSessionsToday) of \(dailyTarget)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                                .contentTransition(.numericText())
                            
                            // Motivational message
                            Text(motivationalMessage(completed: focusSessionsToday, target: dailyTarget))
                                .font(.caption)
                                .foregroundStyle(isGoalMet ? .green : .secondary)
                                .animation(.easeInOut(duration: 0.4), value: focusSessionsToday)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.05))
                            .stroke(
                                isGoalMet ? Color.green.opacity(0.3) : Color.clear,
                                lineWidth: 1
                            )
                    )
                    .padding(.horizontal, 20) // Add horizontal margin for rounded corners
                    .scaleEffect(isGoalMet ? 1.02 : 1.0)
                    .animation(.bouncy(duration: 0.6), value: isGoalMet)
                }
                .animation(.smooth(duration: 0.4), value: focusSessionsToday)
                
                Spacer()
                
                if totalTime > 0 {
                    TimerView(
                        timeRemaining: timeRemaining,
                        totalTime: totalTime,
                        isPaused: isPaused
                    )
                    .scaleEffect(isPlaying && !isPaused ? 1.02 : 1.0)
                    .animation(
                        isPlaying && !isPaused ? 
                            .easeInOut(duration: 2.0).repeatForever(autoreverses: true) :
                            .smooth(duration: 0.6),
                        value: isPlaying
                    )
                    .animation(.smooth(duration: 0.4), value: isPaused)
                    .rotation3DEffect(
                        .degrees(isPaused ? 2 : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .animation(.smooth(duration: 0.5), value: isPaused)
                    .id("timer-\(isPlaying ? "playing" : "stopped")-\(isPaused ? "paused" : "active")")
                    //MARK:- Remove the triple tap gesture for test mode
                    .onTapGesture(count: 3) {  // Triple tap to set 10-second test timer
                        withAnimation(.bouncy(duration: 0.8)) {
                            totalTime = 10
                            timeRemaining = 10
                        }
                    }
                    // Enhanced pause state indicator
                    .overlay(
                        isPaused ?
                        ZStack {
                            // Outer pulse ring
                            Circle()
                                .stroke(Color.orange.opacity(0.3), lineWidth: 3)
                                .frame(width: 290, height: 290)
                                .scaleEffect(isPaused ? 1.1 : 1.0)
                                .opacity(isPaused ? 0.8 : 0.0)
                                .animation(
                                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                    value: isPaused
                                )
                            
                            // Inner subtle ring
                            RoundedRectangle(cornerRadius: 130)
                                .stroke(Color.orange.opacity(0.4), lineWidth: 2)
                                .frame(width: 270, height: 270)
                        }
                        .transition(.scale.combined(with: .opacity))
                        : nil
                    )
                }
                
                Spacer()
                
                Text("🎯 \(focusSessionsToday) focus session\(focusSessionsToday <= 1 ? "" : "s") completed today")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .animation(.bouncy(duration: 0.8, extraBounce: 0.2), value: focusSessionsToday)
                    .scaleEffect(focusSessionsToday > 0 ? 1.0 : 0.95)
                    .animation(.smooth(duration: 0.3), value: focusSessionsToday)
                
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
                        
                        withAnimation(.smooth(duration: 0.5, extraBounce: 0.1)) {
                            if !isPlaying {
                                // Start a new session
                                isPlaying = true
                                isPaused = false
                                hasCompletedSession = false
                                
                                // Track session state
                                UserDefaults.standard.setValue(true, forKey: "isSessionActive")
                                UserDefaults.standard.setValue(selectedTask?.id.uuidString, forKey: "activeTaskID")
                                UserDefaults.standard.setValue(totalTime, forKey: "sessionTotalTime")
                                UserDefaults.standard.setValue(timeRemaining, forKey: "timeRemaining")
                                
                                // Keep screen on during session
                                UIApplication.shared.isIdleTimerDisabled = true
                                
                                // Start ambient sound
                                if let sound = selectedAmbient.audioFileName {
                                    audioManager.playSound(named: sound)
                                }
                                
                                // Enhanced haptic feedback
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                            } else {
                                // Toggle pause state with smoother animation
                                withAnimation(.smooth(duration: 0.3)) {
                                    isPaused.toggle()
                                }
                                
                                if isPaused {
                                    // Entering pause state
                                    pauseCount += 1
                                    lastPauseStartTime = Date()
                                    audioManager.pause()
                                    UIApplication.shared.isIdleTimerDisabled = false
                                    
                                    // Save state
                                    UserDefaults.standard.setValue(true, forKey: "isPaused")
                                    UserDefaults.standard.setValue(Date(), forKey: "pauseStartTime")
                                    
                                    // Softer haptic feedback for pause
                                    let impact = UIImpactFeedbackGenerator(style: .soft)
                                    impact.impactOccurred()
                                } else {
                                    // Resuming from pause
                                    if let pauseStartTime = lastPauseStartTime {
                                        let pauseDuration = Int(Date().timeIntervalSince(pauseStartTime))
                                        totalPausedTime += pauseDuration
                                    }
                                    
                                    audioManager.resume()
                                    UIApplication.shared.isIdleTimerDisabled = true
                                    
                                    // Update state
                                    UserDefaults.standard.setValue(false, forKey: "isPaused")
                                    UserDefaults.standard.setValue(totalPausedTime, forKey: "totalPausedTime")
                                    UserDefaults.standard.setValue(pauseCount, forKey: "pauseCount")
                                    
                                    // Stronger haptic feedback for resume
                                    let impact = UIImpactFeedbackGenerator(style: .rigid)
                                    impact.impactOccurred()
                                }
                            }
                        }
                    } label: {
                        // Enhanced button state representation with smooth transitions
                        Group {
                            if !isPlaying {
                                Label("Start", systemImage: "play.fill")
                                    .font(.headline)
                                    .symbolEffect(.bounce, value: !isPlaying)
                            } else if isPaused {
                                Label("Resume", systemImage: "play.fill")
                                    .font(.headline)
                                    .symbolEffect(.pulse, options: .repeating, value: isPaused)
                            } else {
                                Label("Pause", systemImage: "pause.fill")
                                    .font(.headline)
                                    .symbolEffect(.variableColor, value: isPlaying)
                            }
                        }
                        .contentTransition(.symbolEffect(.replace.byLayer))
                    }
                    .foregroundStyle(isPaused ? .orange : (isPlaying ? .primary : .green))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isPaused ? Color.orange.opacity(0.15) :
                                    (isPlaying ? Color.secondary.opacity(0.1) : Color.green.opacity(0.15)))
                            .shadow(
                                color: isPaused ? .orange.opacity(0.3) : 
                                       (isPlaying ? .clear : .green.opacity(0.3)),
                                radius: isPaused || !isPlaying ? 4 : 0,
                                x: 0, y: 2
                            )
                    )
                    .scaleEffect(selectedTask == nil ? 0.95 : 1.0)
                    .opacity(selectedTask == nil ? 0.6 : 1.0)
                    .animation(.smooth(duration: 0.3), value: selectedTask)
                    .animation(.smooth(duration: 0.4), value: isPaused)
                    .animation(.smooth(duration: 0.4), value: isPlaying)
                    .scaleEffect(selectedTask == nil ? 0.95 : 1.0)
                    .animation(.bouncy(duration: 0.4), value: selectedTask != nil)
                    
                    Button {
                        withAnimation(.bouncy(duration: 0.6, extraBounce: 0.3)) {
                            resetTime()
                        }
                        
                        // Add haptic feedback for reset
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.trianglehead.clockwise.rotate.90")
                                .font(.title2)
                                .symbolEffect(.rotate, value: timeRemaining != totalTime)
                            Text("Reset")
                        }
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.1))
                    )
                    .scaleEffect(isPlaying ? 0.95 : 1.0)
                    .opacity(isPlaying ? 0.7 : 1.0)
                    .animation(.smooth(duration: 0.3), value: isPlaying)
                }
                
                Spacer()
                
                VStack {
                    Text("What are you focusing on?")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(focusTasks) { item in
                                Button {
                                    if !isPlaying {
                                        withAnimation(.bouncy(duration: 0.5, extraBounce: 0.2)) {
                                            selectedTask = selectedTask == item ? nil : item
                                        }
                                        
                                        // Add subtle haptic feedback for task selection
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: item.icon)
                                            .symbolEffect(.bounce, value: selectedTask == item)
                                        Text(item.name)
                                            .font(.subheadline)
                                            .fontWeight(selectedTask == item ? .semibold : .medium)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedTask == item ? Color.teal : Color.secondary.opacity(0.1))
                                            .shadow(
                                                color: selectedTask == item ? .teal.opacity(0.3) : .clear,
                                                radius: selectedTask == item ? 6 : 0,
                                                x: 0, y: 2
                                            )
                                    )
                                    .foregroundStyle(
                                        selectedTask == item ? .white :
                                            isPlaying ? .gray.opacity(0.6) : .primary
                                    )
                                }
                                .disabled(isPlaying)
                                .scaleEffect(selectedTask == item ? 1.02 : 1.0)
                                .animation(.smooth(duration: 0.3), value: selectedTask)
                                .animation(.easeInOut(duration: 0.2), value: isPlaying)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .opacity(isPlaying ? 0.6 : 1.0)
                .scaleEffect(isPlaying ? 0.98 : 1.0)
                .animation(.smooth(duration: 0.4), value: isPlaying)
                
                
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
                if isPlaying && !isPaused {
                    // Auto-pause when app goes to background
                    isPaused = true
                    lastPauseStartTime = Date()
                    audioManager.pause()
                    
                    // Save current state for potential app termination
                    UserDefaults.standard.setValue(true, forKey: "isPaused")
                    UserDefaults.standard.setValue(Date(), forKey: "pauseStartTime")
                    UserDefaults.standard.setValue(timeRemaining, forKey: "timeRemaining")
                    UserDefaults.standard.setValue(timeElapsed, forKey: "timeElapsed")
                    UserDefaults.standard.setValue(true, forKey: "isSessionActive")
                    UserDefaults.standard.setValue(pauseCount, forKey: "pauseCount")
                    UserDefaults.standard.setValue(totalPausedTime, forKey: "totalPausedTime")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Check if we should resume from saved state
                if UserDefaults.standard.bool(forKey: "isSessionActive") {
                    // If we have a saved pause state, update pause duration
                    if UserDefaults.standard.bool(forKey: "isPaused"),
                       let pauseStartTime = UserDefaults.standard.object(forKey: "pauseStartTime") as? Date {
                        let pauseDuration = Int(Date().timeIntervalSince(pauseStartTime))
                        totalPausedTime += pauseDuration
                    }
                }
            }
            .overlay(
                VStack(spacing: 12) {
                    if showTaskWarning {
                        Text("Please select a focus task first.")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(.red.opacity(0.9))
                                    .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .scale(scale: 0.8)).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .scale(scale: 1.1)).combined(with: .opacity)
                            ))
                    }
                    
                    if showAmbientPickerWarning {
                        Text("Stop the timer to change ambient sound.")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(.gray.opacity(0.9))
                                    .shadow(color: .gray.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .scale(scale: 0.8)).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .scale(scale: 1.1)).combined(with: .opacity)
                            ))
                    }
                }
                .padding(.bottom, 50),
                alignment: .top
            )
            .animation(.bouncy(duration: 0.6, extraBounce: 0.2), value: showTaskWarning)
            .animation(.bouncy(duration: 0.6, extraBounce: 0.2), value: showAmbientPickerWarning)
            .sheet(isPresented: $showCompletionSheet, onDismiss: {
                // Called when sheet is dismissed
                resetTime()
                hasCompletedSession = false
            }) {
                SessionCompletionSheet(
                    taskName: completedTaskName,
                    duration: completedDuration,
                    streakCount: streak,
                    dailyCount: focusSessionsToday,
                    onBreakRequest: {
                        // Show break reminder sheet when requested
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showBreakReminder = true
                        }
                    }
                )
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showBreakReminder) {
                BreakReminderView(showBreakTimer: $showBreakReminder)
                    .presentationDragIndicator(.visible)
            }
        }
        .padding(8)
        .onAppear {
            // Initialize settings if needed
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
            
            // Create default tasks if needed
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
            
            // Restore session state if app was closed/terminated during an active session
            if UserDefaults.standard.bool(forKey: "isSessionActive") {
                restoreSessionState()
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
