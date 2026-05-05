// code assited by the some online documentations and LLM

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore


// Synching with firestore

final class AppStore: ObservableObject {
    @Published var notes: [NoteItem] = []
    @Published var reminders: [ReminderItem] = []
    @Published var tasks: [TaskItem] = []
    @Published var workSessions: [WorkSessionRecord] = []
    @Published var expenses: [ExpenseRecord] = []
    @Published var goalRecords: [GoalRecord] = []
    @Published var habits: [HabitItem] = []

    private let auth: AuthStore
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()

    private var notesListener: ListenerRegistration?
    private var remindersListener: ListenerRegistration?
    private var tasksListener: ListenerRegistration?
    private var workSessionsListener: ListenerRegistration?
    private var expensesListener: ListenerRegistration?
    private var goalsListener: ListenerRegistration?
    private var habitsListener: ListenerRegistration?

    init(auth: AuthStore) {
        self.auth = auth

        auth.$currentUserId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] uid in
                self?.setupUser(uid)
            }
            .store(in: &cancellables)

        setupUser(auth.currentUserId)
    }

    deinit {
        removeListeners()
    }

    private func setupUser(_ uid: String?) {
        removeListeners()

        guard let uid, !uid.isEmpty else {
            notes = []
            reminders = []
            tasks = []
            workSessions = []
            expenses = []
            goalRecords = []
            habits = []
            return
        }

        print("APPSTORE USING UID:", uid)

        db.collection("taskflowData").document(uid).setData([
            "uid": uid,
            "email": auth.currentEmail ?? "",
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)

        listenNotes(uid)
        listenReminders(uid)
        listenTasks(uid)
        listenWorkSessions(uid)
        listenExpenses(uid)
        listenGoals(uid)
        listenHabits(uid)
    }

    private func removeListeners() {
        notesListener?.remove()
        remindersListener?.remove()
        tasksListener?.remove()
        workSessionsListener?.remove()
        expensesListener?.remove()
        goalsListener?.remove()
        habitsListener?.remove()
    }

    private func currentUID() -> String? {
        guard let uid = auth.currentUserId, !uid.isEmpty else {
            print("FIREBASE SAVE ERROR: No logged-in user UID")
            return nil
        }
        return uid
    }

    private func col(_ name: String, _ uid: String) -> CollectionReference {
        db.collection("taskflowData").document(uid).collection(name)
    }

    private func doc(_ name: String, _ uid: String, _ id: UUID) -> DocumentReference {
        col(name, uid).document(id.uuidString.uppercased())
    }

    private func readDate(_ data: [String: Any], _ key: String, fallback: Date = Date()) -> Date {
        if let timestamp = data[key] as? Timestamp {
            return timestamp.dateValue()
        }
        return fallback
    }

    // MARK: - Listeners

    private func listenNotes(_ uid: String) {
        notesListener = col("notes", uid).addSnapshotListener { [weak self] snap, error in
            if let error {
                print("NOTES LISTENER ERROR:", error.localizedDescription)
                return
            }

            let documents = snap?.documents.filter { $0.documentID != "_init" } ?? []

            DispatchQueue.main.async {
                if documents.isEmpty {
                    self?.notes = []
                    return
                }

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
            }
        }
    }

    private func listenReminders(_ uid: String) {
        remindersListener = col("reminders", uid).addSnapshotListener { [weak self] snap, error in
            if let error {
                print("REMINDERS LISTENER ERROR:", error.localizedDescription)
                return
            }

            let documents = snap?.documents.filter { $0.documentID != "_init" } ?? []

            DispatchQueue.main.async {
                if documents.isEmpty {
                    self?.reminders = []
                    return
                }

                self?.reminders = documents.map { doc in
                    let d = doc.data()
                    return ReminderItem(
                        id: UUID(uuidString: doc.documentID) ?? UUID(),
                        title: d["title"] as? String ?? "",
                        dueAt: self?.readDate(d, "dueAt") ?? Date(),
                        isDone: d["isDone"] as? Bool ?? false,
                        createdAt: self?.readDate(d, "createdAt") ?? Date()
                    )
                }
            }
        }
    }

    private func listenTasks(_ uid: String) {
        tasksListener = col("tasks", uid).addSnapshotListener { [weak self] snap, error in
            if let error {
                print("TASKS LISTENER ERROR:", error.localizedDescription)
                return
            }

            let documents = snap?.documents.filter { $0.documentID != "_init" } ?? []

            DispatchQueue.main.async {
                if documents.isEmpty {
                    self?.tasks = []
                    return
                }

                self?.tasks = documents.map { doc in
                    let d = doc.data()
                    return TaskItem(
                        id: UUID(uuidString: doc.documentID) ?? UUID(),
                        title: d["title"] as? String ?? "",
                        isDone: d["isDone"] as? Bool ?? false,
                        createdAt: self?.readDate(d, "createdAt") ?? Date()
                    )
                }
            }
        }
    }

    private func listenWorkSessions(_ uid: String) {
        workSessionsListener = col("workSessions", uid).addSnapshotListener { [weak self] snap, error in
            if let error {
                print("WORK LISTENER ERROR:", error.localizedDescription)
                return
            }

            let documents = snap?.documents.filter { $0.documentID != "_init" } ?? []

            DispatchQueue.main.async {
                if documents.isEmpty {
                    self?.workSessions = []
                    return
                }

                self?.workSessions = documents.map { doc in
                    let d = doc.data()
                    return WorkSessionRecord(
                        id: UUID(uuidString: doc.documentID) ?? UUID(),
                        date: self?.readDate(d, "date") ?? Date(),
                        startTime: self?.readDate(d, "startTime") ?? Date(),
                        endTime: self?.readDate(d, "endTime") ?? Date(),
                        hourlyPay: d["hourlyPay"] as? Double ?? 0,
                        notes: d["notes"] as? String ?? ""
                    )
                }
            }
        }
    }

    private func listenExpenses(_ uid: String) {
        expensesListener = col("expenses", uid).addSnapshotListener { [weak self] snap, error in
            if let error {
                print("EXPENSES LISTENER ERROR:", error.localizedDescription)
                return
            }

            let documents = snap?.documents.filter { $0.documentID != "_init" } ?? []

            DispatchQueue.main.async {
                if documents.isEmpty {
                    self?.expenses = []
                    return
                }

                self?.expenses = documents.map { doc in
                    let d = doc.data()
                    let rawType = d["type"] as? String ?? ExpenseType.other.rawValue

                    return ExpenseRecord(
                        id: UUID(uuidString: doc.documentID) ?? UUID(),
                        date: self?.readDate(d, "date") ?? Date(),
                        name: d["name"] as? String ?? "Expense",
                        type: ExpenseType(rawValue: rawType) ?? .other,
                        whereUsed: d["whereUsed"] as? String ?? "",
                        amount: d["amount"] as? Double ?? 0
                    )
                }
            }
        }
    }

    private func listenGoals(_ uid: String) {
        goalsListener = col("goals", uid).addSnapshotListener { [weak self] snap, error in
            if let error {
                print("GOALS LISTENER ERROR:", error.localizedDescription)
                return
            }

            let documents = snap?.documents.filter { $0.documentID != "_init" } ?? []

            DispatchQueue.main.async {
                if documents.isEmpty {
                    self?.goalRecords = []
                    return
                }

                self?.goalRecords = documents.map { doc in
                    let d = doc.data()
                    return GoalRecord(
                        id: UUID(uuidString: doc.documentID) ?? UUID(),
                        goalName: d["goalName"] as? String ?? "",
                        goalDescription: d["goalDescription"] as? String ?? "",
                        targetDate: self?.readDate(d, "targetDate") ?? Date()
                    )
                }
            }
        }
    }

    private func listenHabits(_ uid: String) {
        habitsListener = col("habits", uid).addSnapshotListener { [weak self] snap, error in
            if let error {
                print("HABITS LISTENER ERROR:", error.localizedDescription)
                return
            }

            let documents = snap?.documents.filter { $0.documentID != "_init" } ?? []

            DispatchQueue.main.async {
                if documents.isEmpty {
                    self?.habits = []
                    return
                }

                self?.habits = documents.map { doc in
                    let d = doc.data()
                    return HabitItem(
                        id: UUID(uuidString: doc.documentID) ?? UUID(),
                        title: d["title"] as? String ?? "",
                        streak: d["streak"] as? Int ?? 0,
                        lastCompleted: (d["lastCompleted"] as? Timestamp)?.dateValue(),
                        createdAt: self?.readDate(d, "createdAt") ?? Date(),
                        isCompletedToday: d["isCompletedToday"] as? Bool ?? false
                    )
                }
            }
        }
    }

    // MARK: - Tasks

    func addTask(title: String, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?(false)
            return
        }

        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            completion?(false)
            return
        }

        let item = TaskItem(title: clean, isDone: false, createdAt: Date())

        doc("tasks", uid, item.id).setData([
            "title": item.title,
            "isDone": item.isDone,
            "createdAt": Timestamp(date: item.createdAt)
        ]) { error in
            if let error {
                print("FIREBASE SAVE ERROR TASK:", error.localizedDescription)
            } else {
                print("TASK SAVED FIREBASE:", item.id.uuidString.uppercased())
            }
            DispatchQueue.main.async { completion?(error == nil) }
        }
    }

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
            DispatchQueue.main.async { completion?(error == nil) }
        }
    }

    func toggleTask(_ task: TaskItem, completion: ((Bool) -> Void)? = nil) {
        var updated = task
        updated.isDone.toggle()
        updateTask(updated, completion: completion)
    }

    func deleteTask(_ task: TaskItem, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?(false)
            return
        }

        doc("tasks", uid, task.id).delete { error in
            if let error {
                print("FIREBASE DELETE ERROR TASK:", error.localizedDescription)
            }
            DispatchQueue.main.async { completion?(error == nil) }
        }
    }

    // MARK: - Reminders

    func addReminder(title: String, dueAt: Date, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?(false)
            return
        }

        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            completion?(false)
            return
        }

        let item = ReminderItem(title: clean, dueAt: dueAt, isDone: false, createdAt: Date())

        doc("reminders", uid, item.id).setData([
            "title": item.title,
            "dueAt": Timestamp(date: item.dueAt),
            "isDone": item.isDone,
            "createdAt": Timestamp(date: item.createdAt)
        ]) { error in
            if let error {
                print("FIREBASE SAVE ERROR REMINDER:", error.localizedDescription)
            } else {
                print("REMINDER SAVED FIREBASE:", item.id.uuidString.uppercased())
            }
            DispatchQueue.main.async { completion?(error == nil) }
        }
    }

    func updateReminder(_ reminder: ReminderItem, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?(false)
            return
        }

        doc("reminders", uid, reminder.id).setData([
            "title": reminder.title,
            "dueAt": Timestamp(date: reminder.dueAt),
            "isDone": reminder.isDone,
            "createdAt": Timestamp(date: reminder.createdAt)
        ], merge: true) { error in
            if let error {
                print("FIREBASE UPDATE ERROR REMINDER:", error.localizedDescription)
            }
            DispatchQueue.main.async { completion?(error == nil) }
        }
    }

    func toggleReminder(_ reminder: ReminderItem, completion: ((Bool) -> Void)? = nil) {
        var updated = reminder
        updated.isDone.toggle()
        updateReminder(updated, completion: completion)
    }

    func deleteReminder(_ reminder: ReminderItem, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?(false)
            return
        }

        doc("reminders", uid, reminder.id).delete { error in
            if let error {
                print("FIREBASE DELETE ERROR REMINDER:", error.localizedDescription)
            }
            DispatchQueue.main.async { completion?(error == nil) }
        }
    }

    // MARK: - Notes

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

        let item = NoteItem(
            title: cleanTitle.isEmpty ? "Untitled" : cleanTitle,
            body: cleanBody,
            createdAt: Date(),
            colorSeed: colorSeed
        )

        doc("notes", uid, item.id).setData([
            "title": item.title,
            "body": item.body,
            "colorSeed": item.colorSeed,
            "createdAt": Timestamp(date: item.createdAt)
        ]) { error in
            if let error {
                print("FIREBASE SAVE ERROR NOTE:", error.localizedDescription)
            } else {
                print("NOTE SAVED FIREBASE:", item.id.uuidString.uppercased())
            }
            DispatchQueue.main.async { completion?(error == nil) }
        }
    }

    func updateNote(_ note: NoteItem, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?(false)
            return
        }

        doc("notes", uid, note.id).setData([
            "title": note.title,
            "body": note.body,
            "colorSeed": note.colorSeed,
            "createdAt": Timestamp(date: note.createdAt)
        ], merge: true) { error in
            if let error {
                print("FIREBASE UPDATE ERROR NOTE:", error.localizedDescription)
            }
            DispatchQueue.main.async { completion?(error == nil) }
        }
    }

    func deleteNote(_ note: NoteItem, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?(false)
            return
        }

        doc("notes", uid, note.id).delete { error in
            if let error {
                print("FIREBASE DELETE ERROR NOTE:", error.localizedDescription)
            }
            DispatchQueue.main.async { completion?(error == nil) }
        }
    }

    // MARK: - Work Sessions

    func addWorkSession(_ session: WorkSessionRecord, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?(false)
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
                print("FIREBASE SAVE ERROR WORK:", error.localizedDescription)
            } else {
                print("WORK SAVED FIREBASE:", session.id.uuidString.uppercased())
            }
            DispatchQueue.main.async { completion?(error == nil) }
        }
    }

    func deleteWorkSession(_ session: WorkSessionRecord, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?(false)
            return
        }

        doc("workSessions", uid, session.id).delete { error in
            if let error {
                print("FIREBASE DELETE ERROR WORK:", error.localizedDescription)
            }
            DispatchQueue.main.async { completion?(error == nil) }
        }
    }

    // MARK: - Expenses

    func addExpense(_ expense: ExpenseRecord, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?(false)
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
            } else {
                print("EXPENSE SAVED FIREBASE:", expense.id.uuidString.uppercased())
            }
            DispatchQueue.main.async { completion?(error == nil) }
        }
    }

    func deleteExpense(_ expense: ExpenseRecord, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?(false)
            return
        }

        doc("expenses", uid, expense.id).delete { error in
            if let error {
                print("FIREBASE DELETE ERROR EXPENSE:", error.localizedDescription)
            }
            DispatchQueue.main.async { completion?(error == nil) }
        }
    }

    // MARK: - Goals

    func addGoalRecord(_ goal: GoalRecord, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?(false)
            return
        }

        doc("goals", uid, goal.id).setData([
            "goalName": goal.goalName,
            "goalDescription": goal.goalDescription,
            "targetDate": Timestamp(date: goal.targetDate)
        ]) { error in
            if let error {
                print("FIREBASE SAVE ERROR GOAL:", error.localizedDescription)
            } else {
                print("GOAL SAVED FIREBASE:", goal.id.uuidString.uppercased())
            }
            DispatchQueue.main.async { completion?(error == nil) }
        }
    }

    func updateGoalRecord(_ goal: GoalRecord, completion: ((Bool) -> Void)? = nil) {
        addGoalRecord(goal, completion: completion)
    }

    func deleteGoalRecord(_ goal: GoalRecord, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?(false)
            return
        }

        doc("goals", uid, goal.id).delete { error in
            if let error {
                print("FIREBASE DELETE ERROR GOAL:", error.localizedDescription)
            }
            DispatchQueue.main.async { completion?(error == nil) }
        }
    }

    // MARK: - Habits

    func addHabit(title: String, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?(false)
            return
        }

        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            completion?(false)
            return
        }

        let habit = HabitItem(
            title: clean,
            streak: 0,
            lastCompleted: nil,
            createdAt: Date(),
            isCompletedToday: false
        )

        updateHabit(habit, completion: completion)
    }

    func updateHabit(_ habit: HabitItem, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?(false)
            return
        }

        var data: [String: Any] = [
            "title": habit.title,
            "streak": habit.streak,
            "createdAt": Timestamp(date: habit.createdAt),
            "isCompletedToday": habit.isCompletedToday
        ]

        if let lastCompleted = habit.lastCompleted {
            data["lastCompleted"] = Timestamp(date: lastCompleted)
        }

        doc("habits", uid, habit.id).setData(data, merge: true) { error in
            if let error {
                print("FIREBASE SAVE ERROR HABIT:", error.localizedDescription)
            } else {
                print("HABIT SAVED FIREBASE:", habit.id.uuidString.uppercased())
            }
            DispatchQueue.main.async { completion?(error == nil) }
        }
    }

    func deleteHabit(_ habit: HabitItem, completion: ((Bool) -> Void)? = nil) {
        guard let uid = currentUID() else {
            completion?(false)
            return
        }

        doc("habits", uid, habit.id).delete { error in
            if let error {
                print("FIREBASE DELETE ERROR HABIT:", error.localizedDescription)
            }
            DispatchQueue.main.async { completion?(error == nil) }
        }
    }

    func saveAll() {
        habits.forEach { updateHabit($0) }
    }
}
