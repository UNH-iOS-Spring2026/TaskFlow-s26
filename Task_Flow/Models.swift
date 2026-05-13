//
//  Models.swift
//  Task_Flow
//
//  Created by Aravind Ganipisetty
//

import Foundation

// MARK: - Task Model

// Represents a dashboard task created by the user.
struct TaskItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var isDone: Bool = false
    var createdAt: Date = Date()
}

// MARK: - Note Model

// Represents a saved note with title, body, creation date, and color seed.
struct NoteItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var body: String
    var createdAt: Date = Date()
    var colorSeed: Int = Int.random(in: 0...10_000)
}

// MARK: - Reminder Model

// Represents a time-based reminder and optional location-based reminder.
struct ReminderItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var dueAt: Date = Date()
    var isDone: Bool = false
    var createdAt: Date = Date()

    // Location-based reminder fields used by Core Location.
    var locationName: String? = nil
    var latitude: Double? = nil
    var longitude: Double? = nil
    var radiusMeters: Double = 150
    var notifyOnEntry: Bool = true
    var notifyOnExit: Bool = false

    // Checks whether this reminder has saved location coordinates.
    var hasLocationReminder: Bool {
        latitude != nil && longitude != nil
    }

    // Unique notification ID for the backup deadline notification.
    var deadlineNotificationId: String {
        "deadline-\(id.uuidString)"
    }

    // Unique notification ID for the location-based notification.
    var locationNotificationId: String {
        "location-\(id.uuidString)"
    }
}

// MARK: - Habit Model

// Represents a habit with streak tracking and daily completion status.
struct HabitItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var streak: Int = 0
    var lastCompleted: Date? = nil
    var createdAt: Date = Date()
    var isCompletedToday: Bool = false
}

// MARK: - Expense Type

// Categories used to classify expense entries.
enum ExpenseType: String, CaseIterable, Codable, Equatable {
    case food = "Food"
    case transport = "Transport"
    case bills = "Bills"
    case shopping = "Shopping"
    case health = "Health"
    case entertainment = "Entertainment"
    case other = "Other"
}

// MARK: - Work Session Model

// Represents one work session with start time, end time, hourly pay, and notes.
struct WorkSessionRecord: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var startTime: Date
    var endTime: Date
    var hourlyPay: Double
    var notes: String

    // Calculates total worked hours for the session.
    var hours: Double {
        max(0, endTime.timeIntervalSince(startTime) / 3600)
    }

    // Calculates earnings based on hours and hourly pay.
    var earnings: Double {
        hours * hourlyPay
    }
}

// MARK: - Expense Model

// Represents one expense entry used for spending tracking.
struct ExpenseRecord: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var name: String
    var type: ExpenseType
    var whereUsed: String
    var amount: Double
}

// MARK: - Goal Model

// Represents a goal with name, description, and target date.
struct GoalRecord: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var goalName: String
    var goalDescription: String
    var targetDate: Date
}

// MARK: - Work Stats Model

// Stores calculated work summary values for analytics and reporting.
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

// MARK: - Work Tab Type

// Defines the two main sections inside the Work screen.
enum WorkTab {
    case sessions
    case expenses

    // Display title for the selected work tab.
    var title: String {
        switch self {
        case .sessions:
            return "Sessions"
        case .expenses:
            return "Expenses"
        }
    }
}

// MARK: - Period Mode

// Defines whether work analytics are grouped monthly or yearly.
enum PeriodMode {
    case monthly
    case yearly
}
