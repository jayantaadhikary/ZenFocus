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
    
    @StateObject private var audioManager = AmbientAudioManager.shared
    
//    @State var streak: Int = 2
    var sessionDays: [Date] {
        let calendar = Calendar.current
        let uniqueDays = Set(allSessions.map { calendar.startOfDay(for: $0.date) })
        return Array(uniqueDays).sorted(by: >) // Latest first
    }

    var streak: Int {
        let calendar = Calendar.current
        var streakCount = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for day in sessionDays {
            if calendar.isDate(day, inSameDayAs: currentDate) {
                streakCount += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        return streakCount
    }

    
    @State private var showAmbientPicker = false
    @State private var selectedAmbient: AmbientOption = ambientOptions[0]
    
    @State private var timeRemaining: Int = 15
    @State private var totalTime: Int = 15
    
    @State private var isPlaying: Bool = false
    @State private var isPaused: Bool = false
    
    var focusSessionsToday: Int {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return allSessions.filter { $0.date >= startOfToday }.count
    }
    
    @State private var hasCompletedSession = false
    
    @State private var showAmbientPickerWarning = false
    
    @State private var focusTasks: [FocusTask] = [
        FocusTask(name: "Work", icon: "desktopcomputer"),
        FocusTask(name: "Study", icon: "book"),
        FocusTask(name: "Coding ", icon: "apple.terminal"),
        FocusTask(name: "Reading", icon: "book.closed")
    ]

    @State private var selectedTask: FocusTask?
    @State private var showTaskWarning = false
    
    private func resetTime() {
        timeRemaining = totalTime
        isPlaying = false
        isPaused = false
        hasCompletedSession = false
        audioManager.stop()
    }
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                Text("Focus • \(focusSessionsToday) of 4")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                TimerView(timeRemaining: timeRemaining, totalTime: totalTime)
                
                Spacer()
                
                Text("🎯 \(focusSessionsToday) focus session\(focusSessionsToday <= 1 ? "" : "s") completed today")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
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

                        if !isPlaying {
                            isPlaying = true
                            isPaused = false
                            hasCompletedSession = false
                            
                            if let sound = selectedAmbient.audioFileName {
                                        audioManager.playSound(named: sound)
                                    }
                        } else {
                            isPaused.toggle()
                            if isPaused {
                                        audioManager.pause()
                                    } else {
                                        audioManager.resume()
                                    }
                        }
                    } label: {
                        Image(systemName: !isPlaying || isPaused ? "play" : "pause")
                        Text(!isPlaying || isPaused ? "Start" : "Pause")
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal)
                    
                    Button {
                        resetTime()
                    } label: {
                        Image(systemName: "arrow.trianglehead.clockwise.rotate.90")
                        Text("Reset")
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Select Task to Focus on
                VStack {
                    Text("What are you focusing on?")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(focusTasks) { item in
                                Button {
                                    if selectedTask == item {
                                        selectedTask = nil
                                    } else {
                                        selectedTask = item
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: item.icon)
                                        Text(item.name)
                                    }
                                    .padding(.horizontal, 8)
                                }
                                .padding(6)
                                .buttonStyle(.bordered)
                                .foregroundStyle(selectedTask == item ? .teal : .secondary)
                            }
                        }
                    }
                }
                
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
                        HStack{
                           
                            Image(systemName: "flame.fill")
                                .foregroundStyle(streak > 0 ? .orange : .gray)
                            if (streak > 1){
                                Text("\(streak)")
                                    .font(.callout)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
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
                if isPlaying && !isPaused && timeRemaining > 0 {
                    timeRemaining -= 1
                }
                
                if timeRemaining == 0 && isPlaying && !hasCompletedSession {
                    hasCompletedSession = true
                    isPlaying = false
                    audioManager.stop()
                    AudioServicesPlayAlertSound(1106)
                    
                    if let task = selectedTask {
                            let session = FocusSession(
                                taskName: task.name,
                                duration: totalTime
                            )
                            modelContext.insert(session)
                        }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                if isPlaying {
                    isPaused = true
                    audioManager.pause()
                }
            }
            .alert("Session Complete!", isPresented: $hasCompletedSession) {
                Button("Ok", role: .cancel) {
                    resetTime()
                }
            } message: {
                Text("Great job! You’ve completed a focus session.")
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
                .padding(.bottom, 60),
                alignment: .top
            )
            .animation(.easeInOut, value: showTaskWarning || showAmbientPickerWarning)

            
        }
        .padding(8)
    }
}

#Preview("Light") {
    HomePageView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    HomePageView()
        .preferredColorScheme(.dark)
}
