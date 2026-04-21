import Foundation
import Combine
import SwiftUI
import FirebaseFirestore

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
    private var tasksListener: ListenerRegistration?
    private var remindersListener: ListenerRegistration?
    private var workSessionsListener: ListenerRegistration?
    private var expensesListener: ListenerRegistration?
    private var goalsListener: ListenerRegistration?
    private var habitsListener: ListenerRegistration?

    init(auth: AuthStore) {
        self.auth = auth
        bindAuth()
        handleAuthChange(uid: auth.currentUserId)
    }

    deinit {
        removeAllListeners()
    }

    private func bindAuth() {
        auth.$currentUserId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] uid in
                self?.handleAuthChange(uid: uid)
            }
            .store(in: &cancellables)
    }

    private func handleAuthChange(uid: String?) {
        removeAllListeners()

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

        ensureUserDocument(uid: uid) { [weak self] ok in
            guard let self, ok else { return }

            self.startNotesListener(uid: uid)
            self.startTasksListener(uid: uid)
            self.startRemindersListener(uid: uid)
            self.startWorkSessionsListener(uid: uid)
            self.startExpensesListener(uid: uid)
            self.startGoalsListener(uid: uid)
            self.startHabitsListener(uid: uid)
        }
    }

    private func removeAllListeners() {
        notesListener?.remove()
        tasksListener?.remove()
        remindersListener?.remove()
        workSessionsListener?.remove()
        expensesListener?.remove()
        goalsListener?.remove()
        habitsListener?.remove()

        notesListener = nil
        tasksListener = nil
        remindersListener = nil
        workSessionsListener = nil
        expensesListener = nil
        goalsListener = nil
        habitsListener = nil
    }

    private func ensureUserDocument(uid: String, completion: @escaping (Bool) -> Void) {
        let payload: [String: Any] = [
            "uid": uid,
            "email": auth.currentEmail ?? "",
            "updatedAt": FieldValue.serverTimestamp(),
            "createdAt": FieldValue.serverTimestamp()
        ]

        db.collection("users").document(uid).setData(payload, merge: true) { error in
            DispatchQueue.main.async {
                completion(error == nil)
            }

            if let error {
                print("ENSURE USER DOC ERROR:", error.localizedDescription)
            }
        }
    }

    private func requireUID() -> String? {
        guard let uid = auth.currentUserId, !uid.isEmpty else {
            print("APPSTORE ERROR: missing authenticated uid")
            return nil
        }
        return uid
    }

    private func collection(_ name: String, uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection(name)
    }

    private func document(_ name: String, uid: String, id: UUID) -> DocumentReference {
        collection(name, uid: uid).document(id.uuidString)
    }

    private func date(_ data: [String: Any], _ key: String, fallback: Date = Date()) -> Date {
        if let timestamp = data[key] as? Timestamp {
            return timestamp.dateValue()
        }

        if let date = data[key] as? Date {
            return date
        }

        return fallback
    }

    // MARK: - Listeners

    private func startNotesListener(uid: String) {
        notesListener = collection("notes", uid: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error {
                    print("NOTES LISTENER ERROR:", error.localizedDescription)
                    return
                }

                let items = snapshot?.documents.compactMap {
                    self?.decodeNote($0)
                } ?? []

                DispatchQueue.main.async {
                    self?.notes = items
                }
            }
    }

    private func startTasksListener(uid: String) {
        tasksListener = collection("tasks", uid: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error {
                    print("TASKS LISTENER ERROR:", error.localizedDescription)
                    return
                }

                let items = snapshot?.documents.compactMap {
                    self?.decodeTask($0)
                } ?? []

                DispatchQueue.main.async {
                    self?.tasks = items
                }
            }
    }

    private func startRemindersListener(uid: String) {
        remindersListener = collection("reminders", uid: uid)
            .order(by: "dueAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error {
                    print("REMINDERS LISTENER ERROR:", error.localizedDescription)
                    return
                }

                let items = snapshot?.documents.compactMap {
                    self?.decodeReminder($0)
                } ?? []

                DispatchQueue.main.async {
                    self?.reminders = items
                }
            }
    }

    private func startWorkSessionsListener(uid: String) {
        workSessionsListener = collection("workSessions", uid: uid)
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error {
                    print("WORK SESSIONS LISTENER ERROR:", error.localizedDescription)
                    return
                }

                let items = snapshot?.documents.compactMap {
                    self?.decodeWorkSession($0)
                } ?? []

                DispatchQueue.main.async {
                    self?.workSessions = items
                }
            }
    }

    private func startExpensesListener(uid: String) {
        expensesListener = collection("expenses", uid: uid)
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error {
                    print("EXPENSES LISTENER ERROR:", error.localizedDescription)
                    return
                }

                let items = snapshot?.documents.compactMap {
                    self?.decodeExpense($0)
                } ?? []

                DispatchQueue.main.async {
                    self?.expenses = items
                }
            }
    }

    private func startGoalsListener(uid: String) {
        goalsListener = collection("goals", uid: uid)
            .order(by: "targetDate", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error {
                    print("GOALS LISTENER ERROR:", error.localizedDescription)
                    return
                }

                let items = snapshot?.documents.compactMap {
                    self?.decodeGoal($0)
                } ?? []

                DispatchQueue.main.async {
                    self?.goalRecords = items
                }
            }
    }

    private func startHabitsListener(uid: String) {
        habitsListener = collection("habits", uid: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error {
                    print("HABITS LISTENER ERROR:", error.localizedDescription)
                    return
                }

                let items = snapshot?.documents.compactMap {
                    self?.decodeHabit($0)
                } ?? []

                DispatchQueue.main.async {
                    self?.habits = items
                }
            }
    }

    // MARK: - Decode

    private func decodeNote(_ doc: DocumentSnapshot) -> NoteItem? {
        let data = doc.data() ?? [:]

        return NoteItem(
            id: UUID(uuidString: doc.documentID) ?? UUID(),
            title: data["title"] as? String ?? "",
            body: data["body"] as? String ?? "",
            createdAt: date(data, "createdAt"),
            colorSeed: data["colorSeed"] as? Int ?? 0
        )
    }

    private func decodeTask(_ doc: DocumentSnapshot) -> TaskItem? {
        let data = doc.data() ?? [:]

        return TaskItem(
            id: UUID(uuidString: doc.documentID) ?? UUID(),
            title: data["title"] as? String ?? "",
            isDone: data["isDone"] as? Bool ?? false,
            createdAt: date(data, "createdAt")
        )
    }

    private func decodeReminder(_ doc: DocumentSnapshot) -> ReminderItem? {
        let data = doc.data() ?? [:]

        return ReminderItem(
            id: UUID(uuidString: doc.documentID) ?? UUID(),
            title: data["title"] as? String ?? "",
            dueAt: date(data, "dueAt"),
            isDone: data["isDone"] as? Bool ?? false,
            createdAt: date(data, "createdAt")
        )
    }

    private func decodeWorkSession(_ doc: DocumentSnapshot) -> WorkSessionRecord? {
        let data = doc.data() ?? [:]

        return WorkSessionRecord(
            id: UUID(uuidString: doc.documentID) ?? UUID(),
            date: date(data, "date"),
            startTime: date(data, "startTime"),
            endTime: date(data, "endTime"),
            hourlyPay: data["hourlyPay"] as? Double ?? 0,
            notes: data["notes"] as? String ?? ""
        )
    }

    private func decodeExpense(_ doc: DocumentSnapshot) -> ExpenseRecord? {
        let data = doc.data() ?? [:]
        let rawType = data["type"] as? String ?? ExpenseType.other.rawValue

        return ExpenseRecord(
            id: UUID(uuidString: doc.documentID) ?? UUID(),
            date: date(data, "date"),
            name: data["name"] as? String ?? "Expense",
            type: ExpenseType(rawValue: rawType) ?? .other,
            whereUsed: data["whereUsed"] as? String ?? "",
            amount: data["amount"] as? Double ?? 0
        )
    }

    private func decodeGoal(_ doc: DocumentSnapshot) -> GoalRecord? {
        let data = doc.data() ?? [:]

        return GoalRecord(
            id: UUID(uuidString: doc.documentID) ?? UUID(),
            goalName: data["goalName"] as? String ?? "",
            goalDescription: data["goalDescription"] as? String ?? "",
            targetDate: date(data, "targetDate")
        )
    }

    private func decodeHabit(_ doc: DocumentSnapshot) -> HabitItem? {
        let data = doc.data() ?? [:]
        let lastCompleted = (data["lastCompleted"] as? Timestamp)?.dateValue()

        return HabitItem(
            id: UUID(uuidString: doc.documentID) ?? UUID(),
            title: data["title"] as? String ?? "",
            streak: data["streak"] as? Int ?? 0,
            lastCompleted: lastCompleted,
            createdAt: date(data, "createdAt"),
            isCompletedToday: data["isCompletedToday"] as? Bool ?? false
        )
    }

    // MARK: - Notes

    func addNote(title: String, body: String, colorSeed: Int = Int.random(in: 0...5), completion: ((Bool) -> Void)? = nil) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBody = body.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanTitle.isEmpty || !cleanBody.isEmpty, let uid = requireUID() else {
            completion?(false)
            return
        }

        let note = NoteItem(
            title: cleanTitle.isEmpty ? "Untitled" : cleanTitle,
            body: cleanBody,
            createdAt: Date(),
            colorSeed: colorSeed
        )

        document("notes", uid: uid, id: note.id).setData([
            "title": note.title,
            "body": note.body,
            "colorSeed": note.colorSeed,
            "createdAt": Timestamp(date: note.createdAt)
        ]) { error in
            DispatchQueue.main.async {
                completion?(error == nil)
            }
        }
    }

    func updateNote(_ note: NoteItem, completion: ((Bool) -> Void)? = nil) {
        guard let uid = requireUID() else {
            completion?(false)
            return
        }

        document("notes", uid: uid, id: note.id).setData([
            "title": note.title,
            "body": note.body,
            "colorSeed": note.colorSeed,
            "createdAt": Timestamp(date: note.createdAt)
        ], merge: true) { error in
            DispatchQueue.main.async {
                completion?(error == nil)
            }
        }
    }

    func deleteNote(_ note: NoteItem, completion: ((Bool) -> Void)? = nil) {
        guard let uid = requireUID() else {
            completion?(false)
            return
        }

        document("notes", uid: uid, id: note.id).delete { error in
            DispatchQueue.main.async {
                completion?(error == nil)
            }
        }
    }

    // MARK: - Tasks

    func addTask(title: String, completion: ((Bool) -> Void)? = nil) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanTitle.isEmpty, let uid = requireUID() else {
            completion?(false)
            return
        }

        let task = TaskItem(title: cleanTitle, isDone: false, createdAt: Date())

        document("tasks", uid: uid, id: task.id).setData([
            "title": task.title,
            "isDone": task.isDone,
            "createdAt": Timestamp(date: task.createdAt)
        ]) { error in
            DispatchQueue.main.async {
                completion?(error == nil)
            }
        }
    }

    func updateTask(_ task: TaskItem, completion: ((Bool) -> Void)? = nil) {
        guard let uid = requireUID() else {
            completion?(false)
            return
        }

        document("tasks", uid: uid, id: task.id).setData([
            "title": task.title,
            "isDone": task.isDone,
            "createdAt": Timestamp(date: task.createdAt)
        ], merge: true) { error in
            DispatchQueue.main.async {
                completion?(error == nil)
            }
        }
    }

    func toggleTask(_ task: TaskItem, completion: ((Bool) -> Void)? = nil) {
        var updatedTask = task
        updatedTask.isDone.toggle()
        updateTask(updatedTask, completion: completion)
    }

    func deleteTask(_ task: TaskItem, completion: ((Bool) -> Void)? = nil) {
        guard let uid = requireUID() else {
            completion?(false)
            return
        }

        document("tasks", uid: uid, id: task.id).delete { error in
            DispatchQueue.main.async {
                completion?(error == nil)
            }
        }
    }

    // MARK: - Reminders

    func addReminder(title: String, dueAt: Date, completion: ((Bool) -> Void)? = nil) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanTitle.isEmpty, let uid = requireUID() else {
            completion?(false)
            return
        }

        let reminder = ReminderItem(
            title: cleanTitle,
            dueAt: dueAt,
            isDone: false,
            createdAt: Date()
        )

        document("reminders", uid: uid, id: reminder.id).setData([
            "title": reminder.title,
            "dueAt": Timestamp(date: reminder.dueAt),
            "isDone": reminder.isDone,
            "createdAt": Timestamp(date: reminder.createdAt)
        ]) { error in
            DispatchQueue.main.async {
                completion?(error == nil)
            }
        }
    }

    func updateReminder(_ reminder: ReminderItem, completion: ((Bool) -> Void)? = nil) {
        guard let uid = requireUID() else {
            completion?(false)
            return
        }

        document("reminders", uid: uid, id: reminder.id).setData([
            "title": reminder.title,
            "dueAt": Timestamp(date: reminder.dueAt),
            "isDone": reminder.isDone,
            "createdAt": Timestamp(date: reminder.createdAt)
        ], merge: true) { error in
            DispatchQueue.main.async {
                completion?(error == nil)
            }
        }
    }

    func toggleReminder(_ reminder: ReminderItem, completion: ((Bool) -> Void)? = nil) {
        var updatedReminder = reminder
        updatedReminder.isDone.toggle()
        updateReminder(updatedReminder, completion: completion)
    }

    func deleteReminder(_ reminder: ReminderItem, completion: ((Bool) -> Void)? = nil) {
        guard let uid = requireUID() else {
            completion?(false)
            return
        }

        document("reminders", uid: uid, id: reminder.id).delete { error in
            DispatchQueue.main.async {
                completion?(error == nil)
            }
        }
    }

    // MARK: - Work Hours

    func addWorkSession(_ session: WorkSessionRecord, completion: ((String?) -> Void)? = nil) {
        guard let uid = requireUID() else {
            completion?("No authenticated user")
            return
        }

        document("workSessions", uid: uid, id: session.id).setData([
            "date": Timestamp(date: session.date),
            "startTime": Timestamp(date: session.startTime),
            "endTime": Timestamp(date: session.endTime),
            "hourlyPay": session.hourlyPay,
            "notes": session.notes
        ]) { error in
            DispatchQueue.main.async {
                completion?(error?.localizedDescription)
            }
        }
    }

    func deleteWorkSession(_ session: WorkSessionRecord, completion: ((String?) -> Void)? = nil) {
        guard let uid = requireUID() else {
            completion?("No authenticated user")
            return
        }

        document("workSessions", uid: uid, id: session.id).delete { error in
            DispatchQueue.main.async {
                completion?(error?.localizedDescription)
            }
        }
    }

    // MARK: - Expenses

    func addExpense(_ expense: ExpenseRecord, completion: ((String?) -> Void)? = nil) {
        guard let uid = requireUID() else {
            completion?("No authenticated user")
            return
        }

        document("expenses", uid: uid, id: expense.id).setData([
            "date": Timestamp(date: expense.date),
            "name": expense.name,
            "type": expense.type.rawValue,
            "whereUsed": expense.whereUsed,
            "amount": expense.amount
        ]) { error in
            DispatchQueue.main.async {
                completion?(error?.localizedDescription)
            }
        }
    }

    func deleteExpense(_ expense: ExpenseRecord, completion: ((String?) -> Void)? = nil) {
        guard let uid = requireUID() else {
            completion?("No authenticated user")
            return
        }

        document("expenses", uid: uid, id: expense.id).delete { error in
            DispatchQueue.main.async {
                completion?(error?.localizedDescription)
            }
        }
    }

    // MARK: - Goals

    func addGoalRecord(_ goal: GoalRecord, completion: ((String?) -> Void)? = nil) {
        guard let uid = requireUID() else {
            completion?("No authenticated user")
            return
        }

        document("goals", uid: uid, id: goal.id).setData([
            "goalName": goal.goalName,
            "goalDescription": goal.goalDescription,
            "targetDate": Timestamp(date: goal.targetDate)
        ]) { error in
            DispatchQueue.main.async {
                completion?(error?.localizedDescription)
            }
        }
    }

    func updateGoalRecord(_ goal: GoalRecord, completion: ((String?) -> Void)? = nil) {
        addGoalRecord(goal, completion: completion)
    }

    func deleteGoalRecord(_ goal: GoalRecord, completion: ((String?) -> Void)? = nil) {
        guard let uid = requireUID() else {
            completion?("No authenticated user")
            return
        }

        document("goals", uid: uid, id: goal.id).delete { error in
            DispatchQueue.main.async {
                completion?(error?.localizedDescription)
            }
        }
    }

    // MARK: - Habits

    func addHabit(title: String, completion: ((String?) -> Void)? = nil) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanTitle.isEmpty, let uid = requireUID() else {
            completion?("Missing habit title or user")
            return
        }

        let habit = HabitItem(
            title: cleanTitle,
            streak: 0,
            lastCompleted: nil,
            createdAt: Date(),
            isCompletedToday: false
        )

        setHabit(habit, uid: uid, completion: completion)
    }

    func updateHabit(_ habit: HabitItem, completion: ((String?) -> Void)? = nil) {
        guard let uid = requireUID() else {
            completion?("No authenticated user")
            return
        }

        setHabit(habit, uid: uid, completion: completion)
    }

    private func setHabit(_ habit: HabitItem, uid: String, completion: ((String?) -> Void)?) {
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

        document("habits", uid: uid, id: habit.id).setData(payload, merge: true) { error in
            DispatchQueue.main.async {
                completion?(error?.localizedDescription)
            }
        }
    }

    func deleteHabit(_ habit: HabitItem, completion: ((String?) -> Void)? = nil) {
        guard let uid = requireUID() else {
            completion?("No authenticated user")
            return
        }

        document("habits", uid: uid, id: habit.id).delete { error in
            DispatchQueue.main.async {
                completion?(error?.localizedDescription)
            }
        }
    }

    func saveAll() {
        for habit in habits {
            updateHabit(habit)
        }
    }
}
