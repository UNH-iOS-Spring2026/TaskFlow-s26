import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct DashboardView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var auth: AuthStore

    @State private var searchText = ""
    @State private var showAddTaskSheet = false
    @State private var showAddReminderSheet = false

    private var todayTasks: [TaskItem] {
        store.tasks.filter { Calendar.current.isDateInToday($0.createdAt) }
    }

    private var todayReminders: [ReminderItem] {
        store.reminders.filter { Calendar.current.isDateInToday($0.dueAt) }
    }

    private var completedTodayTasksCount: Int {
        todayTasks.filter { $0.isDone }.count
    }

    private var completedTodayRemindersCount: Int {
        todayReminders.filter { $0.isDone }.count
    }

    private var taskProgressText: String {
        guard !todayTasks.isEmpty else { return "0% complete" }
        let percent = Int((Double(completedTodayTasksCount) / Double(todayTasks.count)) * 100)
        return "\(percent)% complete"
    }

    private var reminderProgressText: String {
        guard !todayReminders.isEmpty else { return "0% complete" }
        let percent = Int((Double(completedTodayRemindersCount) / Double(todayReminders.count)) * 100)
        return "\(percent)% complete"
    }

    private var thisWeekHours: Double {
        let calendar = Calendar.current
        return store.workSessions
            .filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
            .reduce(0) { $0 + $1.hours }
    }

    private var thisMonthEarnings: Double {
        let calendar = Calendar.current
        return store.workSessions
            .filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + $1.earnings }
    }

    private var greetingTitle: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning!"
        case 12..<17: return "Good Afternoon!"
        default: return "Good Evening!"
        }
    }

    private var displayName: String {
        let email = auth.currentEmail ?? ""
        if email.isEmpty { return "User" }
        return email.components(separatedBy: "@").first ?? "User"
    }

    private var userInitial: String {
        String(displayName.prefix(1)).uppercased()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 8/255, green: 12/255, blue: 42/255),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

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
            }
            .sheet(isPresented: $showAddReminderSheet) {
                AddReminderDashboardSheet()
            }
        }
    }

    private var topBar: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))

                TextField("Search pages...", text: $searchText)
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.08))
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
                        .foregroundColor(.white)
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
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    private var greetingCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greetingTitle)
                .font(.system(size: 28, weight: .bold))

            Text("Here's your productivity snapshot for today")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.85),
                    Color.indigo.opacity(0.45),
                    Color.black.opacity(0.65)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

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
                background: Color(red: 78/255, green: 89/255, blue: 126/255)
            )

            statCard(
                title: "REMINDERS",
                value: "\(completedTodayRemindersCount)/\(todayReminders.count)",
                subtitle: reminderProgressText,
                background: Color(red: 92/255, green: 58/255, blue: 112/255)
            )

            statCard(
                title: "WORK HOURS",
                value: "\(String(format: "%.1f", thisWeekHours)) h",
                subtitle: "this week",
                background: Color(red: 95/255, green: 66/255, blue: 47/255)
            )

            statCard(
                title: "EARNINGS",
                value: "$\(String(format: "%.0f", thisMonthEarnings))",
                subtitle: "this month",
                background: Color(red: 37/255, green: 87/255, blue: 57/255)
            )
        }
    }

    private func statCard(title: String, value: String, subtitle: String, background: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.8))

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .padding(16)
        .background(background.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var bottomCards: some View {
        HStack(alignment: .top, spacing: 12) {
            todayTasksCard
            todayRemindersCard
        }
    }

    private var todayTasksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Today's Tasks")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)

                Spacer()

                Button {
                    showAddTaskSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            if todayTasks.isEmpty {
                Text("No tasks for today. Add one and get moving.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.75))
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
                                    .foregroundColor(task.isDone ? .green : .white.opacity(0.7))
                            }
                            .buttonStyle(.plain)

                            Text(task.title)
                                .font(.title3)
                                .foregroundColor(.white)
                                .strikethrough(task.isDone, color: .white.opacity(0.7))
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
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var todayRemindersCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Today's Reminders")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)

                Spacer()

                Button {
                    showAddReminderSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            if todayReminders.isEmpty {
                Text("No reminders for today. Enjoy your day!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.75))
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
                                    .foregroundColor(reminder.isDone ? .green : .white.opacity(0.7))
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(reminder.title)
                                    .font(.title3)
                                    .foregroundColor(.white)

                                Text(reminder.dueAt.formatted(date: .omitted, time: .shortened))
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.65))
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
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct AddTaskDashboardSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""

    private let db = Firestore.firestore()

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
                        saveTask()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveTask() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("TASK SAVE ERROR: No Firebase user")
            return
        }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }

        let id = UUID().uuidString.uppercased()

        db.collection("taskflowData")
            .document(uid)
            .collection("tasks")
            .document(id)
            .setData([
                "title": cleanTitle,
                "isDone": false,
                "createdAt": Timestamp(date: Date())
            ]) { error in
                if let error {
                    print("TASK FIREBASE ERROR:", error.localizedDescription)
                } else {
                    print("TASK SAVED FIREBASE:", id)
                    dismiss()
                }
            }
    }
}

struct AddReminderDashboardSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var dueAt = Date()

    private let db = Firestore.firestore()

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
                        saveReminder()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveReminder() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("REMINDER SAVE ERROR: No Firebase user")
            return
        }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }

        let id = UUID().uuidString.uppercased()

        db.collection("taskflowData")
            .document(uid)
            .collection("reminders")
            .document(id)
            .setData([
                "title": cleanTitle,
                "dueAt": Timestamp(date: dueAt),
                "isDone": false,
                "createdAt": Timestamp(date: Date())
            ]) { error in
                if let error {
                    print("REMINDER FIREBASE ERROR:", error.localizedDescription)
                } else {
                    print("REMINDER SAVED FIREBASE:", id)
                    dismiss()
                }
            }
    }
}
