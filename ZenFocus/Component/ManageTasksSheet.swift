//
//  ManageTasksSheet.swift
//  ZenFocus
//
//  Created by Jayanta Adhikary on 15/06/25.
//


import SwiftUI
import SwiftData

struct ManageTasksSheet: View {
    @Query private var tasks: [FocusTask]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showNewTaskSheet = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(tasks) { task in
                    HStack {
                        Image(systemName: task.icon)
                        Text(task.name)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        context.delete(tasks[index])
                    }
                    try? context.save()
                }
            }
            .navigationTitle("Manage Tasks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewTaskSheet = true
                    } label: {
                        Label("New Task", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showNewTaskSheet) {
            NewTaskSheet { newTask in
                context.insert(newTask)
                try? context.save()
            }
        }
    }
}
