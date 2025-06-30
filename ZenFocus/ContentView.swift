//
//  ContentView.swift
//  ZenFocus
//
//  Created by Jayanta Adhikary on 11/06/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var selectedTab: Int = 0
    
    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView()
        } else {
            
            TabView(selection: $selectedTab) {
                HomePageView()
                    .tabItem {
                        Label("Focus", systemImage: "timer")
                    }
                    .tag(0)
                SummaryPageView(selectedTab: $selectedTab)
                    .tabItem {
                        Label("Summary", systemImage: "chart.bar")
                    }
                    .tag(1)
                SettingsPageView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .tag(2)
            }
        }
    }
}
#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

#Preview("Dark") {
    ContentView()
        .preferredColorScheme(.dark)
}
