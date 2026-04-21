//
//  AnalyticsView.swift
//  Task_Flow
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

                Section("Reminders") {
                    let total = store.reminders.count
                    let done = store.reminders.filter { $0.isDone }.count
                    let pending = total - done

                    Text("Total reminders: \(total)")
                    Text("Pending: \(pending)")
                    Text("Completed: \(done)")
                }

                Section("Work Hours") {
                    let totalSessions = store.workSessions.count
                    let totalHours = store.workSessions.reduce(0.0) { $0 + $1.hours }
                    let totalEarnings = store.workSessions.reduce(0.0) { $0 + $1.earnings }

                    Text("Sessions: \(totalSessions)")
                    Text("Total hours: \(String(format: "%.1f", totalHours))h")
                    Text("Total earnings: \(money(totalEarnings))")
                }

                Section("Expenses") {
                    let totalExpenses = store.expenses.count
                    let totalSpent = store.expenses.reduce(0.0) { $0 + $1.amount }

                    Text("Entries: \(totalExpenses)")
                    Text("Total spent: \(money(totalSpent))")
                }

                Section("Goals") {
                    Text("Goals: \(store.goalRecords.count)")
                }

                Section("Habits") {
                    let best = store.habits.map(\.streak).max() ?? 0
                    let completedToday = store.habits.filter { $0.isCompletedToday }.count

                    Text("Habits: \(store.habits.count)")
                    Text("Completed today: \(completedToday)")
                    Text("Best streak: \(best)")
                }
            }
            .navigationTitle("Analytics")
        }
    }

    private func money(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

#Preview {
    let auth = AuthStore()
    let store = AppStore(auth: auth)

    return AnalyticsView()
        .environmentObject(store)
}
