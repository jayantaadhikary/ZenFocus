//
//  TimerView.swift
//  ZenFocus
//
//  Created by Jayanta Adhikary on 11/06/25.
//

import SwiftUI

struct TimerView: View {
    var timeRemaining: Int
    var totalTime: Int
    var isPaused: Bool = false
    
    var progress: CGFloat {
        totalTime == 0 ? 0 : CGFloat(timeRemaining) / CGFloat(totalTime)
    }
    
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(.secondary.opacity(0.15), lineWidth: 16)
            
            // Progress ring
            Circle()
                .trim(from:0, to: progress)
                .stroke(style: .init(lineWidth: 16, lineCap: .round))
                .foregroundStyle(isPaused ? Color.orange : Color.teal)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.3), value: progress)
                .id(totalTime - timeRemaining) // Force view refresh on reset
            
            // Time display
            VStack(spacing: 0) {
                Text(formattedTime)
                    .font(.system(size: 68, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .opacity(isPaused ? 0.7 : 1.0)
                
                // Pause indicator
                if isPaused {
                    Text("PAUSED")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.orange)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.orange.opacity(0.1))
                        )
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .frame(width: 260, height: 260)
        .overlay(
            // Pulsating pause indicator ring for paused state
            isPaused ?
            Circle()
                .stroke(Color.orange.opacity(0.2), lineWidth: 6)
                .frame(width: 280, height: 280)
                .scaleEffect(isPaused ? [1.0, 1.05].randomElement()! : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(), value: isPaused)
            : nil
        )
    }
}


#Preview {
    TimerView(timeRemaining: 1500, totalTime: 1500)
}
