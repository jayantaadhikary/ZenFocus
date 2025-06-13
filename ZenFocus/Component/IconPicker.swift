//
//  IconPicker.swift
//  ZenFocus
//
//  Created by Jayanta Adhikary on 12/06/25.
//

import Foundation
import SwiftUI

struct IconPicker: View {
        @Binding var selectedIcon: String
        
        let icons = ["pencil", "book", "desktopcomputer", "bolt", "flame", "leaf", "moon", "star"]
        
        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                        } label: {
                            Image(systemName: icon)
                                .padding(.horizontal)
                                .foregroundColor(selectedIcon == icon ? .blue : .gray)
                        }
                    }
                }
            }
        }
    }

#Preview {
    IconPicker(selectedIcon: .constant("pencil"))
}
