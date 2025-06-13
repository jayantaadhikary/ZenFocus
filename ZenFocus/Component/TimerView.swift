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
            Circle()
                .stroke(.secondary.opacity(0.15), lineWidth: 16)
            
            Circle()
                .trim(from:0, to: progress)
                .stroke(style: .init(lineWidth: 16, lineCap: .round))
                .foregroundStyle(.teal)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
            
            
            Text(formattedTime)
                .font(.system(size: 68, weight: .bold, design: .rounded))
                .monospacedDigit()
            
        }
        .frame(width: 260, height: 260)
    }
}

#Preview {
    TimerView(timeRemaining: 1500, totalTime: 1500)
}
