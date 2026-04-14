//
//  Models.swift
//  Task_Flow
//

import Foundation

struct TaskItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var isDone: Bool = false
    var createdAt: Date = Date()
}

struct NoteItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var body: String
    var createdAt: Date = Date()
    var colorSeed: Int = Int.random(in: 0...10_000)
}

struct WorkHourEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var startTime: Date
    var endTime: Date
    var breakMinutes: Int
}

struct GoalItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var targetDate: Date
    var progress: Double = 0.0
    var createdAt: Date = Date()
}

struct HabitItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var streak: Int = 0
    var lastCompleted: Date? = nil
    var createdAt: Date = Date()
    var isCompletedToday: Bool = false
}

struct ReminderItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var dueAt: Date = Date()
    var isDone: Bool = false
    var createdAt: Date = Date()
}
