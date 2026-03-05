//
//  AppStore.swift
//  Task_Flow
//
//  Created by Aravind Ganipisetty on 2/11/26.
//

import Foundation
import Combine

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

    private var cancellables = Set<AnyCancellable>()

    init() {
        self.auth = AuthStore()

        // ✅ Forward AuthStore changes so RootView refreshes
        auth.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        // ✅ Load from disk
        tasks = Persistence.shared.load([TaskItem].self, from: tasksFile, default: [])
        reminders = Persistence.shared.load([ReminderItem].self, from: remindersFile, default: [])
        notes = Persistence.shared.load([NoteItem].self, from: notesFile, default: [])
        workHours = Persistence.shared.load([WorkHourEntry].self, from: workFile, default: [])
        goals = Persistence.shared.load([GoalItem].self, from: goalsFile, default: [])
        habits = Persistence.shared.load([HabitItem].self, from: habitsFile, default: [])

        // ✅ Auto-save when arrays change (debounced)
        wireAutosave()
    }
    // MARK: - Autosave
    private func wireAutosave() {
        // Debounce so we don’t write to disk 50 times while typing
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

    // MARK: - Manual Save (still available)
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
