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
            
            // Progress ring with enhanced animations
            Circle()
                .trim(from:0, to: progress)
                .stroke(style: .init(lineWidth: 16, lineCap: .round))
                .foregroundStyle(isPaused ? Color.orange : Color.teal)
                .rotationEffect(.degrees(-90))
                .animation(.smooth(duration: 0.5), value: progress)
                .animation(.smooth(duration: 0.4), value: isPaused)
                .id(totalTime - timeRemaining) // Force view refresh on reset
            
            // Time display with enhanced styling
            VStack(spacing: 4) {
                Text(formattedTime)
                    .font(.system(size: 68, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .opacity(isPaused ? 0.7 : 1.0)
                    .scaleEffect(isPaused ? 0.98 : 1.0)
                    .animation(.smooth(duration: 0.3), value: isPaused)
                
                // Enhanced pause indicator
                if isPaused {
                    Text("PAUSED")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.orange)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.15))
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .bottom)),
                            removal: .scale(scale: 1.2).combined(with: .opacity).combined(with: .move(edge: .bottom))
                        ))
                        .animation(.bouncy(duration: 0.5, extraBounce: 0.3), value: isPaused)
                }
            }
        }
        .frame(width: 260, height: 260)
        .overlay(
            // Enhanced pulsating pause indicator ring
            isPaused ?
            Circle()
                .stroke(Color.orange.opacity(0.2), lineWidth: 4)
                .frame(width: 285, height: 285)
                .scaleEffect(isPaused ? 1.05 : 1.0)
                .opacity(isPaused ? 0.8 : 0.0)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: isPaused
                )
            : nil
        )
    }
}


#Preview {
    TimerView(timeRemaining: 1500, totalTime: 1500)
}
