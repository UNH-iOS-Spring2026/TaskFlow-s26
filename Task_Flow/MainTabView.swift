import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "house") }

            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            NotesView()
                .tabItem { Label("Notes", systemImage: "note.text") }

            WorkHoursView()
                .tabItem { Label("Work", systemImage: "clock") }

            GoalsView()
                .tabItem { Label("Goals", systemImage: "target") }

            HabitsView()
                .tabItem { Label("Habits", systemImage: "flame") }

            FocusView()
                .tabItem { Label("Focus", systemImage: "timer") }

            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: "chart.bar") }

            VaultView()
                .tabItem { Label("Vault", systemImage: "lock") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }   // ✅ NEW
        }
    }
}
