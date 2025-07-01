//
//  BreakReminderView.swift
//  ZenFocus
//
//  Created by Jayanta Adhikary on 02/07/25.
//

import SwiftUI
import AudioToolbox

struct BreakReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var showBreakTimer: Bool
    @State private var breakTime: Int = 300 // 5 minutes default
    @State private var isBreakActive: Bool = false
    @State private var breakTimeRemaining: Int = 300
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var formattedBreakTime: String {
        let minutes = breakTimeRemaining / 60
        let seconds = breakTimeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse, options: .repeating, value: isBreakActive)
                
                Text("Time for a Break")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Rest your mind to stay focused for longer")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Break timer display
            if isBreakActive {
                ZStack {
                    Circle()
                        .stroke(.secondary.opacity(0.15), lineWidth: 12)
                        .frame(width: 180, height: 180)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(breakTimeRemaining) / CGFloat(breakTime))
                        .stroke(style: .init(lineWidth: 12, lineCap: .round))
                        .foregroundStyle(.blue)
                        .rotationEffect(.degrees(-90))
                        .frame(width: 180, height: 180)
                        .animation(.linear(duration: 0.3), value: breakTimeRemaining)
                    
                    Text(formattedBreakTime)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                .padding(.vertical, 10)
            }
            
            // Break tips
            if isBreakActive {
                VStack(alignment: .leading, spacing: 12) {
                    BreakTipRow(icon: "eye", tip: "Look away from your screen")
                    BreakTipRow(icon: "figure.walk", tip: "Stand up and stretch")
                    BreakTipRow(icon: "cup.and.saucer", tip: "Get a glass of water")
                }
                .padding(.vertical)
            }
            
            Spacer(minLength: 10)
            
            // Action buttons
            VStack(spacing: 15) {
                if !isBreakActive {
                    Button(action: {
                        startBreak()
                    }) {
                        Text("Take a 5-Minute Break")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Skip Break")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 5)
                } else {
                    Button(action: {
                        endBreak()
                    }) {
                        Text("End Break")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.secondary.opacity(0.15))
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.bottom)
        }
        .padding()
        .onReceive(timer) { _ in
            if isBreakActive && breakTimeRemaining > 0 {
                breakTimeRemaining -= 1
            } else if isBreakActive && breakTimeRemaining == 0 {
                completeBreak()
            }
        }
        .onDisappear {
            isBreakActive = false
        }
    }
    
    private func startBreak() {
        withAnimation(.easeInOut) {
            isBreakActive = true
            breakTimeRemaining = breakTime
        }
        
        // Trigger haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    private func endBreak() {
        withAnimation(.easeInOut) {
            isBreakActive = false
        }
        dismiss()
    }
    
    private func completeBreak() {
        // Play completion sound
        AudioServicesPlaySystemSound(1007) // iOS system sound
        
        withAnimation(.easeInOut) {
            isBreakActive = false
        }
        
        // Wait a moment before dismissing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss()
        }
    }
}

// Helper view for break tips
struct BreakTipRow: View {
    var icon: String
    var tip: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(tip)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

// Preview provider
#Preview {
    BreakReminderView(showBreakTimer: .constant(true))
        .preferredColorScheme(.dark)
}
