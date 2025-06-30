//
//  SessionCompletionSheet.swift
//  ZenFocus
//
//  Created by Jayanta Adhikary on 30/06/25.
//

import SwiftUI

struct SessionCompletionSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let taskName: String
    let duration: Int
    let streakCount: Int
    let dailyCount: Int
    var onDismiss: () -> Void = {}
    
    // Break up computed properties
    var formattedTime: String {
        let minutes = duration / 60
        let seconds = duration % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    var streakText: String {
        return "\(streakCount) day\(streakCount == 1 ? "" : "s")"
    }
    
    // Break the view into smaller components
    var celebrationGraphic: some View {
        ZStack {
            Circle()
                .fill(.teal.opacity(0.15))
                .frame(width: 200, height: 200)
            
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100)
                .foregroundStyle(.teal)
        }
    }
    
    var statsSection: some View {
        VStack(spacing: 16) {
            statRow(icon: "clock.fill", label: "Focused for", value: formattedTime)
            statRow(icon: "target", label: "Task", value: taskName)
            statRow(icon: "calendar", label: "Today's sessions", value: "\(dailyCount)")
            
            if streakCount > 0 {
                statRow(icon: "flame.fill", label: "Current streak", value: streakText, iconColor: .orange)
            }
        }
        .padding(.horizontal)
    }
    
    func statRow(icon: String, label: String, value: String, iconColor: Color = .teal) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
    
    var actionButton: some View {
        Button {
            dismiss()
            onDismiss()
        } label: {
            Text("Done")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.teal)
                )
                .foregroundStyle(.white)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Use the extracted components
                celebrationGraphic
                    .padding(.top, 20)
                
                // Header
                Text("Session Complete!")
                    .font(.title)
                    .bold()
                
                // Stats
                statsSection
                
                // Message
                Text("Great job staying focused!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Action Button
                actionButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}

#Preview {
    SessionCompletionSheet(
        taskName: "Coding", 
        duration: 1500,
        streakCount: 3,
        dailyCount: 2
    )
}
