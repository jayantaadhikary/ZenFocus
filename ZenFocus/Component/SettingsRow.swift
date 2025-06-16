//
//  SettingsRow.swift
//  ZenFocus
//
//  Created by Jayanta Adhikary on 15/06/25.
//

import Foundation
import SwiftUI

struct SettingsRow: View {
    var label: String
    var icon: String
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack {
                Label(label, systemImage: icon)
                    .labelStyle(.titleAndIcon)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        
    }
}
