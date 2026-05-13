//
//  MainTabView.swift
//  Task_Flow

import SwiftUI

// Main tab navigation for the Task Flow app.
struct MainTabView: View {
    @AppStorage("tf_dark_mode") private var darkMode = false

    // MARK: - Body

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            NotesView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }

            WorkHoursView()
                .tabItem {
                    Label("Work", systemImage: "clock")
                }

            GoalsView()
                .tabItem {
                    Label("Goals", systemImage: "target")
                }

            HabitsView()
                .tabItem {
                    Label("Habits", systemImage: "flame")
                }

            FocusView()
                .tabItem {
                    Label("Focus", systemImage: "timer")
                }

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar")
                }

            VaultView()
                .tabItem {
                    Label("Vault", systemImage: "lock")
                }

            LocationRemindersView()
                .tabItem {
                    Label("Location Reminders", systemImage: "location.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        // Applies the selected app theme across all tabs.
        .preferredColorScheme(darkMode ? .dark : .light)

        // Sets the selected tab color.
        .tint(.blue)
    }
}
