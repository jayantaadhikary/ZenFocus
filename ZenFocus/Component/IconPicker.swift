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
                                .padding()
                                .background(selectedIcon == icon ? Color.teal.opacity(0.3) : Color.clear)
                                .clipShape(Circle())
                        }
                    }
                }
            }
        }
    }