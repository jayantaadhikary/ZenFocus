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
    
    var body: some View {
        TabView {
            Tab("Timer", systemImage: "timer"){
                HomePageView()
            }
            Tab("Stats", systemImage: "chart.bar") {
                
            }
            Tab("Settings", systemImage: "gearshape") {
                
            }
            .badge("!")
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
