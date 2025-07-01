//
//  OnboardingView.swift
//  ZenFocus
//
//  Created by Jayanta Adhikary on 28/06/25.
//

import Foundation
import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentTab = 0
    @State private var showSetupScreen = false
    
    var body: some View {
        if showSetupScreen {
            InitialSetupScreen()
        } else {
            VStack {
                TabView(selection: $currentTab) {
                    OnboardingSlideView(
                        title: "Welcome to ZenFocus",
                        subtitle: "Boost your productivity through focused sessions and calming sounds.",
                        image: "brain.head.profile"
                    )
                    .tag(0)

                    OnboardingSlideView(
                        title: "Track Your Progress",
                        subtitle: "Daily streaks and session history help you stay consistent.",
                        image: "chart.bar.fill"
                    )
                    .tag(1)

                    OnboardingSlideView(
                        title: "Personalize Your Focus",
                        subtitle: "Choose sounds and tasks that work for you.",
                        image: "slider.horizontal.3"
                    )
                    .tag(2)
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                Button(action: {
                    if currentTab < 2 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentTab += 1
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showSetupScreen = true
                        }
                    }
                }) {
                    Text(currentTab < 2 ? "Next" : "Continue")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
    }
}

struct OnboardingSlideView: View {
    let title: String
    let subtitle: String
    let image: String
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            Image(systemName: image)
                .resizable()
                .scaledToFit()
                .frame(height: 120)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}
