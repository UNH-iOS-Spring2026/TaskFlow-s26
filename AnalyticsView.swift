//
//  AnalyticsView.swift
//  Task_Flow
//
//  Created by Aravind Ganipisetty on 2/11/26.
//

import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        NavigationStack {
            List {
                Section("Tasks") {
                    let total = store.tasks.count
                    let done = store.tasks.filter { $0.isDone }.count
                    Text("Total: \(total)")
                    Text("Completed: \(done)")
                }
                Section("Notes") {
                    Text("Total notes: \(store.notes.count)")
                }
                Section("Work Hours") {
                    Text("Entries: \(store.workHours.count)")
                }
                Section("Goals") {
                    let avg = store.goals.isEmpty ? 0 : store.goals.map(\.progress).reduce(0,+) / Double(store.goals.count)
                    Text("Goals: \(store.goals.count)")
                    Text("Avg progress: \(Int(avg * 100))%")
                }
                Section("Habits") {
                    let best = store.habits.map(\.streak).max() ?? 0
                    Text("Habits: \(store.habits.count)")
                    Text("Best streak: \(best)")
                }
            }
            .navigationTitle("Analytics")
        }
    }
}

