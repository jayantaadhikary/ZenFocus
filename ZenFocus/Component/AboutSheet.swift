//
//  AboutSheet.swift
//  ZenFocus
//
//  Created by Jayanta Adhikary on 15/06/25.
//
import SwiftUI

struct AboutSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Hi, I'm Jay 👋")
                        .font(.title2.bold())

                    Text("ZenFocus was built to help you reclaim your attention and cultivate deep focus habits, without distractions or ads. I'm an indie developer passionate about minimalist tools that respect your time and privacy. I hope you find it useful!")
                        .font(.body)
                        
                    
                    

                    Link("Twitter / X", destination: URL(string: "https://x.com/jayadky")!)
                    Link("Portfolio", destination: URL(string: "https://jayantaadhikary.xyz")!)
                }
                .padding()
            }
            .navigationTitle("About ZenFocus")
            .cornerRadius(20)
        }
        
    }
}

#Preview {
    AboutSheet()
}
