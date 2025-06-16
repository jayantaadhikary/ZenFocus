//
//  UpgradeProSheet.swift
//  ZenFocus
//
//  Created by Jayanta Adhikary on 15/06/25.
//

import SwiftUI


struct UpgradeProSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("ZenFocus Pro")
                    .font(.largeTitle.bold())

                Text("Unlock premium features like insights, custom durations, iCloud sync and more.")
                    .multilineTextAlignment(.center)

                Button("Subscribe for ₹199/year") {
                    // Add IAP logic here
                }
                .buttonStyle(.borderedProminent)

                Button("Close") { dismiss() }
            }
            .padding()
            .navigationTitle("Go Pro")
        }
    }
}
