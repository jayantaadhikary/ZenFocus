//
//  AmbientSheet.swift
//  ZenFocus
//
//  Created by Jayanta Adhikary on 11/06/25.
//

import SwiftUI

struct AmbientSheet: View {
    
    @Binding var selected: AmbientOption
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            NavigationStack {
                List {
                    ForEach(ambientOptions) { option in
                        HStack {
                            Label(option.name, systemImage: option.icon)
                            Spacer()
                            if selected == option {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selected = option
                            dismiss()
                        }
                    }
                }
                .navigationTitle("Ambient Sound")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
}

#Preview {
    AmbientSheet(selected: .constant(ambientOptions[0]))
}
