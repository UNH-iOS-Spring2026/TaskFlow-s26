import SwiftUI

// This view shows analytics data
struct AnalyticsView: View {
    
    // Getting shared data from AppStore
    @EnvironmentObject var store: AppStore

    var body: some View {
        NavigationStack {
            List {
                
                // Tasks section
                Section("Tasks") {
                    // Total tasks count
                    Text("Total: \(store.tasks.count)")
                    
                    // Completed tasks count
                    Text("Completed: \(store.tasks.filter { $0.isDone }.count)")
                }

                // Notes section
                Section("Notes") {
                    // Total notes count
                    Text("Total notes: \(store.notes.count)")
                }

                // Reminders section
                Section("Reminders") {
                    // Total reminders count
                    Text("Total reminders: \(store.reminders.count)")
                    
                    // Completed reminders count
                    Text("Completed: \(store.reminders.filter { $0.isDone }.count)")
                }

                // Work hours section
                Section("Work Hours") {
                    
                    // Add all work hours
                    let totalHours = store.workSessions.reduce(0.0) { $0 + $1.hours }
                    
                    // Add all earnings
                    let totalEarnings = store.workSessions.reduce(0.0) { $0 + $1.earnings }

                    // Total sessions count
                    Text("Sessions: \(store.workSessions.count)")
                    
                    // Show total hours
                    Text("Total hours: \(String(format: "%.1f", totalHours))h")
                    
                    // Show total earnings
                    Text("Total earnings: $\(String(format: "%.2f", totalEarnings))")
                }

                // Expenses section
                Section("Expenses") {
                    
                    // Add all expenses
                    let totalSpent = store.expenses.reduce(0.0) { $0 + $1.amount }

                    // Total expense entries
                    Text("Entries: \(store.expenses.count)")
                    
                    // Show total spent
                    Text("Total spent: $\(String(format: "%.2f", totalSpent))")
                }

                // Goals section
                Section("Goals") {
                    // Total goals count
                    Text("Goals: \(store.goalRecords.count)")
                }

                // Habits section
                Section("Habits") {
                    // Total habits count
                    Text("Habits: \(store.habits.count)")
                    
                    // Best streak value
                    Text("Best streak: \(store.habits.map(\.streak).max() ?? 0)")
                }
            }
            // Title at top
            .navigationTitle("Analytics")
        }
    }
}
