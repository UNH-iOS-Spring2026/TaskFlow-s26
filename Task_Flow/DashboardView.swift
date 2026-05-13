//
//  DashboardView.swift
//  Task_Flow
//
//  Created by Aravind Ganipisetty
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var auth: AuthStore

    @AppStorage("tf_dark_mode") private var darkMode = false

    // MARK: - View State

    // Stores text entered in the search field.
    @State private var searchText = ""

    // Controls the task creation sheet.
    @State private var showAddTaskSheet = false

    // Controls the reminder creation sheet.
    @State private var showAddReminderSheet = false

    // MARK: - Today Data

    // Filters tasks created today for the dashboard summary.
    private var todayTasks: [TaskItem] {
        store.tasks.filter { Calendar.current.isDateInToday($0.createdAt) }
    }

    // Filters reminders due today for the dashboard summary.
    private var todayReminders: [ReminderItem] {
        store.reminders.filter { Calendar.current.isDateInToday($0.dueAt) }
    }

    // Counts completed tasks for today.
    private var completedTodayTasksCount: Int {
        todayTasks.filter { $0.isDone }.count
    }

    // Counts completed reminders for today.
    private var completedTodayRemindersCount: Int {
        todayReminders.filter { $0.isDone }.count
    }

    // Shows today's task completion percentage.
    private var taskProgressText: String {
        guard !todayTasks.isEmpty else {
            return "0% complete"
        }

        let percent = Int((Double(completedTodayTasksCount) / Double(todayTasks.count)) * 100)
        return "\(percent)% complete"
    }

    // Shows today's reminder completion percentage.
    private var reminderProgressText: String {
        guard !todayReminders.isEmpty else {
            return "0% complete"
        }

        let percent = Int((Double(completedTodayRemindersCount) / Double(todayReminders.count)) * 100)
        return "\(percent)% complete"
    }

    // MARK: - Work Summary

    // Calculates total work hours for the current week.
    private var thisWeekHours: Double {
        let calendar = Calendar.current

        return store.workSessions
            .filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
            .reduce(0) { $0 + $1.hours }
    }

    // Calculates total earnings for the current month.
    private var thisMonthEarnings: Double {
        let calendar = Calendar.current

        return store.workSessions
            .filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + $1.earnings }
    }

    // MARK: - User Display

    // Changes greeting based on the current time of day.
    private var greetingTitle: String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<12:
            return "Good Morning!"
        case 12..<17:
            return "Good Afternoon!"
        default:
            return "Good Evening!"
        }
    }

    // Uses the email prefix as a simple display name.
    private var displayName: String {
        let email = auth.currentEmail ?? ""

        if email.isEmpty {
            return "User"
        }

        return email.components(separatedBy: "@").first ?? "User"
    }

    // First letter shown inside the profile circle.
    private var userInitial: String {
        String(displayName.prefix(1)).uppercased()
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                background

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        topBar
                        greetingCard
                        statsGrid
                        bottomCards
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddTaskSheet) {
                AddTaskDashboardSheet()
                    .environmentObject(store)
                    .preferredColorScheme(darkMode ? .dark : .light)
            }
            .sheet(isPresented: $showAddReminderSheet) {
                AddReminderDashboardSheet()
                    .environmentObject(store)
                    .preferredColorScheme(darkMode ? .dark : .light)
            }
        }
    }

    // MARK: - Top Bar

    // Contains the search field, user avatar, display name, and logout button.
    private var topBar: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(secondaryText)

                TextField("Search pages...", text: $searchText)
                    .foregroundColor(primaryText)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(cardFill)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 38, height: 38)

                        Text(userInitial)
                            .font(.headline.bold())
                            .foregroundColor(.white)
                    }

                    Text(displayName)
                        .font(.headline)
                        .foregroundColor(primaryText)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    auth.logout()
                } label: {
                    Text("Logout")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(cardFill)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    // MARK: - Greeting Card

    // Shows a friendly greeting and short productivity message.
    private var greetingCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greetingTitle)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("Here's your productivity snapshot for today")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.82))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: darkMode
                ? [
                    Color.purple.opacity(0.85),
                    Color.indigo.opacity(0.45),
                    Color.black.opacity(0.65)
                ]
                : [
                    Color.purple.opacity(0.82),
                    Color.blue.opacity(0.58),
                    Color.pink.opacity(0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Stats Grid

    // Displays the main dashboard summary cards.
    private var statsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            statCard(
                title: "TODAY'S TASKS",
                value: "\(completedTodayTasksCount)/\(todayTasks.count)",
                subtitle: taskProgressText,
                background: darkMode ? Color(red: 78/255, green: 89/255, blue: 126/255) : Color(red: 0.85, green: 0.90, blue: 1.00)
            )

            statCard(
                title: "REMINDERS",
                value: "\(completedTodayRemindersCount)/\(todayReminders.count)",
                subtitle: reminderProgressText,
                background: darkMode ? Color(red: 92/255, green: 58/255, blue: 112/255) : Color(red: 0.94, green: 0.86, blue: 1.00)
            )

            statCard(
                title: "WORK HOURS",
                value: "\(String(format: "%.1f", thisWeekHours)) h",
                subtitle: "this week",
                background: darkMode ? Color(red: 95/255, green: 66/255, blue: 47/255) : Color(red: 1.00, green: 0.90, blue: 0.78)
            )

            statCard(
                title: "EARNINGS",
                value: "$\(String(format: "%.0f", thisMonthEarnings))",
                subtitle: "this month",
                background: darkMode ? Color(red: 37/255, green: 87/255, blue: 57/255) : Color(red: 0.82, green: 0.95, blue: 0.86)
            )
        }
    }

    // MARK: - Stat Card

    // Reusable dashboard card used for tasks, reminders, work hours, and earnings.
    private func statCard(title: String, value: String, subtitle: String, background: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(darkMode ? .white.opacity(0.8) : .black.opacity(0.62))

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(darkMode ? .white : .black)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(darkMode ? .white.opacity(0.75) : .black.opacity(0.58))
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .padding(16)
        .background(background.opacity(darkMode ? 0.9 : 1.0))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Bottom Cards

    // Shows today's tasks and today's reminders side by side.
    private var bottomCards: some View {
        HStack(alignment: .top, spacing: 12) {
            todayTasksCard
            todayRemindersCard
        }
    }

    // MARK: - Today's Tasks Card

    // Displays today's tasks and gives quick actions to add, complete, or delete tasks.
    private var todayTasksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Today's Tasks")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(primaryText)

                Spacer()

                Button {
                    showAddTaskSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.bold())
                        .foregroundColor(primaryText)
                        .frame(width: 36, height: 36)
                        .background(buttonFill)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            if todayTasks.isEmpty {
                Text("No tasks for today. Add one and get moving.")
                    .font(.subheadline)
                    .foregroundColor(secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 130)
            } else {
                VStack(spacing: 12) {
                    ForEach(todayTasks) { task in
                        HStack(spacing: 10) {
                            Button {
                                store.toggleTask(task)
                            } label: {
                                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundColor(task.isDone ? .green : secondaryText)
                            }
                            .buttonStyle(.plain)

                            Text(task.title)
                                .font(.title3)
                                .foregroundColor(primaryText)
                                .strikethrough(task.isDone, color: secondaryText)
                                .lineLimit(1)

                            Spacer()

                            Button {
                                store.deleteTask(task)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .font(.headline)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Today's Reminders Card

    // Displays today's reminders and gives quick actions to add, complete, or delete reminders.
    private var todayRemindersCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Today's Reminders")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(primaryText)

                Spacer()

                Button {
                    showAddReminderSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.bold())
                        .foregroundColor(primaryText)
                        .frame(width: 36, height: 36)
                        .background(buttonFill)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            if todayReminders.isEmpty {
                Text("No reminders for today. Enjoy your day!")
                    .font(.subheadline)
                    .foregroundColor(secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 130)
            } else {
                VStack(spacing: 12) {
                    ForEach(todayReminders) { reminder in
                        HStack(spacing: 10) {
                            Button {
                                store.toggleReminder(reminder)
                            } label: {
                                Image(systemName: reminder.isDone ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundColor(reminder.isDone ? .green : secondaryText)
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(reminder.title)
                                    .font(.title3)
                                    .foregroundColor(primaryText)

                                Text(reminder.dueAt.formatted(date: .omitted, time: .shortened))
                                    .font(.subheadline)
                                    .foregroundColor(secondaryText)
                            }

                            Spacer()

                            Button {
                                store.deleteReminder(reminder)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .font(.headline)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Theme

    // Main dashboard background for light and dark mode.
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
                Color.white,
                Color(red: 0.91, green: 0.94, blue: 1.00)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // Main text color based on the current app theme.
    private var primaryText: Color {
        darkMode ? .white : .black
    }

    // Secondary text color used for subtitles and empty states.
    private var secondaryText: Color {
        darkMode ? .white.opacity(0.65) : .black.opacity(0.58)
    }

    // Card background color used across dashboard sections.
    private var cardFill: Color {
        darkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.92)
    }

    // Small button background color.
    private var buttonFill: Color {
        darkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.06)
    }
}

// MARK: - Add Task Sheet

// Sheet used to add a new task directly from the dashboard.
struct AddTaskDashboardSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    // Stores the task title entered by the user.
    @State private var title = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Task title", text: $title)
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        store.addTask(title: cleanTitle)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Add Reminder Sheet

// Sheet used to add a new reminder directly from the dashboard.
struct AddReminderDashboardSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    // Stores the reminder title entered by the user.
    @State private var title = ""

    // Stores the selected reminder date and time.
    @State private var dueAt = Date()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Reminder title", text: $title)

                DatePicker(
                    "Due time",
                    selection: $dueAt,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
            .navigationTitle("New Reminder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        store.addReminder(title: cleanTitle, dueAt: dueAt)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
