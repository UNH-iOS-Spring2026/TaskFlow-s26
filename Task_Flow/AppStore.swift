//
//  AppStore.swift
//  Task_Flow
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class AppStore: ObservableObject {

    @Published var auth: AuthStore

    @Published var tasks: [TaskItem] = []
    @Published var reminders: [ReminderItem] = []
    @Published var notes: [NoteItem] = []
    @Published var workHours: [WorkHourEntry] = []
    @Published var goals: [GoalItem] = []
    @Published var habits: [HabitItem] = []

    private let workFile = "workhours.json"
    private let goalsFile = "goals.json"
    private let habitsFile = "habits.json"

    private let db = Firestore.firestore()

    private var notesListener: ListenerRegistration?
    private var tasksListener: ListenerRegistration?
    private var remindersListener: ListenerRegistration?

    private var cancellables = Set<AnyCancellable>()

    init(auth: AuthStore) {
        self.auth = auth

        notes = []
        tasks = []
        reminders = []

        workHours = Persistence.shared.load([WorkHourEntry].self, from: workFile, default: [])
        goals = Persistence.shared.load([GoalItem].self, from: goalsFile, default: [])
        habits = Persistence.shared.load([HabitItem].self, from: habitsFile, default: [])

        auth.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        wireAutosave()
        bindAuth()
        handleAuthChange(uid: auth.currentUserId)
    }

    deinit {
        notesListener?.remove()
        tasksListener?.remove()
        remindersListener?.remove()
    }

    // MARK: - Auth

    private func bindAuth() {
        auth.$currentUserId
            .receive(on: RunLoop.main)
            .sink { [weak self] uid in
                self?.handleAuthChange(uid: uid)
            }
            .store(in: &cancellables)
    }

    private func handleAuthChange(uid: String?) {
        print("APPSTORE AUTH UID:", uid ?? "nil")

        notesListener?.remove()
        notesListener = nil

        tasksListener?.remove()
        tasksListener = nil

        remindersListener?.remove()
        remindersListener = nil

        notes = []
        tasks = []
        reminders = []

        guard let uid, !uid.isEmpty else {
            print("APPSTORE: No authenticated uid")
            return
        }

        ensureUserDocument(uid: uid) { [weak self] success in
            guard let self, success else { return }
            self.startNotesListener(for: uid)
            self.startTasksListener(for: uid)
            self.startRemindersListener(for: uid)
        }
    }

    private func requireUID() -> String? {
        guard let uid = auth.currentUserId, !uid.isEmpty else {
            print("APPSTORE ERROR: Missing auth.currentUserId")
            return nil
        }
        return uid
    }

    private func ensureUserDocument(uid: String, completion: ((Bool) -> Void)? = nil) {
        let payload: [String: Any] = [
            "uid": uid,
            "email": auth.currentEmail ?? "",
            "updatedAt": Timestamp(date: Date()),
            "createdAt": FieldValue.serverTimestamp()
        ]

        db.collection("users")
            .document(uid)
            .setData(payload, merge: true) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("ENSURE USER DOC ERROR:", error.localizedDescription)
                        completion?(false)
                    } else {
                        print("ENSURE USER DOC SUCCESS:", uid)
                        completion?(true)
                    }
                }
            }
    }

    // MARK: - Notes

    private func notesCollection(for uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("notes")
    }

    private func noteDocument(uid: String, noteId: UUID) -> DocumentReference {
        notesCollection(for: uid).document(noteId.uuidString)
    }

    private func startNotesListener(for uid: String) {
        notesListener?.remove()

        print("NOTES LISTENER START PATH: users/\(uid)/notes")

        notesListener = notesCollection(for: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error = error {
                    print("NOTES LISTENER ERROR:", error.localizedDescription)
                    return
                }

                let docs = snapshot?.documents ?? []
                print("NOTES LISTENER DOC COUNT:", docs.count)

                let items = docs.compactMap { self.makeNote(from: $0) }

                DispatchQueue.main.async {
                    self.notes = items
                    print("NOTES ARRAY UPDATED:", self.notes.map(\.title))
                }
            }
    }

    private func makeNote(from document: DocumentSnapshot) -> NoteItem? {
        let data = document.data() ?? [:]

        let id = UUID(uuidString: document.documentID) ?? UUID()
        let title = data["title"] as? String ?? ""
        let body = data["body"] as? String ?? ""
        let colorSeed = data["colorSeed"] as? Int ?? 0

        let createdAt: Date
        if let ts = data["createdAt"] as? Timestamp {
            createdAt = ts.dateValue()
        } else {
            createdAt = Date()
        }

        return NoteItem(
            id: id,
            title: title,
            body: body,
            createdAt: createdAt,
            colorSeed: colorSeed
        )
    }

    private func notePayload(from note: NoteItem) -> [String: Any] {
        [
            "title": note.title,
            "body": note.body,
            "colorSeed": note.colorSeed,
            "createdAt": Timestamp(date: note.createdAt)
        ]
    }

    func addNote(title: String, body: String, colorSeed: Int, completion: ((String?) -> Void)? = nil) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty || !trimmedBody.isEmpty else {
            completion?("Note cannot be empty.")
            return
        }

        guard let uid = requireUID() else {
            completion?("You are not logged in.")
            return
        }

        ensureUserDocument(uid: uid) { [weak self] success in
            guard let self, success else {
                completion?("Could not create user document.")
                return
            }

            let note = NoteItem(
                title: trimmedTitle.isEmpty ? "Untitled" : trimmedTitle,
                body: trimmedBody,
                createdAt: Date(),
                colorSeed: colorSeed
            )

            let docRef = self.noteDocument(uid: uid, noteId: note.id)

            docRef.setData(self.notePayload(from: note)) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("ADD NOTE ERROR:", error.localizedDescription)
                        completion?(error.localizedDescription)
                    } else {
                        print("ADD NOTE SUCCESS:", docRef.path)
                        completion?(nil)
                    }
                }
            }
        }
    }

    func updateNote(id: UUID, title: String, body: String, colorSeed: Int, completion: ((String?) -> Void)? = nil) {
        guard let existing = notes.first(where: { $0.id == id }) else {
            completion?("Note not found.")
            return
        }

        guard let uid = requireUID() else {
            completion?("You are not logged in.")
            return
        }

        let updated = NoteItem(
            id: existing.id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : title.trimmingCharacters(in: .whitespacesAndNewlines),
            body: body.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: existing.createdAt,
            colorSeed: colorSeed
        )

        noteDocument(uid: uid, noteId: updated.id)
            .setData(notePayload(from: updated)) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("UPDATE NOTE ERROR:", error.localizedDescription)
                        completion?(error.localizedDescription)
                    } else {
                        completion?(nil)
                    }
                }
            }
    }

    func deleteNote(_ note: NoteItem, completion: ((String?) -> Void)? = nil) {
        guard let uid = requireUID() else {
            completion?("You are not logged in.")
            return
        }

        noteDocument(uid: uid, noteId: note.id)
            .delete { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("DELETE NOTE ERROR:", error.localizedDescription)
                        completion?(error.localizedDescription)
                    } else {
                        completion?(nil)
                    }
                }
            }
    }

    // MARK: - Tasks

    private func tasksCollection(for uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("tasks")
    }

    private func taskDocument(uid: String, taskId: UUID) -> DocumentReference {
        tasksCollection(for: uid).document(taskId.uuidString)
    }

    private func startTasksListener(for uid: String) {
        tasksListener?.remove()

        print("TASKS LISTENER START PATH: users/\(uid)/tasks")

        tasksListener = tasksCollection(for: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error = error {
                    print("TASKS LISTENER ERROR:", error.localizedDescription)
                    return
                }

                let docs = snapshot?.documents ?? []
                print("TASKS LISTENER DOC COUNT:", docs.count)

                let items = docs.compactMap { self.makeTask(from: $0) }

                DispatchQueue.main.async {
                    self.tasks = items
                    print("TASKS ARRAY UPDATED:", self.tasks.map(\.title))
                }
            }
    }

    private func makeTask(from document: DocumentSnapshot) -> TaskItem? {
        let data = document.data() ?? [:]

        let id = UUID(uuidString: document.documentID) ?? UUID()
        let title = data["title"] as? String ?? ""
        let isDone = data["isDone"] as? Bool ?? false

        let createdAt: Date
        if let ts = data["createdAt"] as? Timestamp {
            createdAt = ts.dateValue()
        } else {
            createdAt = Date()
        }

        return TaskItem(
            id: id,
            title: title,
            isDone: isDone,
            createdAt: createdAt
        )
    }

    private func taskPayload(from task: TaskItem) -> [String: Any] {
        [
            "title": task.title,
            "isDone": task.isDone,
            "createdAt": Timestamp(date: task.createdAt)
        ]
    }

    private func debugPrintAllTaskDocs(uid: String) {
        tasksCollection(for: uid).getDocuments { snapshot, error in
            if let error = error {
                print("DEBUG TASK FETCH ERROR:", error.localizedDescription)
                return
            }

            let docs = snapshot?.documents ?? []
            print("DEBUG TASK FETCH COUNT:", docs.count)

            for doc in docs {
                print("DEBUG TASK DOC ID:", doc.documentID)
                print("DEBUG TASK DOC DATA:", doc.data())
            }
        }
    }

    func addTask(title: String, completion: ((String?) -> Void)? = nil) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            completion?("Task title cannot be empty.")
            return
        }

        guard let uid = requireUID() else {
            completion?("You are not logged in.")
            return
        }

        ensureUserDocument(uid: uid) { [weak self] success in
            guard let self, success else {
                completion?("Could not create user document.")
                return
            }

            let task = TaskItem(
                title: trimmedTitle,
                isDone: false,
                createdAt: Date()
            )

            let docRef = self.taskDocument(uid: uid, taskId: task.id)

            print("ADD TASK UID:", uid)
            print("ADD TASK TITLE:", task.title)
            print("ADD TASK DOC PATH:", docRef.path)

            docRef.setData(self.taskPayload(from: task)) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        print("ADD TASK ERROR:", error.localizedDescription)
                        completion?(error.localizedDescription)
                    }
                    return
                }

                print("ADD TASK SUCCESS:", task.id.uuidString)

                docRef.getDocument { snapshot, readError in
                    DispatchQueue.main.async {
                        if let readError = readError {
                            print("ADD TASK READBACK ERROR:", readError.localizedDescription)
                            completion?(readError.localizedDescription)
                            return
                        }

                        print("ADD TASK READBACK EXISTS:", snapshot?.exists ?? false)
                        print("ADD TASK READBACK DATA:", snapshot?.data() ?? [:])

                        self.debugPrintAllTaskDocs(uid: uid)
                        completion?(nil)
                    }
                }
            }
        }
    }

    func updateTask(_ task: TaskItem, completion: ((String?) -> Void)? = nil) {
        let trimmedTitle = task.title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let uid = requireUID() else {
            completion?("You are not logged in.")
            return
        }

        let updated = TaskItem(
            id: task.id,
            title: trimmedTitle.isEmpty ? "Untitled Task" : trimmedTitle,
            isDone: task.isDone,
            createdAt: task.createdAt
        )

        taskDocument(uid: uid, taskId: updated.id)
            .setData(taskPayload(from: updated)) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("UPDATE TASK ERROR:", error.localizedDescription)
                        completion?(error.localizedDescription)
                    } else {
                        print("UPDATE TASK SUCCESS:", updated.id.uuidString)
                        completion?(nil)
                    }
                }
            }
    }

    func toggleTask(_ task: TaskItem, completion: ((String?) -> Void)? = nil) {
        let toggled = TaskItem(
            id: task.id,
            title: task.title,
            isDone: !task.isDone,
            createdAt: task.createdAt
        )
        updateTask(toggled, completion: completion)
    }

    func deleteTask(_ task: TaskItem, completion: ((String?) -> Void)? = nil) {
        guard let uid = requireUID() else {
            completion?("You are not logged in.")
            return
        }

        taskDocument(uid: uid, taskId: task.id)
            .delete { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("DELETE TASK ERROR:", error.localizedDescription)
                        completion?(error.localizedDescription)
                    } else {
                        print("DELETE TASK SUCCESS:", task.id.uuidString)
                        completion?(nil)
                    }
                }
            }
    }

    // MARK: - Reminders

    private func remindersCollection(for uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("reminders")
    }

    private func reminderDocument(uid: String, reminderId: UUID) -> DocumentReference {
        remindersCollection(for: uid).document(reminderId.uuidString)
    }

    private func startRemindersListener(for uid: String) {
        remindersListener?.remove()

        print("REMINDERS LISTENER START PATH: users/\(uid)/reminders")

        remindersListener = remindersCollection(for: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error = error {
                    print("REMINDERS LISTENER ERROR:", error.localizedDescription)
                    return
                }

                let docs = snapshot?.documents ?? []
                print("REMINDERS LISTENER DOC COUNT:", docs.count)

                let items = docs.compactMap { self.makeReminder(from: $0) }

                DispatchQueue.main.async {
                    self.reminders = items
                    print("REMINDERS ARRAY UPDATED:", self.reminders.map(\.title))
                }
            }
    }

    private func makeReminder(from document: DocumentSnapshot) -> ReminderItem? {
        let data = document.data() ?? [:]

        let id = UUID(uuidString: document.documentID) ?? UUID()
        let title = data["title"] as? String ?? ""
        let isDone = data["isDone"] as? Bool ?? false

        let dueAt: Date
        if let ts = data["dueAt"] as? Timestamp {
            dueAt = ts.dateValue()
        } else {
            dueAt = Date()
        }

        let createdAt: Date
        if let ts = data["createdAt"] as? Timestamp {
            createdAt = ts.dateValue()
        } else {
            createdAt = Date()
        }

        return ReminderItem(
            id: id,
            title: title,
            dueAt: dueAt,
            isDone: isDone,
            createdAt: createdAt
        )
    }

    private func reminderPayload(from reminder: ReminderItem) -> [String: Any] {
        [
            "title": reminder.title,
            "dueAt": Timestamp(date: reminder.dueAt),
            "isDone": reminder.isDone,
            "createdAt": Timestamp(date: reminder.createdAt)
        ]
    }

    func addReminder(title: String, dueAt: Date, completion: ((String?) -> Void)? = nil) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            completion?("Reminder title cannot be empty.")
            return
        }

        guard let uid = requireUID() else {
            completion?("You are not logged in.")
            return
        }

        ensureUserDocument(uid: uid) { [weak self] success in
            guard let self, success else {
                completion?("Could not create user document.")
                return
            }

            let reminder = ReminderItem(
                title: trimmedTitle,
                dueAt: dueAt,
                isDone: false,
                createdAt: Date()
            )

            let docRef = self.reminderDocument(uid: uid, reminderId: reminder.id)

            docRef.setData(self.reminderPayload(from: reminder)) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("ADD REMINDER ERROR:", error.localizedDescription)
                        completion?(error.localizedDescription)
                    } else {
                        print("ADD REMINDER SUCCESS:", docRef.path)
                        completion?(nil)
                    }
                }
            }
        }
    }

    func updateReminder(_ reminder: ReminderItem, completion: ((String?) -> Void)? = nil) {
        let trimmedTitle = reminder.title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let uid = requireUID() else {
            completion?("You are not logged in.")
            return
        }

        let updated = ReminderItem(
            id: reminder.id,
            title: trimmedTitle.isEmpty ? "Untitled Reminder" : trimmedTitle,
            dueAt: reminder.dueAt,
            isDone: reminder.isDone,
            createdAt: reminder.createdAt
        )

        reminderDocument(uid: uid, reminderId: updated.id)
            .setData(reminderPayload(from: updated)) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("UPDATE REMINDER ERROR:", error.localizedDescription)
                        completion?(error.localizedDescription)
                    } else {
                        completion?(nil)
                    }
                }
            }
    }

    func toggleReminder(_ reminder: ReminderItem, completion: ((String?) -> Void)? = nil) {
        let toggled = ReminderItem(
            id: reminder.id,
            title: reminder.title,
            dueAt: reminder.dueAt,
            isDone: !reminder.isDone,
            createdAt: reminder.createdAt
        )
        updateReminder(toggled, completion: completion)
    }

    func deleteReminder(_ reminder: ReminderItem, completion: ((String?) -> Void)? = nil) {
        guard let uid = requireUID() else {
            completion?("You are not logged in.")
            return
        }

        reminderDocument(uid: uid, reminderId: reminder.id)
            .delete { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("DELETE REMINDER ERROR:", error.localizedDescription)
                        completion?(error.localizedDescription)
                    } else {
                        completion?(nil)
                    }
                }
            }
    }

    // MARK: - Local Only

    private func wireAutosave() {
        $workHours
            .dropFirst()
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveWorkHours() }
            .store(in: &cancellables)

        $goals
            .dropFirst()
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveGoals() }
            .store(in: &cancellables)

        $habits
            .dropFirst()
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveHabits() }
            .store(in: &cancellables)
    }

    func saveAll() {
        saveWorkHours()
        saveGoals()
        saveHabits()
    }

    private func saveWorkHours() {
        Persistence.shared.save(workHours, as: workFile)
    }

    private func saveGoals() {
        Persistence.shared.save(goals, as: goalsFile)
    }

    private func saveHabits() {
        Persistence.shared.save(habits, as: habitsFile)
    }
}
