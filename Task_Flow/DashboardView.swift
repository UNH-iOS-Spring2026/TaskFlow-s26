import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: AppStore

    @State private var search = ""
    @State private var showAddTask = false
    @State private var showAddReminder = false

    var body: some View {
        NavigationStack {
            ZStack {
                background

                ScrollView {
                    VStack(spacing: 16) {

                        topBar
                            .padding(.top, 8)

                        heroCard

                        statCards

                        bigPanels

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddTask) { AddTaskSheet() }
            .sheet(isPresented: $showAddReminder) { AddReminderSheet() }
        }
    }

    // MARK: - Background
    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.07, blue: 0.12),
                Color(red: 0.10, green: 0.10, blue: 0.18),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Top Bar
    private var topBar: some View {
        VStack(spacing: 10) {
            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search pages…", text: $search)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            // Profile + Logout
            HStack(spacing: 10) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(Color.purple.opacity(0.9))
                        Text(initials)
                            .foregroundStyle(.white)
                            .font(.headline)
                    }
                    .frame(width: 34, height: 34)

                    Text(displayName)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Spacer()

                Button(action: { store.auth.logout() }) {
                    Text("Logout")
                        .font(.headline)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    // MARK: - Hero
    private var heroCard: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.55))
                .overlay(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.55), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                )

            VStack(alignment: .leading, spacing: 6) {
                Text("\(greeting)!")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color.purple.opacity(0.92))

                Text("Here's your productivity snapshot for today")
                    .foregroundStyle(.white.opacity(0.8))
                    .font(.subheadline)
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 130)
    }

    // MARK: - Stat Cards (2x2 grid)
    private var statCards: some View {
        let taskTotal = todaysTasks.count
        let taskDone = todaysTasksDone

        let remTotal = todaysReminders.count
        let remDone = todaysRemindersDone

        let items: [(String, String, String, Color)] = [
            ("TODAY'S TASKS",
             "\(taskDone)/\(taskTotal)",
             percentText(done: taskDone, total: taskTotal),
             Color(red: 0.55, green: 0.70, blue: 1.0).opacity(0.22)),

            ("REMINDERS",
             "\(remDone)/\(remTotal)",
             percentText(done: remDone, total: remTotal),
             Color.purple.opacity(0.18)),

            ("WORK HOURS",
             "\(String(format: "%.1f", workHoursThisWeek)) h",
             "this week",
             Color.orange.opacity(0.18)),

            ("EARNINGS",
             "$\(earningsThisMonth)",
             "this month",
             Color.green.opacity(0.18))
        ]

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(items.indices, id: \.self) { i in
                statCard(title: items[i].0, big: items[i].1, small: items[i].2, tint: items[i].3)
            }
        }
    }

    private func statCard(title: String, big: String, small: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(big)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.70)

            Text(small)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.70))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .background(tint)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Big Panels
    private var bigPanels: some View {
        HStack(spacing: 12) {
            bigPanel(
                title: "Today's Todos",
                emptyText: "No todos yet. Great way to start the day!",
                action: { showAddTask = true }
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(todaysTasks.prefix(6)) { t in
                        HStack(spacing: 10) {
                            Image(systemName: t.isDone ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(t.isDone ? .green : .white.opacity(0.55))
                                .onTapGesture { toggleTask(t) }

                            Text(t.title)
                                .foregroundStyle(.white)
                                .lineLimit(1)

                            Spacer()
                        }
                    }
                }
            }

            bigPanel(
                title: "Today's Reminders",
                emptyText: "No reminders for today. Enjoy your day!",
                action: { showAddReminder = true }
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(todaysReminders.prefix(6)) { r in
                        HStack(spacing: 10) {
                            Image(systemName: r.isDone ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(r.isDone ? .green : .white.opacity(0.55))
                                .onTapGesture { toggleReminder(r) }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(r.title)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)

                                Text(r.dueAt.formatted(date: .omitted, time: .shortened))
                                    .font(.footnote)
                                    .foregroundStyle(.white.opacity(0.65))
                            }

                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private func bigPanel<Content: View>(
        title: String,
        emptyText: String,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                Button(action: action) {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }

            if (title.contains("Todos") ? todaysTasks.isEmpty : todaysReminders.isEmpty) {
                Text(emptyText)
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(maxWidth: .infinity, minHeight: 150, alignment: .center)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
            } else {
                content()
                    .padding(.top, 6)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 260, alignment: .topLeading)
        .background(Color.white.opacity(0.06))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Helpers / Data
    private var displayName: String {
        if let email = store.auth.currentEmail, !email.isEmpty {
            return email.components(separatedBy: "@").first ?? "User"
        }
        return "ar"
    }

    private var initials: String {
        let parts = displayName.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].first ?? "A")\(parts[1].first ?? "R")".uppercased()
        }
        return String(displayName.prefix(1)).uppercased()
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning" }
        if hour < 18 { return "Good Afternoon" }
        return "Good Evening"
    }

    private var todaysTasks: [TaskItem] {
        store.tasks.filter { Calendar.current.isDateInToday($0.createdAt) }
    }

    private var todaysTasksDone: Int {
        todaysTasks.filter { $0.isDone }.count
    }

    private var todaysReminders: [ReminderItem] {
        store.reminders.filter { Calendar.current.isDateInToday($0.dueAt) }
    }

    private var todaysRemindersDone: Int {
        todaysReminders.filter { $0.isDone }.count
    }

    private var workHoursThisWeek: Double {
        let cal = Calendar.current
        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: Date())?.start else { return 0 }
        let entries = store.workHours.filter { $0.date >= weekStart }
        let seconds = entries.reduce(0.0) { acc, e in
            let raw = e.endTime.timeIntervalSince(e.startTime)
            let breakSec = Double(e.breakMinutes) * 60.0
            return acc + max(0, raw - breakSec)
        }
        return seconds / 3600.0
    }

    private var earningsThisMonth: Int {
        // Keep $0 for now (same as your web screenshot). Wire later if you want hourly rate.
        return 0
    }

    private func percentText(done: Int, total: Int) -> String {
        guard total > 0 else { return "0% complete" }
        let p = Int((Double(done) / Double(total)) * 100.0)
        return "\(p)% complete"
    }

    // MARK: - Actions
    private func toggleTask(_ task: TaskItem) {
        guard let i = store.tasks.firstIndex(of: task) else { return }
        store.tasks[i].isDone.toggle()
        store.saveAll()
    }

    private func toggleReminder(_ r: ReminderItem) {
        guard let i = store.reminders.firstIndex(of: r) else { return }
        store.reminders[i].isDone.toggle()
        store.saveAll()
    }
}

// MARK: - Sheets

struct AddTaskSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    @State private var title = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Task title", text: $title)
            }
            .navigationTitle("Add Task")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !t.isEmpty else { return }

                        // ✅ Force newly created tasks to NOT be completed
                        let newTask = TaskItem(title: t, isDone: false, createdAt: Date())

                        store.tasks.insert(newTask, at: 0)
                        store.saveAll()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AddReminderSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var dueAt = Date()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Reminder title", text: $title)
                DatePicker("Time", selection: $dueAt, displayedComponents: [.date, .hourAndMinute])
            }
            .navigationTitle("Add Reminder")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !t.isEmpty else { return }

                        let newReminder = ReminderItem(title: t, dueAt: dueAt, isDone: false, createdAt: Date())

                        store.reminders.insert(newReminder, at: 0)
                        store.saveAll()
                        dismiss()
                    }
                }
            }
        }
    }
}
