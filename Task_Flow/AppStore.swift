//
//  AppStore.swift
//  Task_Flow
//
//  Central data manager for Task Flow.
//  This file connects the app with Firebase Firestore and keeps user data synced.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

final class AppStore: ObservableObject {

    // MARK: - Published App Data

    // Notes created by the logged-in user.
    @Published var notes: [NoteItem] = []

    // Reminders include normal deadline reminders and location-based reminders.
    @Published var reminders: [ReminderItem] = []

    // Tasks shown on the dashboard.
    @Published var tasks: [TaskItem] = []

    // Work sessions used to calculate total hours and earnings.
    @Published var workSessions: [WorkSessionRecord] = []

    // Expense records used for spending tracking.
    @Published var expenses: [ExpenseRecord] = []

    // Goal records created by the user.
    @Published var goalRecords: [GoalRecord] = []

    // Habit records with streak tracking.
    @Published var habits: [HabitItem] = []

    // MARK: - Firebase and Authentication

    // AuthStore gives access to the current user's UID and email.
    private let auth: AuthStore

    // Firestore database instance used for all cloud reads and writes.
    private let db = Firestore.firestore()

    // Stores Combine subscriptions, mainly for tracking authentication changes.
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Firestore Listener References

    // Listener references are stored so they can be removed during logout or account change.
    private var notesListener: ListenerRegistration?
    private var remindersListener: ListenerRegistration?
    private var tasksListener: ListenerRegistration?
    private var workSessionsListener: ListenerRegistration?
    private var expensesListener: ListenerRegistration?
    private var goalsListener: ListenerRegistration?
    private var habitsListener: ListenerRegistration?

    // MARK: - Initialization

    init(auth: AuthStore) {
        self.auth = auth

        // Whenever the logged-in user changes, reload Firestore listeners for that user.
        auth.$currentUserId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] uid in
                self?.setupUser(uid)
            }
            .store(in: &cancellables)

        // Loads data immediately if the user is already signed in.
        setupUser(auth.currentUserId)
    }

    deinit {
        removeListeners()
    }

    // MARK: - User Setup

    // Prepares Firestore storage and listeners for the current user.
    private func setupUser(_ uid: String?) {
        removeListeners()

        guard let uid, !uid.isEmpty else {
            clearAllData()
            return
        }

        print("APPSTORE USING UID:", uid)

        // Creates or updates the parent user document in Firestore.
        db.collection("taskflowData").document(uid).setData([
            "uid": uid,
            "email": auth.currentEmail ?? "",
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true) { error in
            if let error {
                print("USER DOCUMENT ERROR:", error.localizedDescription)
            }
        }

        // Start real-time listeners for every feature in the app.
        listenNotes(uid)
        listenReminders(uid)
        listenTasks(uid)
        listenWorkSessions(uid)
        listenExpenses(uid)
        listenGoals(uid)
        listenHabits(uid)
    }

    // Clears local data when the user is logged out.
    private func clearAllData() {
        notes = []
        reminders = []
        tasks = []
        workSessions = []
        expenses = []
        goalRecords = []
        habits = []
    }

    // Removes all active Firestore listeners to avoid duplicate updates.
    private func removeListeners() {
        notesListener?.remove()
        remindersListener?.remove()
        tasksListener?.remove()
        workSessionsListener?.remove()
        expensesListener?.remove()
        goalsListener?.remove()
        habitsListener?.remove()

        notesListener = nil
        remindersListener = nil
        tasksListener = nil
        workSessionsListener = nil
        expensesListener = nil
        goalsListener = nil
        habitsListener = nil
    }

    // Returns the current Firebase user ID before reading or writing Firestore data.
    private func currentUID() -> String? {
        guard let uid = auth.currentUserId, !uid.isEmpty else {
            print("FIREBASE SAVE ERROR: No logged-in user UID")
            return nil
        }

        return uid
    }

    // MARK: - Firestore Path Helpers

    // Returns a feature collection under the logged-in user's Firestore document.
    private func col(_ name: String, _ uid: String) -> CollectionReference {
        db.collection("taskflowData").document(uid).collection(name)
    }

    // Returns a document reference using the model UUID as the Firestore document ID.
    private func doc(_ name: String, _ uid: String, _ id: UUID) -> DocumentReference {
        col(name, uid).document(id.uuidString.uppercased())
    }

    // MARK: - Firestore Value Readers

    // Safely converts Firestore Timestamp values into Swift Date values.
    private func readDate(_ data: [String: Any], _ key: String, fallback: Date = Date()) -> Date {
        if let timestamp = data[key] as? Timestamp {
            return timestamp.dateValue()
        }

        if let date = data[key] as? Date {
            return date
        }

        return fallback
    }

    // Safely reads numeric Firestore values as Double.
    private func readDouble(_ data: [String: Any], _ key: String, fallback: Double = 0) -> Double {
        if let value = data[key] as? Double {
            return value
        }

        if let value = data[key] as? Int {
            return Double(value)
        }

        if let value = data[key] as? NSNumber {
            return value.doubleValue
        }

        return fallback
    }

    // Safely reads numeric Firestore values as Int.
    private func readInt(_ data: [String: Any], _ key: String, fallback: Int = 0) -> Int {
        if let value = data[key] as? Int {
            return value
        }

        if let value = data[key] as? NSNumber {
            return value.intValue
        }

        return fallback
    }

    // MARK: - Real-Time Firestore Listeners

    // Loads and continuously updates notes from Firestore.
    private func listenNotes(_ uid: String) {
        notesListener = col("notes", uid).addSnapshotListener { [weak self] snap, error in
            if let error {
                print("NOTES LISTENER ERROR:", error.localizedDescription)
                return
            }

            let documents = snap?.documents.filter { $0.documentID != "_init" } ?? []

            DispatchQueue.main.async {
                self?.notes = documents.map { doc in
                    let d = doc.data()

                    return NoteItem(
                        id: UUID(uuidString: doc.documentID) ?? UUID(),
                        title: d["title"] as? String ?? "",
                        body: d["body"] as? String ?? "",
                        createdAt: self?.readDate(d, "createdAt") ?? Date(),
                        colorSeed: d["colorSeed"] as? Int ?? 0
                    )
                }
                .sorted { $0.createdAt > $1.createdAt }
            }
        }
    }

    // Loads reminders from Firestore, including deadline and location reminder fields.
    private func listenReminders(_ uid: String) {
        remindersListener = col("reminders", uid).addSnapshotListener { [weak self] snap, error in
            if let error {
                print("REMINDERS LISTENER ERROR:", error.localizedDescription)
                return
            }

            let documents = snap?.documents.filter { $0.documentID != "_init" } ?? []

            DispatchQueue.main.async {
                let loaded = documents.map { doc in
                    let d = doc.data()

                    return ReminderItem(
                        id: UUID(uuidString: doc.documentID) ?? UUID(),
                        title: d["title"] as? String ?? "",
                        dueAt: self?.readDate(d, "dueAt") ?? Date(),
                        isDone: d["isDone"] as? Bool ?? false,
                        createdAt: self?.readDate(d, "createdAt") ?? Date(),

                        // Location-based reminder fields for Core Location support.
                        locationName: d["locationName"] as? String,
                        latitude: self?.readDouble(d, "latitude", fallback: 0),
                        longitude: self?.readDouble(d, "longitude", fallback: 0),
                        radiusMeters: self?.readDouble(d, "radiusMeters", fallback: 150) ?? 150,
                        notifyOnEntry: d["notifyOnEntry"] as? Bool ?? true,
                        notifyOnExit: d["notifyOnExit"] as? Bool ?? false
                    )
                }
                .map { reminder in
                    // Old reminders without location data should not become fake 0,0 location reminders.
                    if reminder.latitude == 0 && reminder.longitude == 0 && reminder.locationName == nil {
                        var fixed = reminder
                        fixed.latitude = nil
                        fixed.longitude = nil
                        return fixed
                    }

                    return reminder
                }
                .sorted { $0.dueAt < $1.dueAt }

                self?.reminders = loaded
            }
        }
    }

    // Loads dashboard tasks from Firestore.
    private func listenTasks(_ uid: String) {
        tasksListener = col("tasks", uid).addSnapshotListener { [weak self] snap, error in
            if let error {
                print("TASKS LISTENER ERROR:", error.localizedDescription)
                return
            }

            let documents = snap?.documents.filter { $0.documentID != "_init" } ?? []

            DispatchQueue.main.async {
                self?.tasks = documents.map { doc in
                    let d = doc.data()

                    return TaskItem(
                        id: UUID(uuidString: doc.documentID) ?? UUID(),
                        title: d["title"] as? String ?? "",
                        isDone: d["isDone"] as? Bool ?? false,
                        createdAt: self?.readDate(d, "createdAt") ?? Date()
                    )
                }
                .sorted { $0.createdAt > $1.createdAt }
            }
        }
    }

    // Loads work sessions used for work-hour and earnings calculations.
    private func listenWorkSessions(_ uid: String) {
        workSessionsListener = col("workSessions", uid).addSnapshotListener { [weak self] snap, error in
            if let error {
                print("WORK LISTENER ERROR:", error.localizedDescription)
                return
            }

            let documents = snap?.documents.filter { $0.documentID != "_init" } ?? []

            DispatchQueue.main.async {
                self?.workSessions = documents.map { doc in
                    let d = doc.data()

                    return WorkSessionRecord(
                        id: UUID(uuidString: doc.documentID) ?? UUID(),
                        date: self?.readDate(d, "date") ?? Date(),
                        startTime: self?.readDate(d, "startTime") ?? Date(),
                        endTime: self?.readDate(d, "endTime") ?? Date(),
                        hourlyPay: self?.readDouble(d, "hourlyPay") ?? 0,
                        notes: d["notes"] as? String ?? ""
                    )
                }
                .sorted { $0.date > $1.date }
            }
        }
    }

    // Loads expense records from Firestore.
    private func listenExpenses(_ uid: String) {
        expensesListener = col("expenses", uid).addSnapshotListener { [weak self] snap, error in
            if let error {
                print("EXPENSES LISTENER ERROR:", error.localizedDescription)
                return
            }

            let documents = snap?.documents.filter { $0.documentID != "_init" } ?? []

            DispatchQueue.main.async {
                self?.expenses = documents.map { doc in
                    let d = doc.data()
                    let rawType = d["type"] as? String ?? ExpenseType.other.rawValue

                    return ExpenseRecord(
                        id: UUID(uuidString: doc.documentID) ?? UUID(),
                        date: self?.readDate(d, "date") ?? Date(),
                        name: d["name"] as? String ?? "Expense",
                        type: ExpenseType(rawValue: rawType) ?? .other,
                        whereUsed: d["whereUsed"] as? String ?? "",
                        amount: self?.readDouble(d, "amount") ?? 0
                    )
                }
                .sorted { $0.date > $1.date }
            }
        }
    }

    // Loads goal records from Firestore.
    private func listenGoals(_ uid: String) {
        goalsListener = col("goals", uid).addSnapshotListener { [weak self] snap, error in
            if let error {
                print("GOALS LISTENER ERROR:", error.localizedDescription)
                return
            }

            let documents = snap?.documents.filter { $0.documentID != "_init" } ?? []

            DispatchQueue.main.async {
                self?.goalRecords = documents.map { doc in
                    let d = doc.data()

                    return GoalRecord(
                        id: UUID(uuidString: doc.documentID) ?? UUID(),
                        goalName: d["goalName"] as? String ?? "",
                        goalDescription: d["goalDescription"] as? String ?? "",
                        targetDate: self?.readDate(d, "targetDate") ?? Date()
                    )
                }
                .sorted { $0.targetDate < $1.targetDate }
            }
        }
    }

    // Loads habits and their streak progress from Firestore.
    private func listenHabits(_ uid: String) {
        habitsListener = col("habits", uid).addSnapshotListener { [weak self] snap, error in
            if let error {
                print("HABITS LISTENER ERROR:", error.localizedDescription)
                return
            }

            let documents = snap?.documents.filter { $0.documentID != "_init" } ?? []

            DispatchQueue.main.async {
                self?.habits = documents.map { doc in
                    let d = doc.data()

                    let lastCompleted: Date?
                    if let timestamp = d["lastCompleted"] as? Timestamp {
                        lastCompleted = timestamp.dateValue()
                    } else {
                        lastCompleted = nil
                    }

                    return HabitItem(
                        id: UUID(uuidString: doc.documentID) ?? UUID(),
                        title: d["title"] as? String ?? "",
                        streak: self?.readInt(d, "streak") ?? 0,
                        lastCompleted: lastCompleted,
                        createdAt: self?.readDate(d, "createdAt") ?? Date(),
                        isCompletedToday: d["isCompletedToday"] as? Bool ?? false
                    )
                }
                .sorted { $0.createdAt > $1.createdAt }
            }
        }
    }

    // MARK: - Notes CRUD

    // Adds a new note to Firestore.
    func addNote(
        title: String,
        body: String,
        colorSeed: Int = Int.random(in: 0...10_000),
        completion: ((Bool) -> Void)? = nil
    ) {
        guard let uid = currentUID() else {
            completion?(false)
            return
        }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBody = body.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanTitle.isEmpty || !cleanBody.isEmpty else {
            completion?(false)
            return
        }

        let note = NoteItem(
            title: cleanTitle.isEmpty ? "Untitled" : cleanTitle,
            body: cleanBody,
            createdAt: Date(),
            colorSeed: colorSeed
        )

        doc("notes", uid, note.id).setData([
            "title": note.title,
            "body": note.body,
            "createdAt": Timestamp(date: note.createdAt),
            "colorSeed": note.colorSeed
        ]) { error in
            if let error {
                print("FIREBASE SAVE ERROR NOTE:", error.localizedDescription)
            }

            DispatchQueue.main.async {
                completion?(error == nil)
            }
        }
    }

    // Updates an existing note in Firestore.
    func updateNote(_ note: NoteItem, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?(false)
            return
        }

        doc("notes", uid, note.id).setData([
            "title": note.title,
            "body": note.body,
            "createdAt": Timestamp(date: note.createdAt),
            "colorSeed": note.colorSeed
        ], merge: true) { error in
            if let error {
                print("FIREBASE UPDATE ERROR NOTE:", error.localizedDescription)
            }

            DispatchQueue.main.async {
                completion?(error == nil)
            }
        }
    }

    // Deletes a note from Firestore.
    func deleteNote(_ note: NoteItem, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?(false)
            return
        }

        doc("notes", uid, note.id).delete { error in
            if let error {
                print("FIREBASE DELETE ERROR NOTE:", error.localizedDescription)
            }

            DispatchQueue.main.async {
                completion?(error == nil)
            }
        }
    }

    // MARK: - Tasks CRUD

    // Adds a new dashboard task to Firestore.
    func addTask(title: String, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?(false)
            return
        }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanTitle.isEmpty else {
            completion?(false)
            return
        }

        let task = TaskItem(
            title: cleanTitle,
            isDone: false,
            createdAt: Date()
        )

        doc("tasks", uid, task.id).setData([
            "title": task.title,
            "isDone": task.isDone,
            "createdAt": Timestamp(date: task.createdAt)
        ]) { error in
            if let error {
                print("FIREBASE SAVE ERROR TASK:", error.localizedDescription)
            }

            DispatchQueue.main.async {
                completion?(error == nil)
            }
        }
    }

    // Updates a task in Firestore.
    func updateTask(_ task: TaskItem, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?(false)
            return
        }

        doc("tasks", uid, task.id).setData([
            "title": task.title,
            "isDone": task.isDone,
            "createdAt": Timestamp(date: task.createdAt)
        ], merge: true) { error in
            if let error {
                print("FIREBASE UPDATE ERROR TASK:", error.localizedDescription)
            }

            DispatchQueue.main.async {
                completion?(error == nil)
            }
        }
    }

    // Toggles a task between complete and incomplete.
    func toggleTask(_ task: TaskItem, completion: ((Bool) -> Void)? = nil) {
        var updated = task
        updated.isDone.toggle()
        updateTask(updated, completion: completion)
    }

    // Deletes a task from Firestore.
    func deleteTask(_ task: TaskItem, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?(false)
            return
        }

        doc("tasks", uid, task.id).delete { error in
            if let error {
                print("FIREBASE DELETE ERROR TASK:", error.localizedDescription)
            }

            DispatchQueue.main.async {
                completion?(error == nil)
            }
        }
    }

    // MARK: - Reminders CRUD

    // Adds a reminder to Firestore and schedules its local notifications.
    func addReminder(
        title: String,
        dueAt: Date,
        locationName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        radiusMeters: Double = 150,
        notifyOnEntry: Bool = true,
        notifyOnExit: Bool = false,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard let uid = currentUID() else {
            completion?(false)
            return
        }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanTitle.isEmpty else {
            completion?(false)
            return
        }

        let reminder = ReminderItem(
            title: cleanTitle,
            dueAt: dueAt,
            isDone: false,
            createdAt: Date(),
            locationName: locationName,
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters,
            notifyOnEntry: notifyOnEntry,
            notifyOnExit: notifyOnExit
        )

        var payload: [String: Any] = [
            "title": reminder.title,
            "dueAt": Timestamp(date: reminder.dueAt),
            "isDone": reminder.isDone,
            "createdAt": Timestamp(date: reminder.createdAt),
            "radiusMeters": reminder.radiusMeters,
            "notifyOnEntry": reminder.notifyOnEntry,
            "notifyOnExit": reminder.notifyOnExit
        ]

        if let locationName = reminder.locationName,
           !locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            payload["locationName"] = locationName
        }

        if let latitude = reminder.latitude {
            payload["latitude"] = latitude
        }

        if let longitude = reminder.longitude {
            payload["longitude"] = longitude
        }

        doc("reminders", uid, reminder.id).setData(payload) { error in
            if let error {
                print("FIREBASE SAVE ERROR REMINDER:", error.localizedDescription)
            } else {
                print("REMINDER SAVED FIREBASE:", reminder.id.uuidString.uppercased())

                // Notifications are scheduled only after the reminder is saved successfully.
                NotificationManager.shared.scheduleNotifications(for: reminder)
            }

            DispatchQueue.main.async {
                completion?(error == nil)
            }
        }
    }

    // Updates a reminder and refreshes its scheduled notifications.
    func updateReminder(_ reminder: ReminderItem, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?(false)
            return
        }

        var payload: [String: Any] = [
            "title": reminder.title,
            "dueAt": Timestamp(date: reminder.dueAt),
            "isDone": reminder.isDone,
            "createdAt": Timestamp(date: reminder.createdAt),
            "radiusMeters": reminder.radiusMeters,
            "notifyOnEntry": reminder.notifyOnEntry,
            "notifyOnExit": reminder.notifyOnExit
        ]

        if let locationName = reminder.locationName,
           !locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            payload["locationName"] = locationName
        } else {
            payload["locationName"] = FieldValue.delete()
        }

        if let latitude = reminder.latitude {
            payload["latitude"] = latitude
        } else {
            payload["latitude"] = FieldValue.delete()
        }

        if let longitude = reminder.longitude {
            payload["longitude"] = longitude
        } else {
            payload["longitude"] = FieldValue.delete()
        }

        doc("reminders", uid, reminder.id).setData(payload, merge: true) { error in
            if let error {
                print("FIREBASE UPDATE ERROR REMINDER:", error.localizedDescription)
            } else {
                if reminder.isDone {
                    NotificationManager.shared.removeNotifications(for: reminder)
                } else {
                    NotificationManager.shared.scheduleNotifications(for: reminder)
                }
            }

            DispatchQueue.main.async {
                completion?(error == nil)
            }
        }
    }

    // Toggles a reminder between complete and incomplete.
    func toggleReminder(_ reminder: ReminderItem, completion: ((Bool) -> Void)? = nil) {
        var updated = reminder
        updated.isDone.toggle()
        updateReminder(updated, completion: completion)
    }

    // Deletes a reminder and removes any pending notifications for it.
    func deleteReminder(_ reminder: ReminderItem, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?(false)
            return
        }

        NotificationManager.shared.removeNotifications(for: reminder)

        doc("reminders", uid, reminder.id).delete { error in
            if let error {
                print("FIREBASE DELETE ERROR REMINDER:", error.localizedDescription)
            }

            DispatchQueue.main.async {
                completion?(error == nil)
            }
        }
    }

    // MARK: - Work Sessions CRUD

    // Adds a work session record to Firestore.
    func addWorkSession(_ session: WorkSessionRecord, completion: ((String?) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?("No authenticated user")
            return
        }

        doc("workSessions", uid, session.id).setData([
            "date": Timestamp(date: session.date),
            "startTime": Timestamp(date: session.startTime),
            "endTime": Timestamp(date: session.endTime),
            "hourlyPay": session.hourlyPay,
            "notes": session.notes
        ]) { error in
            if let error {
                print("FIREBASE SAVE ERROR WORK SESSION:", error.localizedDescription)
            }

            DispatchQueue.main.async {
                completion?(error?.localizedDescription)
            }
        }
    }

    // Deletes a work session from Firestore.
    func deleteWorkSession(_ session: WorkSessionRecord, completion: ((String?) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?("No authenticated user")
            return
        }

        doc("workSessions", uid, session.id).delete { error in
            if let error {
                print("FIREBASE DELETE ERROR WORK SESSION:", error.localizedDescription)
            }

            DispatchQueue.main.async {
                completion?(error?.localizedDescription)
            }
        }
    }

    // MARK: - Expenses CRUD

    // Adds an expense record to Firestore.
    func addExpense(_ expense: ExpenseRecord, completion: ((String?) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?("No authenticated user")
            return
        }

        doc("expenses", uid, expense.id).setData([
            "date": Timestamp(date: expense.date),
            "name": expense.name,
            "type": expense.type.rawValue,
            "whereUsed": expense.whereUsed,
            "amount": expense.amount
        ]) { error in
            if let error {
                print("FIREBASE SAVE ERROR EXPENSE:", error.localizedDescription)
            }

            DispatchQueue.main.async {
                completion?(error?.localizedDescription)
            }
        }
    }

    // Deletes an expense record from Firestore.
    func deleteExpense(_ expense: ExpenseRecord, completion: ((String?) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?("No authenticated user")
            return
        }

        doc("expenses", uid, expense.id).delete { error in
            if let error {
                print("FIREBASE DELETE ERROR EXPENSE:", error.localizedDescription)
            }

            DispatchQueue.main.async {
                completion?(error?.localizedDescription)
            }
        }
    }

    // MARK: - Goals CRUD

    // Adds a goal record to Firestore.
    func addGoalRecord(_ goal: GoalRecord, completion: ((String?) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?("No authenticated user")
            return
        }

        doc("goals", uid, goal.id).setData([
            "goalName": goal.goalName,
            "goalDescription": goal.goalDescription,
            "targetDate": Timestamp(date: goal.targetDate)
        ]) { error in
            if let error {
                print("FIREBASE SAVE ERROR GOAL:", error.localizedDescription)
            }

            DispatchQueue.main.async {
                completion?(error?.localizedDescription)
            }
        }
    }

    // Updates a goal by saving it again with the same document ID.
    func updateGoalRecord(_ goal: GoalRecord, completion: ((String?) -> Void)? = nil) {
        addGoalRecord(goal, completion: completion)
    }

    // Deletes a goal record from Firestore.
    func deleteGoalRecord(_ goal: GoalRecord, completion: ((String?) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?("No authenticated user")
            return
        }

        doc("goals", uid, goal.id).delete { error in
            if let error {
                print("FIREBASE DELETE ERROR GOAL:", error.localizedDescription)
            }

            DispatchQueue.main.async {
                completion?(error?.localizedDescription)
            }
        }
    }

    // MARK: - Habits CRUD

    // Creates a new habit from a title.
    func addHabit(title: String, completion: ((String?) -> Void)? = nil) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanTitle.isEmpty else {
            completion?("Missing habit title")
            return
        }

        let habit = HabitItem(
            title: cleanTitle,
            streak: 0,
            lastCompleted: nil,
            createdAt: Date(),
            isCompletedToday: false
        )

        addHabit(habit, completion: completion)
    }

    // Adds a full habit model to Firestore.
    func addHabit(_ habit: HabitItem, completion: ((String?) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?("No authenticated user")
            return
        }

        setHabit(habit, uid: uid, completion: completion)
    }

    // Updates an existing habit in Firestore.
    func updateHabit(_ habit: HabitItem, completion: ((String?) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?("No authenticated user")
            return
        }

        setHabit(habit, uid: uid, completion: completion)
    }

    // Toggles today's habit completion and updates the streak count.
    func toggleHabit(_ habit: HabitItem, completion: ((String?) -> Void)? = nil) {
        var updated = habit

        if updated.isCompletedToday {
            updated.isCompletedToday = false
            updated.streak = max(0, updated.streak - 1)
            updated.lastCompleted = nil
        } else {
            updated.isCompletedToday = true
            updated.streak += 1
            updated.lastCompleted = Date()
        }

        updateHabit(updated, completion: completion)
    }

    // Deletes a habit record from Firestore.
    func deleteHabit(_ habit: HabitItem, completion: ((String?) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?("No authenticated user")
            return
        }

        doc("habits", uid, habit.id).delete { error in
            if let error {
                print("FIREBASE DELETE ERROR HABIT:", error.localizedDescription)
            }

            DispatchQueue.main.async {
                completion?(error?.localizedDescription)
            }
        }
    }

    // Shared Firestore write method used by addHabit and updateHabit.
    private func setHabit(_ habit: HabitItem, uid: String, completion: ((String?) -> Void)? = nil) {
        var payload: [String: Any] = [
            "title": habit.title,
            "streak": habit.streak,
            "createdAt": Timestamp(date: habit.createdAt),
            "isCompletedToday": habit.isCompletedToday
        ]

        if let lastCompleted = habit.lastCompleted {
            payload["lastCompleted"] = Timestamp(date: lastCompleted)
        } else {
            payload["lastCompleted"] = FieldValue.delete()
        }

        doc("habits", uid, habit.id).setData(payload, merge: true) { error in
            if let error {
                print("FIREBASE SAVE ERROR HABIT:", error.localizedDescription)
            }

            DispatchQueue.main.async {
                completion?(error?.localizedDescription)
            }
        }
    }
}
