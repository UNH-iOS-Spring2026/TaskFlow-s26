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

struct ReminderItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var dueAt: Date = Date()
    var isDone: Bool = false
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

enum ExpenseType: String, CaseIterable, Codable, Equatable {
    case food = "Food"
    case transport = "Transport"
    case bills = "Bills"
    case shopping = "Shopping"
    case health = "Health"
    case entertainment = "Entertainment"
    case other = "Other"
}

struct WorkSessionRecord: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var startTime: Date
    var endTime: Date
    var hourlyPay: Double
    var notes: String

    var hours: Double {
        max(0, endTime.timeIntervalSince(startTime) / 3600)
    }

    var earnings: Double {
        hours * hourlyPay
    }
}

struct ExpenseRecord: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var name: String
    var type: ExpenseType
    var whereUsed: String
    var amount: Double
}

struct GoalRecord: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var goalName: String
    var goalDescription: String
    var targetDate: Date
}

struct WorkStats {
    var totalHours: Double
    var totalEarnings: Double
    var totalSessions: Int
    var avgDailyHours: Double
    var earningsPerHour: Double
    var daysWorked: Int
    var busiestDay: String
    var busiestDayHours: Double
}

enum WorkTab {
    case sessions
    case expenses

    var title: String {
        switch self {
        case .sessions:
            return "Sessions"
        case .expenses:
            return "Expenses"
        }
    }
}

enum PeriodMode {
    case monthly
    case yearly
}
