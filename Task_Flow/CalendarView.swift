//
//  CalendarView.swift
//  Task_Flow
import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var store: AppStore
    @AppStorage("tf_dark_mode") private var darkMode = false

    // MARK: - Calendar State

    // Controls which month is currently displayed.
    @State private var monthOffset: Int = 0

    // Stores the date selected by the user in the calendar grid.
    @State private var selectedDate: Date = Date()

    // MARK: - Reminder Form State

    // Controls the Add Reminder sheet.
    @State private var showAddReminder = false

    // Stores the reminder title entered by the user.
    @State private var newTitle = ""

    // Stores the selected reminder date and time.
    @State private var newTime = Date()

    // Calendar helper used for date calculations.
    private let cal = Calendar.current

    var body: some View {
        NavigationStack {
            ZStack {
                background

                ScrollView {
                    VStack(spacing: 12) {
                        header
                        monthCardCompact
                        dayPanel
                    }
                    .padding(.horizontal)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 110)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddReminder) {
                addReminderSheet
                    .preferredColorScheme(darkMode ? .dark : .light)
            }
        }
    }

    // MARK: - Header

    // Displays the title and short description for the Calendar screen.
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Calendar")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(primaryText)

            Text("Manage your reminders, birthdays, and events")
                .foregroundStyle(secondaryText)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    // MARK: - Month Calendar Card

    // Compact monthly calendar view with previous and next month navigation.
    private var monthCardCompact: some View {
        let monthDate = monthBaseDate
        let monthTitle = monthDate.formatted(.dateTime.month(.wide).year())

        return VStack(spacing: 10) {
            HStack {
                Text(monthTitle)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(primaryText)

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        monthOffset -= 1
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(primaryText)
                    .background(buttonFill)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Button {
                        monthOffset += 1
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(primaryText)
                    .background(buttonFill)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }

            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(secondaryText)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7),
                spacing: 6
            ) {
                ForEach(compactMonthDays) { day in
                    compactDayCell(day)
                }
            }
        }
        .padding(12)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Day Cell

    // Creates one day cell in the monthly calendar grid.
    private func compactDayCell(_ day: MonthDay) -> some View {
        let isSelected = cal.isDate(day.date, inSameDayAs: selectedDate)
        let isToday = cal.isDateInToday(day.date)
        let inMonth = day.isInMonth

        // Shows a small orange dot when the day has at least one reminder.
        let hasReminder = store.reminders.contains {
            cal.isDate($0.dueAt, inSameDayAs: day.date)
        }

        return Button {
            selectedDate = day.date
        } label: {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        isSelected
                        ? Color.purple.opacity(0.70)
                        : cellFill(inMonth: inMonth)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isToday ? Color.purple.opacity(0.95) : Color.clear, lineWidth: 2)
                    )

                Text("\(cal.component(.day, from: day.date))")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(
                        isSelected
                        ? AnyShapeStyle(.white)
                        : AnyShapeStyle(inMonth ? primaryText : secondaryText.opacity(0.45))
                    )

                if hasReminder {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 5, height: 5)
                        .padding(.bottom, 4)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(height: 36)
    }

    // MARK: - Selected Day Panel

    // Shows pending and completed reminders for the selected calendar date.
    private var dayPanel: some View {
        let headerDate = selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
        let pending = remindersForSelectedDate.filter { !$0.isDone }
        let completed = remindersForSelectedDate.filter { $0.isDone }

        return VStack(alignment: .leading, spacing: 12) {
            Text(selectedDate.formatted(.dateTime.weekday(.wide)))
                .font(.title3.weight(.bold))
                .foregroundStyle(primaryText)

            Text(headerDate)
                .foregroundStyle(secondaryText)
                .font(.subheadline)

            Button {
                newTitle = ""
                newTime = selectedDate
                showAddReminder = true
            } label: {
                Text("+ Add Reminder")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.purple.opacity(0.88))

            sectionHeader(title: "Pending", count: pending.count)

            if pending.isEmpty {
                emptyLine("No pending reminders")
            } else {
                VStack(spacing: 10) {
                    ForEach(pending) { reminder in
                        reminderRow(reminder)
                    }
                }
            }

            sectionHeader(title: "Completed", count: completed.count)

            if completed.isEmpty {
                emptyLine("No completed reminders")
            } else {
                VStack(spacing: 10) {
                    ForEach(completed) { reminder in
                        reminderRow(reminder)
                    }
                }
            }
        }
        .padding(14)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Section Header

    // Reusable section header used for Pending and Completed reminder groups.
    private func sectionHeader(title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(primaryText)

            Spacer()

            Text("\(count)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(primaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(buttonFill)
                .clipShape(Capsule())
        }
        .padding(.top, 2)
    }

    // MARK: - Empty State

    // Displays a simple message when there are no reminders in a section.
    private func emptyLine(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(secondaryText)
            .padding(.bottom, 2)
    }

    // MARK: - Reminder Row

    // Displays one reminder with complete and delete actions.
    private func reminderRow(_ reminder: ReminderItem) -> some View {
        HStack(spacing: 10) {
            Button {
                store.toggleReminder(reminder)
            } label: {
                Image(systemName: reminder.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(reminder.isDone ? .green : secondaryText)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .foregroundStyle(primaryText)
                    .lineLimit(1)

                Text(reminder.dueAt.formatted(date: .omitted, time: .shortened))
                    .font(.footnote)
                    .foregroundStyle(secondaryText)
            }

            Spacer()

            Button(role: .destructive) {
                store.deleteReminder(reminder)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
                    .padding(8)
                    .background(buttonFill)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(rowFill)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Add Reminder Sheet

    // Sheet used to create a new reminder for the selected date.
    private var addReminderSheet: some View {
        NavigationStack {
            Form {
                TextField("Reminder title", text: $newTitle)

                DatePicker(
                    "Time",
                    selection: $newTime,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
            .navigationTitle("Add Reminder")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showAddReminder = false
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveReminder()
                    }
                    .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    // MARK: - Save Reminder

    // Saves the reminder through AppStore after combining the selected day and time.
    private func saveReminder() {
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
            return
        }

        let correctedDate = merge(date: selectedDate, time: newTime)

        store.addReminder(title: title, dueAt: correctedDate)

        newTitle = ""
        newTime = Date()
        showAddReminder = false
    }

    // MARK: - Calendar Date Helpers

    // Short weekday symbols shown above the calendar grid.
    private var weekdays: [String] {
        cal.shortWeekdaySymbols
    }

    // Calculates the visible month based on the current month offset.
    private var monthBaseDate: Date {
        let now = Date()
        return cal.date(byAdding: .month, value: monthOffset, to: startOfMonth(now)) ?? now
    }

    // Returns the first day of the month for a given date.
    private func startOfMonth(_ date: Date) -> Date {
        let comps = cal.dateComponents([.year, .month], from: date)
        return cal.date(from: comps) ?? date
    }

    // Builds all day cells needed for the compact calendar grid.
    private var compactMonthDays: [MonthDay] {
        let monthStart = monthBaseDate
        let range = cal.range(of: .day, in: .month, for: monthStart) ?? 1..<2
        let daysCount = range.count

        let firstWeekday = cal.component(.weekday, from: monthStart)
        let leading = (firstWeekday - cal.firstWeekday + 7) % 7

        var result: [MonthDay] = []

        if leading > 0 {
            for i in 0..<leading {
                let date = cal.date(byAdding: .day, value: -(leading - i), to: monthStart) ?? monthStart
                result.append(MonthDay(date: date, isInMonth: false))
            }
        }

        for day in 1...daysCount {
            let date = cal.date(byAdding: .day, value: day - 1, to: monthStart) ?? monthStart
            result.append(MonthDay(date: date, isInMonth: true))
        }

        while result.count % 7 != 0 {
            let last = result.last?.date ?? monthStart
            let next = cal.date(byAdding: .day, value: 1, to: last) ?? last
            result.append(MonthDay(date: next, isInMonth: false))
        }

        return result
    }

    // Filters reminders to show only items for the selected date.
    private var remindersForSelectedDate: [ReminderItem] {
        store.reminders
            .filter { cal.isDate($0.dueAt, inSameDayAs: selectedDate) }
            .sorted { $0.dueAt < $1.dueAt }
    }

    // Combines the selected calendar day with the selected reminder time.
    private func merge(date: Date, time: Date) -> Date {
        let dateComponents = cal.dateComponents([.year, .month, .day], from: date)
        let timeComponents = cal.dateComponents([.hour, .minute], from: time)

        var components = DateComponents()
        components.year = dateComponents.year
        components.month = dateComponents.month
        components.day = dateComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        return cal.date(from: components) ?? date
    }

    // MARK: - Theme

    // Main screen background for light and dark mode.
    private var background: some View {
        LinearGradient(
            colors: darkMode
            ? [
                Color.black,
                Color(red: 8/255, green: 12/255, blue: 42/255),
                Color.black
            ]
            : [
                Color(red: 0.96, green: 0.97, blue: 1.00),
                Color.white,
                Color(red: 0.91, green: 0.94, blue: 1.00)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // Main text color based on selected theme.
    private var primaryText: Color {
        darkMode ? .white : .black
    }

    // Secondary text color based on selected theme.
    private var secondaryText: Color {
        darkMode ? .white.opacity(0.66) : .black.opacity(0.58)
    }

    // Card background color for calendar and reminder sections.
    private var cardFill: Color {
        darkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.92)
    }

    // Reminder row background color.
    private var rowFill: Color {
        darkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.04)
    }

    // Small button background color.
    private var buttonFill: Color {
        darkMode ? Color.white.opacity(0.10) : Color.black.opacity(0.06)
    }

    // Calendar day cell background color.
    private func cellFill(inMonth: Bool) -> Color {
        if darkMode {
            return Color.white.opacity(inMonth ? 0.10 : 0.05)
        } else {
            return Color.black.opacity(inMonth ? 0.055 : 0.025)
        }
    }
}

// MARK: - Month Day Model

// Represents one visible day cell in the calendar grid.
struct MonthDay: Identifiable {
    let id = UUID()
    let date: Date
    let isInMonth: Bool
}
