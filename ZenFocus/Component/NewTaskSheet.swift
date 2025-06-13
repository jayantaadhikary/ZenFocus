//
//  NewTaskSheet.swift
//  ZenFocus
//
//  Created by Jayanta Adhikary on 12/06/25.
//

import SwiftUI

struct NewTaskSheet: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var taskName: String = ""
    @State private var selectedIcon: String = "pencil"
    
    var onAdd: (FocusTask) -> Void
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section(header: Text("Task Name")) {
                        TextField("Enter task name", text: $taskName)
                    }
                    
                    Section(header: Text("Choose an icon")) {
                        IconPicker(selectedIcon: $selectedIcon)
                    }
                }
                
                Button{
                    if taskName.isEmpty {
                        return
                    }
                    let newTask = FocusTask(name: taskName, icon: selectedIcon)
                    onAdd(newTask)
                    dismiss()
                    
                } label: {
                    Text("Add Task")
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 24)
                .padding(.bottom)
                .cornerRadius(20)
                
                
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .imageScale(.large)
                            .tint(.gray)
                    }
                }
            }
        }
    }
}

//#Preview {
//    NewTaskSheet()
//}
