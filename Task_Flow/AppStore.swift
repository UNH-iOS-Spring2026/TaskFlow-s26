//
//  AppStore.swift
//  Task_Flow
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class AppStore: ObservableObject {

    // MARK: - Stores
    @Published var auth: AuthStore

    // MARK: - Data
    @Published var tasks: [TaskItem] = []
    @Published var reminders: [ReminderItem] = []
    @Published var notes: [NoteItem] = []
    @Published var workHours: [WorkHourEntry] = []
    @Published var goals: [GoalItem] = []
    @Published var habits: [HabitItem] = []

    // MARK: - Files
    private let tasksFile = "tasks.json"
    private let remindersFile = "reminders.json"
    private let notesFile = "notes.json"
    private let workFile  = "workhours.json"
    private let goalsFile = "goals.json"
    private let habitsFile = "habits.json"

    private let db = Firestore.firestore()
    private var notesListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()

    init(auth: AuthStore) {
        self.auth = auth

        // load local data
        tasks = Persistence.shared.load([TaskItem].self, from: tasksFile, default: [])
        reminders = Persistence.shared.load([ReminderItem].self, from: remindersFile, default: [])
        notes = Persistence.shared.load([NoteItem].self, from: notesFile, default: [])
        workHours = Persistence.shared.load([WorkHourEntry].self, from: workFile, default: [])
        goals = Persistence.shared.load([GoalItem].self, from: goalsFile, default: [])
        habits = Persistence.shared.load([HabitItem].self, from: habitsFile, default: [])

        // keep RootView/UI refreshed when auth changes
        auth.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        wireAutosave()
        bindAuth()
    }

    deinit {
        notesListener?.remove()
    }

    // MARK: - Auth binding
    private func bindAuth() {
        auth.$currentUserId
            .receive(on: RunLoop.main)
            .sink { [weak self] uid in
                self?.handleAuthChange(uid: uid)
            }
            .store(in: &cancellables)
    }

    private func handleAuthChange(uid: String?) {
        notesListener?.remove()
        notesListener = nil

        guard let uid, !uid.isEmpty else {
            notes = []
            return
        }

        startNotesListener(for: uid)
    }

    // MARK: - Notes Firestore sync
    private func startNotesListener(for uid: String) {
        notesListener = db.collection("users")
            .document(uid)
            .collection("notes")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error = error {
                    print("NOTES LISTENER ERROR:", error.localizedDescription)
                    return
                }

                let items = snapshot?.documents.compactMap { self.makeNote(from: $0) } ?? []

                DispatchQueue.main.async {
                    self.notes = items
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
            "createdAt": Timestamp(date: note.createdAt),
            "colorSeed": note.colorSeed
        ]
    }

    func addNote(title: String, body: String, colorSeed: Int, completion: ((String?) -> Void)? = nil) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty || !trimmedBody.isEmpty else {
            completion?("Note cannot be empty.")
            return
        }

        let note = NoteItem(
            title: trimmedTitle.isEmpty ? "Untitled" : trimmedTitle,
            body: trimmedBody,
            createdAt: Date(),
            colorSeed: colorSeed
        )

        guard let uid = auth.currentUserId, !uid.isEmpty else {
            notes.insert(note, at: 0)
            saveNotes()
            completion?(nil)
            return
        }

        db.collection("users")
            .document(uid)
            .collection("notes")
            .document(note.id.uuidString)
            .setData(notePayload(from: note)) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("ADD NOTE ERROR:", error.localizedDescription)
                        completion?(error.localizedDescription)
                    } else {
                        completion?(nil)
                    }
                }
            }
    }

    func updateNote(id: UUID, title: String, body: String, colorSeed: Int, completion: ((String?) -> Void)? = nil) {
        guard let existing = notes.first(where: { $0.id == id }) else {
            completion?("Note not found.")
            return
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)

        let updated = NoteItem(
            id: existing.id,
            title: trimmedTitle.isEmpty ? "Untitled" : trimmedTitle,
            body: trimmedBody,
            createdAt: existing.createdAt,
            colorSeed: colorSeed
        )

        guard let uid = auth.currentUserId, !uid.isEmpty else {
            if let idx = notes.firstIndex(where: { $0.id == id }) {
                notes[idx] = updated
                saveNotes()
            }
            completion?(nil)
            return
        }

        db.collection("users")
            .document(uid)
            .collection("notes")
            .document(id.uuidString)
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
        guard let uid = auth.currentUserId, !uid.isEmpty else {
            notes.removeAll { $0.id == note.id }
            saveNotes()
            completion?(nil)
            return
        }

        db.collection("users")
            .document(uid)
            .collection("notes")
            .document(note.id.uuidString)
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

    // MARK: - Autosave
    private func wireAutosave() {
        $tasks
            .dropFirst()
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveTasks() }
            .store(in: &cancellables)

        $reminders
            .dropFirst()
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveReminders() }
            .store(in: &cancellables)

        // notes are cached locally too, but actual source of truth is Firestore
        $notes
            .dropFirst()
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveNotes() }
            .store(in: &cancellables)

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

    // MARK: - Manual Save
    func saveAll() {
        saveTasks()
        saveReminders()
        saveNotes()
        saveWorkHours()
        saveGoals()
        saveHabits()
    }

    private func saveTasks()     { Persistence.shared.save(tasks, as: tasksFile) }
    private func saveReminders() { Persistence.shared.save(reminders, as: remindersFile) }
    private func saveNotes()     { Persistence.shared.save(notes, as: notesFile) }
    private func saveWorkHours() { Persistence.shared.save(workHours, as: workFile) }
    private func saveGoals()     { Persistence.shared.save(goals, as: goalsFile) }
    private func saveHabits()    { Persistence.shared.save(habits, as: habitsFile) }
}
