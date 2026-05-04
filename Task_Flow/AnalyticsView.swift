import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        NavigationStack {
            List {
                Section("Tasks") {
                    Text("Total: \(store.tasks.count)")
                    Text("Completed: \(store.tasks.filter { $0.isDone }.count)")
                }

                Section("Notes") {
                    Text("Total notes: \(store.notes.count)")
                }

                Section("Reminders") {
                    Text("Total reminders: \(store.reminders.count)")
                    Text("Completed: \(store.reminders.filter { $0.isDone }.count)")
                }

                Section("Work Hours") {
                    let totalHours = store.workSessions.reduce(0.0) { $0 + $1.hours }
                    let totalEarnings = store.workSessions.reduce(0.0) { $0 + $1.earnings }

                    Text("Sessions: \(store.workSessions.count)")
                    Text("Total hours: \(String(format: "%.1f", totalHours))h")
                    Text("Total earnings: $\(String(format: "%.2f", totalEarnings))")
                }

                Section("Expenses") {
                    let totalSpent = store.expenses.reduce(0.0) { $0 + $1.amount }

                    Text("Entries: \(store.expenses.count)")
                    Text("Total spent: $\(String(format: "%.2f", totalSpent))")
                }

                Section("Goals") {
                    Text("Goals: \(store.goalRecords.count)")
                }

                Section("Habits") {
                    Text("Habits: \(store.habits.count)")
                    Text("Best streak: \(store.habits.map(\.streak).max() ?? 0)")
                }
            }
            .navigationTitle("Analytics")
        }
    }
}
