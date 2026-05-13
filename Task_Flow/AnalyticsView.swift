//  Task_Flow
//
//  Created by Aravind Ganipisetty on 2/11/26.

import SwiftUI


//
//  Displays a simple summary dashboard for the user's saved productivity data.
//  This screen pulls data from AppStore and calculates totals for tasks, notes,
//  reminders, work sessions, expenses, goals, and habits.

struct AnalyticsView: View {
    @EnvironmentObject var store: AppStore
    @AppStorage("tf_dark_mode") private var darkMode = false

    var body: some View {
        NavigationStack {
            ZStack {
                background

                // A grouped list is used here because analytics are separated
                // by feature area, making the summary easier to read quickly.
                List {
                    Section("Tasks") {
                        row("Total", "\(store.tasks.count)")
                        row("Completed", "\(store.tasks.filter { $0.isDone }.count)")
                    }

                    Section("Notes") {
                        row("Total notes", "\(store.notes.count)")
                    }

                    Section("Reminders") {
                        row("Total reminders", "\(store.reminders.count)")
                        row("Completed", "\(store.reminders.filter { $0.isDone }.count)")
                    }

                    Section("Work Hours") {
                        // Work session totals are calculated from all saved sessions.
                        // This gives the user a quick view of time worked and earnings.
                        let totalHours = store.workSessions.reduce(0.0) { $0 + $1.hours }
                        let totalEarnings = store.workSessions.reduce(0.0) { $0 + $1.earnings }

                        row("Sessions", "\(store.workSessions.count)")
                        row("Total hours", "\(String(format: "%.1f", totalHours))h")
                        row("Total earnings", "$\(String(format: "%.2f", totalEarnings))")
                    }

                    Section("Expenses") {
                        // Adds all expense entries to show the user's total spending.
                        let totalSpent = store.expenses.reduce(0.0) { $0 + $1.amount }

                        row("Entries", "\(store.expenses.count)")
                        row("Total spent", "$\(String(format: "%.2f", totalSpent))")
                    }

                    Section("Goals") {
                        row("Goals", "\(store.goalRecords.count)")
                    }

                    Section("Habits") {
                        // The best streak helps the user see their strongest habit progress.
                        let bestStreak = store.habits.map(\.streak).max() ?? 0

                        row("Habits", "\(store.habits.count)")
                        row("Best streak", "\(bestStreak)")
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Analytics")
            .toolbarBackground(darkMode ? Color.black : Color.white, for: .navigationBar)
            .toolbarColorScheme(darkMode ? .dark : .light, for: .navigationBar)
        }
    }

    // MARK: - Background

    // Provides a consistent app background that supports both light and dark mode.
    // The gradient keeps the Analytics screen visually aligned with the rest of Task Flow.
    private var background: some View {
        LinearGradient(
            colors: darkMode
            ? [
                Color.black,
                Color(red: 8/255, green: 12/255, blue: 42/255),
                Color.black
            ]
            : [
                Color(red: 0.96, green: 0.97, blue: 1.00),
                Color.white
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Theme Colors

    // List row background changes based on the selected app theme.
    private var rowBackground: Color {
        darkMode ? Color.white.opacity(0.08) : Color.white
    }

    // Primary text color used for row titles.
    private var primaryText: Color {
        darkMode ? .white : .black
    }

    // Secondary text color used for calculated values.
    private var secondaryText: Color {
        darkMode ? .white.opacity(0.7) : .black.opacity(0.55)
    }

    // MARK: - Reusable Row

    // Creates a reusable analytics row with a title on the left and a value on the right.
    // Using one helper keeps every section visually consistent and avoids repeated layout code.
    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(primaryText)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(secondaryText)
        }
        .listRowBackground(rowBackground)
    }
}
