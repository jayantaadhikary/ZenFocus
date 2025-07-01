//
//  InitialSetupScreen.swift
//  ZenFocus
//
//  Created by Jayanta Adhikary on 01/07/25.
//

import Foundation
import SwiftUI
import SwiftData

struct InitialSetupScreen: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // Setup state
    @State private var selectedDuration = 1500 // 25 minutes default
    @State private var dailyTarget = 3
    @State private var selectedTasks: Set<String> = []
    
    let durationOptions = [
        (duration: 900, label: "15 min"),
        (duration: 1500, label: "25 min"),
        (duration: 2100, label: "30 min"),
        (duration: 2400, label: "40 min"),
    ]
    
    let suggestedTasks = [
        (name: "Work", icon: "desktopcomputer"),
        (name: "Study", icon: "book"),
        (name: "Coding", icon: "laptopcomputer"),
        (name: "Reading", icon: "book.closed"),
        (name: "Writing", icon: "pencil"),
        (name: "Creative", icon: "paintbrush")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80)
                            .foregroundStyle(.teal)
                        
                        Text("Let's Set You Up")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("Customize your focus preferences to get the most out of ZenFocus.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 32) {
                        // Focus Duration Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Default Focus Duration", systemImage: "clock")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(durationOptions, id: \.duration) { option in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedDuration = option.duration
                                        }
                                    }) {
                                        Text(option.label)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(selectedDuration == option.duration ? Color.accentColor : Color(.systemGray6))
                                            .foregroundColor(selectedDuration == option.duration ? .white : .primary)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                        }
                        
                        // Daily Target Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Daily Target Sessions", systemImage: "target")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 16) {
                                ForEach(1...5, id: \.self) { target in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            dailyTarget = target
                                        }
                                    }) {
                                        Text("\(target)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .frame(width: 50, height: 50)
                                            .background(dailyTarget == target ? Color.accentColor : Color(.systemGray6))
                                            .foregroundColor(dailyTarget == target ? .white : .primary)
                                            .clipShape(Circle())
                                    }
                                }
                                Spacer()
                            }
                        }
                        
                        // Task Selection
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Choose Your Focus Areas", systemImage: "list.bullet")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Select tasks you'll be working on (optional)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(suggestedTasks, id: \.name) { task in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            if selectedTasks.contains(task.name) {
                                                selectedTasks.remove(task.name)
                                            } else {
                                                selectedTasks.insert(task.name)
                                            }
                                        }
                                    }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: task.icon)
                                                .frame(width: 20)
                                                .foregroundColor(selectedTasks.contains(task.name) ? .white : .accentColor)
                                            Text(task.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                            Spacer()
                                            if selectedTasks.contains(task.name) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .frame(height: 48)
                                        .background(selectedTasks.contains(task.name) ? Color.accentColor : Color(.systemGray6))
                                        .foregroundColor(selectedTasks.contains(task.name) ? .white : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: completeSetup) {
                            Text("Complete Setup")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button(action: skipSetup) {
                            Text("Skip for Now")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func completeSetup() {
        saveUserPreferences()
        
        withAnimation(.easeInOut(duration: 0.5)) {
            hasCompletedOnboarding = true
        }
    }
    
    private func skipSetup() {
        // Save default settings (ignore user selections)
        let settings = UserSettings(
            defaultFocusDuration: 1500, // Default 25 minutes
            dailyTargetSessions: 3,     // Default 3 sessions
            theme: .system
        )
        context.insert(settings)
        
        // Add default tasks (ignore user selections)
        let defaultTasks = [
            FocusTask(name: "Work", icon: "desktopcomputer"),
            FocusTask(name: "Study", icon: "book"),
            FocusTask(name: "Coding", icon: "laptopcomputer"),
            FocusTask(name: "Reading", icon: "book.closed")
        ]
        defaultTasks.forEach { context.insert($0) }
        
        try? context.save()
        
        withAnimation(.easeInOut(duration: 0.5)) {
            hasCompletedOnboarding = true
        }
    }
    
    private func saveUserPreferences() {
        // Save user settings
        let settings = UserSettings(
            defaultFocusDuration: selectedDuration,
            dailyTargetSessions: dailyTarget,
            theme: .system
        )
        context.insert(settings)
        
        // Save selected tasks
        for taskName in selectedTasks {
            if let task = suggestedTasks.first(where: { $0.name == taskName }) {
                let focusTask = FocusTask(name: task.name, icon: task.icon)
                context.insert(focusTask)
            }
        }
        
        // Save default tasks if none selected
        if selectedTasks.isEmpty {
            let defaultTasks = [
                FocusTask(name: "Work", icon: "desktopcomputer"),
                FocusTask(name: "Study", icon: "book"),
                FocusTask(name: "Coding", icon: "laptopcomputer"),
                FocusTask(name: "Reading", icon: "book.closed")
            ]
            defaultTasks.forEach { context.insert($0) }
        }
        
        try? context.save()
    }
}

#Preview {
    InitialSetupScreen()
}
