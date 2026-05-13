//
//  WorkHoursView.swift
//  Task_Flow
//
//  Created by Aravind Ganipisetty
//

import SwiftUI

struct WorkHoursView: View {
    @EnvironmentObject var store: AppStore
    @AppStorage("tf_dark_mode") private var darkMode = false

    // MARK: - Screen State

    // Controls whether the screen shows work sessions or expenses.
    @State private var tab: WorkTab = .sessions

    // Controls whether data is filtered by month or year.
    @State private var periodMode: PeriodMode = .monthly

    // Stores the selected month index.
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date()) - 1

    // Stores the selected year.
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())

    // Stores search text used to filter sessions and expenses.
    @State private var searchText: String = ""

    // MARK: - Work Session Form State

    // Stores the selected work session date.
    @State private var wsDate: Date = Date()

    // Stores the work session start time.
    @State private var wsStart: Date = Date()

    // Stores the work session end time.
    @State private var wsEnd: Date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()

    // Stores hourly pay as text before converting it to Double.
    @State private var wsRate: String = ""

    // Stores optional work session notes.
    @State private var wsNotes: String = ""

    // MARK: - Expense Form State

    // Stores the selected expense date.
    @State private var exDate: Date = Date()

    // Stores the expense name.
    @State private var exName: String = ""

    // Stores the selected expense category.
    @State private var exType: ExpenseType = .food

    // Stores where the expense was used.
    @State private var exWhere: String = ""

    // Stores expense amount as text before converting it to Double.
    @State private var exAmount: String = ""

    // Month names used in the month picker.
    private let monthNames = Calendar.current.monthSymbols

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                background

                ScrollView {
                    VStack(spacing: 18) {
                        heroSection
                        topStatsSection
                        extraStatsSection
                        controlsSection
                        formsSection
                        recordsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 110)
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Hero Section

    // Top section with title, description, period mode, month picker, and year picker.
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Work Hours")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(primaryText)

            Text("Track your work sessions and earnings")
                .font(.subheadline)
                .foregroundStyle(secondaryText)

            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    periodButton("Monthly", mode: .monthly)
                    periodButton("Yearly", mode: .yearly)
                }

                HStack(spacing: 10) {
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(0..<monthNames.count, id: \.self) { idx in
                            Text(monthNames[idx]).tag(idx)
                        }
                    }
                    .disabled(periodMode == .yearly)
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .frame(height: 46)
                    .background(fieldFill)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .opacity(periodMode == .yearly ? 0.7 : 1)

                    Picker("Year", selection: $selectedYear) {
                        ForEach(availableYears, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .frame(height: 46)
                    .background(fieldFill)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Top Stats Section

    // Shows the main summary cards for total hours, earnings, and sessions.
    private var topStatsSection: some View {
        let stats = currentStats

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 14) {
            statCard(title: "Total Hours", value: hoursText(stats.totalHours), subtitle: "vs \(previousLabel)", accent: .purple)
            statCard(title: "Total Earnings", value: money(stats.totalEarnings), subtitle: "vs \(previousLabel)", accent: .orange)
            statCard(title: "Sessions", value: String(stats.totalSessions), subtitle: "in \(currentLabel)", accent: .purple)
        }
    }

    // MARK: - Extra Stats Section

    // Shows additional insights calculated from the current work sessions.
    private var extraStatsSection: some View {
        let stats = currentStats

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 2), spacing: 14) {
            pastelCard(title: "Avg Daily Hours", value: hoursText(stats.avgDailyHours), subtitle: "per day worked", tint: Color(red: 0.91, green: 0.95, blue: 1.0))
            pastelCard(title: "Earnings/Hour", value: money(stats.earningsPerHour), subtitle: "average rate", tint: Color(red: 0.91, green: 0.98, blue: 0.92))
            pastelCard(title: "Days Worked", value: String(stats.daysWorked), subtitle: "in this period", tint: Color(red: 0.96, green: 0.92, blue: 1.0))
            pastelCard(title: "Busiest Day", value: stats.busiestDay, subtitle: stats.busiestDay == "—" ? "no data" : "\(shortHours(stats.busiestDayHours)) worked", tint: Color(red: 0.97, green: 0.94, blue: 0.85))
        }
    }

    // MARK: - Controls Section

    // Contains search field and tab buttons for sessions and expenses.
    private var controlsSection: some View {
        VStack(spacing: 12) {
            TextField("Search sessions or expenses...", text: $searchText)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(fieldFill)
                .foregroundStyle(primaryText)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            HStack(spacing: 12) {
                tabButton(.sessions)
                tabButton(.expenses)
            }
        }
    }

    // MARK: - Forms Section

    // Contains both the work session form and expense form.
    private var formsSection: some View {
        VStack(spacing: 16) {
            workSessionForm
            expenseForm
        }
    }

    // MARK: - Work Session Form

    // Form used to add a new work session with date, time, hourly pay, and notes.
    private var workSessionForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Enter Work Time")
                .font(.title3.weight(.bold))
                .foregroundStyle(primaryText)

            twoColumnGrid {
                labeledDatePicker("Date", selection: $wsDate, displayed: [.date])
                labeledTextField("Hourly Pay ($)", text: $wsRate, placeholder: "e.g. 20", keyboard: .decimalPad)
                labeledDatePicker("Start Time", selection: $wsStart, displayed: [.hourAndMinute])
                labeledDatePicker("End Time", selection: $wsEnd, displayed: [.hourAndMinute])
            }

            HStack(spacing: 12) {
                liveValueCard(title: "Hours", value: shortHours(wsHours))
                liveValueCard(title: "Earnings", value: money(wsEarnings))
            }

            labeledTextField("Notes (optional)", text: $wsNotes, placeholder: "e.g. shift at store", keyboard: .default)

            Button(action: addWorkSession) {
                Text("Add Work Session")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.purple.opacity(0.92))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(18)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Expense Form

    // Form used to add a new expense with amount, name, type, and usage details.
    private var expenseForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Enter Expense")
                .font(.title3.weight(.bold))
                .foregroundStyle(primaryText)

            twoColumnGrid {
                labeledDatePicker("Date", selection: $exDate, displayed: [.date])
                labeledTextField("Amount ($)", text: $exAmount, placeholder: "e.g. 12.50", keyboard: .decimalPad)
                labeledTextField("Expense Name", text: $exName, placeholder: "e.g. Grocery", keyboard: .default)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Type")
                        .font(.headline)
                        .foregroundStyle(primaryText)

                    Picker("Type", selection: $exType) {
                        ForEach(ExpenseType.allCases, id: \.self) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .padding(.horizontal, 12)
                    .background(fieldFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }

            labeledTextField("Where / Used For (optional)", text: $exWhere, placeholder: "e.g. Walmart, Uber, etc.", keyboard: .default)

            Button(action: addExpense) {
                Text("Add Expense")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.orange.opacity(0.85))
                    .foregroundStyle(darkMode ? .white : .black)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(18)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Records Section

    // Displays filtered work sessions or expenses based on the selected tab.
    private var recordsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(tab == .sessions ? "Work Sessions" : "Expenses")
                .font(.title3.weight(.bold))
                .foregroundStyle(primaryText)

            if tab == .sessions {
                if visibleSessions.isEmpty {
                    emptyCard("No sessions found.")
                } else {
                    VStack(spacing: 12) {
                        ForEach(visibleSessions) { session in
                            sessionRow(session)
                        }
                    }
                }
            } else {
                if visibleExpenses.isEmpty {
                    emptyCard("No expenses found.")
                } else {
                    VStack(spacing: 12) {
                        ForEach(visibleExpenses) { expense in
                            expenseRow(expense)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Period Button

    // Reusable button for switching between monthly and yearly views.
    private func periodButton(_ title: String, mode: PeriodMode) -> some View {
        Button {
            periodMode = mode
        } label: {
            Text(title)
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(periodMode == mode ? Color.purple : fieldFill)
                .foregroundStyle(periodMode == mode ? .white : primaryText)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Tab Button

    // Reusable button for switching between session records and expense records.
    private func tabButton(_ value: WorkTab) -> some View {
        Button {
            tab = value
        } label: {
            Text(value.title)
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(tab == value ? Color.purple : buttonFill)
                .foregroundStyle(tab == value ? .white : primaryText)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Stat Card

    // Reusable summary card for the top statistics section.
    private func statCard(title: String, value: String, subtitle: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(secondaryText)

            Text(value)
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(primaryText)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .padding(18)
        .background(cardFill)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(accent.opacity(0.20), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Pastel Card

    // Reusable card for extra work analytics.
    private func pastelCard(title: String, value: String, subtitle: String, tint: Color) -> some View {
        let fill = darkMode ? Color.white.opacity(0.08) : tint

        return VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.heavy))
                .foregroundStyle(secondaryText)

            Text(value)
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(primaryText)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .padding(18)
        .background(fill)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Live Value Card

    // Shows live calculated hours and earnings before saving a work session.
    private func liveValueCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(secondaryText)

            Text(value)
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(Color.purple)
        }
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
        .padding(14)
        .background(darkMode ? Color.white.opacity(0.08) : Color(red: 0.95, green: 0.94, blue: 0.98))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.purple.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Labeled Text Field

    // Reusable labeled text field used by work session and expense forms.
    private func labeledTextField(_ label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.headline)
                .foregroundStyle(primaryText)

            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .foregroundStyle(primaryText)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(fieldFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - Labeled Date Picker

    // Reusable labeled date picker used for dates and times.
    private func labeledDatePicker(_ label: String, selection: Binding<Date>, displayed: DatePickerComponents) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.headline)
                .foregroundStyle(primaryText)

            DatePicker("", selection: selection, displayedComponents: displayed)
                .labelsHidden()
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                .padding(.horizontal, 14)
                .background(fieldFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - Two Column Grid

    // Reusable two-column layout for form inputs.
    private func twoColumnGrid<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            content()
        }
    }

    // MARK: - Session Row

    // Displays one saved work session with date, time, hours, pay, notes, and delete action.
    private func sessionRow(_ session: WorkSessionRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(formatDate(session.date))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(primaryText)

                Spacer()

                Text(money(session.earnings))
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Color.purple)
            }

            Text("\(weekdayName(session.date)) • \(formatTime(session.startTime)) → \(formatTime(session.endTime))")
                .font(.subheadline)
                .foregroundStyle(secondaryText)

            HStack {
                Text("Hours: \(shortHours(session.hours))")
                Spacer()
                Text("Pay: \(money(session.hourlyPay))")
            }
            .font(.subheadline)
            .foregroundStyle(secondaryText)

            if !session.notes.isEmpty {
                Text(session.notes)
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)
            }

            Button(role: .destructive) {
                store.deleteWorkSession(session)
            } label: {
                Label("Delete", systemImage: "trash")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Expense Row

    // Displays one saved expense with type, date, amount, details, and delete action.
    private func expenseRow(_ expense: ExpenseRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(expense.name)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(primaryText)

                Spacer()

                Text(money(expense.amount))
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Color.orange)
            }

            Text("\(expense.type.rawValue) • \(formatDate(expense.date))")
                .font(.subheadline)
                .foregroundStyle(secondaryText)

            if !expense.whereUsed.isEmpty {
                Text(expense.whereUsed)
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)
            }

            Button(role: .destructive) {
                store.deleteExpense(expense)
            } label: {
                Label("Delete", systemImage: "trash")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Empty Card

    // Displays a simple empty state when no records match the current filter.
    private func emptyCard(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(secondaryText)
            .frame(maxWidth: .infinity)
            .padding(18)
            .background(cardFill)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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

    // Primary text color based on the selected theme.
    private var primaryText: Color {
        darkMode ? .white : .black
    }

    // Secondary text color used for subtitles and helper text.
    private var secondaryText: Color {
        darkMode ? .white.opacity(0.68) : .black.opacity(0.58)
    }

    // Main card background color.
    private var cardFill: Color {
        darkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.92)
    }

    // Input field background color.
    private var fieldFill: Color {
        darkMode ? Color.white.opacity(0.10) : Color.white
    }

    // Button background color for inactive controls.
    private var buttonFill: Color {
        darkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.06)
    }

    // Border color for input fields.
    private var borderColor: Color {
        darkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.12)
    }

    // MARK: - Filtered Data

    // Work sessions matching the selected month or year.
    private var currentSessions: [WorkSessionRecord] {
        store.workSessions.filter { isInSelectedPeriod($0.date) }
    }

    // Expenses matching the selected month or year.
    private var currentExpenses: [ExpenseRecord] {
        store.expenses.filter { isInSelectedPeriod($0.date) }
    }

    // Work sessions filtered by search text and sorted by newest first.
    private var visibleSessions: [WorkSessionRecord] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return currentSessions
            .filter {
                q.isEmpty ||
                $0.notes.lowercased().contains(q) ||
                formatDate($0.date).lowercased().contains(q) ||
                weekdayName($0.date).lowercased().contains(q)
            }
            .sorted { $0.date > $1.date }
    }

    // Expenses filtered by search text and sorted by newest first.
    private var visibleExpenses: [ExpenseRecord] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return currentExpenses
            .filter {
                q.isEmpty ||
                $0.name.lowercased().contains(q) ||
                $0.whereUsed.lowercased().contains(q) ||
                $0.type.rawValue.lowercased().contains(q)
            }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Stats Data

    // Builds work statistics from the currently filtered sessions.
    private var currentStats: WorkStats {
        makeStats(from: currentSessions)
    }

    // Label for the selected current period.
    private var currentLabel: String {
        periodMode == .yearly ? "\(selectedYear)" : "\(monthNames[selectedMonth]) \(selectedYear)"
    }

    // Label for the previous comparison period.
    private var previousLabel: String {
        let previous = previousPeriod()
        return periodLabel(mode: previous.mode, month: previous.month, year: previous.year)
    }

    // Year options shown in the year picker.
    private var availableYears: [Int] {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 5)...(current + 5))
    }

    // MARK: - Live Work Session Calculations

    // Calculates hours from the work session form before saving.
    private var wsHours: Double {
        let start = mergedDate(date: wsDate, time: wsStart)
        let rawEnd = mergedDate(date: wsDate, time: wsEnd)
        let end = adjustedEndDate(start: start, end: rawEnd)

        return max(0, end.timeIntervalSince(start) / 3600)
    }

    // Calculates earnings from current form hours and hourly rate.
    private var wsEarnings: Double {
        let rate = Double(wsRate) ?? 0
        return wsHours * rate
    }

    // MARK: - Add Work Session

    // Validates and saves a new work session through AppStore.
    private func addWorkSession() {
        let rate = Double(wsRate) ?? 0
        let start = mergedDate(date: wsDate, time: wsStart)
        let rawEnd = mergedDate(date: wsDate, time: wsEnd)
        let end = adjustedEndDate(start: start, end: rawEnd)

        let hours = max(0, end.timeIntervalSince(start) / 3600)

        guard hours > 0 else {
            return
        }

        let entry = WorkSessionRecord(
            date: wsDate,
            startTime: start,
            endTime: end,
            hourlyPay: rate,
            notes: wsNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        store.addWorkSession(entry)

        wsRate = ""
        wsNotes = ""
        wsStart = Date()
        wsEnd = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    }

    // MARK: - Add Expense

    // Validates and saves a new expense through AppStore.
    private func addExpense() {
        guard let amount = Double(exAmount), amount > 0 else {
            return
        }

        let cleanName = exName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanWhere = exWhere.trimmingCharacters(in: .whitespacesAndNewlines)

        let entry = ExpenseRecord(
            date: exDate,
            name: cleanName.isEmpty ? "Expense" : cleanName,
            type: exType,
            whereUsed: cleanWhere,
            amount: amount
        )

        store.addExpense(entry)

        exName = ""
        exWhere = ""
        exAmount = ""
        exType = .food
    }

    // MARK: - Period Helpers

    // Checks whether a date belongs to the selected month or year.
    private func isInSelectedPeriod(_ date: Date) -> Bool {
        let y = Calendar.current.component(.year, from: date)
        let m = Calendar.current.component(.month, from: date) - 1

        if periodMode == .yearly {
            return y == selectedYear
        }

        return y == selectedYear && m == selectedMonth
    }

    // Returns the previous period used for comparison labels.
    private func previousPeriod() -> (mode: PeriodMode, month: Int, year: Int) {
        if periodMode == .yearly {
            return (.yearly, selectedMonth, selectedYear - 1)
        }

        if selectedMonth == 0 {
            return (.monthly, 11, selectedYear - 1)
        }

        return (.monthly, selectedMonth - 1, selectedYear)
    }

    // Creates a readable label for a month or year period.
    private func periodLabel(mode: PeriodMode, month: Int, year: Int) -> String {
        mode == .yearly ? "\(year)" : "\(monthNames[month]) \(year)"
    }

    // MARK: - Stats Builder

    // Calculates total hours, earnings, sessions, averages, and busiest day.
    private func makeStats(from source: [WorkSessionRecord]) -> WorkStats {
        let totalHours = source.reduce(0) { $0 + $1.hours }
        let totalEarnings = source.reduce(0) { $0 + $1.earnings }
        let totalSessions = source.count

        let uniqueDays = Set(source.map { Calendar.current.startOfDay(for: $0.date) })
        let daysWorked = uniqueDays.count
        let avgDailyHours = daysWorked == 0 ? 0 : totalHours / Double(daysWorked)
        let earningsPerHour = totalHours == 0 ? 0 : totalEarnings / totalHours

        var weekdayHours: [String: Double] = [:]

        for item in source {
            let dayName = weekdayName(item.date)
            weekdayHours[dayName, default: 0] += item.hours
        }

        let busiest = weekdayHours.max(by: { $0.value < $1.value })

        return WorkStats(
            totalHours: totalHours,
            totalEarnings: totalEarnings,
            totalSessions: totalSessions,
            avgDailyHours: avgDailyHours,
            earningsPerHour: earningsPerHour,
            daysWorked: daysWorked,
            busiestDay: busiest?.key ?? "—",
            busiestDayHours: busiest?.value ?? 0
        )
    }

    // MARK: - Date Helpers

    // Combines a selected date with a selected time.
    private func mergedDate(date: Date, time: Date) -> Date {
        let d = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let t = Calendar.current.dateComponents([.hour, .minute], from: time)

        var comps = DateComponents()
        comps.year = d.year
        comps.month = d.month
        comps.day = d.day
        comps.hour = t.hour
        comps.minute = t.minute

        return Calendar.current.date(from: comps) ?? date
    }

    // Allows overnight shifts by moving the end time to the next day when needed.
    private func adjustedEndDate(start: Date, end: Date) -> Date {
        if end >= start {
            return end
        }

        return Calendar.current.date(byAdding: .day, value: 1, to: end) ?? end
    }

    // MARK: - Formatting Helpers

    // Formats a date without time.
    private func formatDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    // Returns the full weekday name for a date.
    private func weekdayName(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide))
    }

    // Formats only the time from a date.
    private func formatTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    // Formats a value as money.
    private func money(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }

    // Formats hours with one decimal place.
    private func hoursText(_ value: Double) -> String {
        "\(String(format: "%.1f", value))h"
    }

    // Formats hours with two decimal places for detailed records.
    private func shortHours(_ value: Double) -> String {
        "\(String(format: "%.2f", value))h"
    }
}
