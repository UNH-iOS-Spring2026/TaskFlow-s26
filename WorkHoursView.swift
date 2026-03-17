
//
//  WorkHoursView.swift
//  Task_Flow
//
//  Created by Aravind Ganipisetty on 3/08/26.
//

import SwiftUI

struct WorkHoursView: View {
    @State private var tab: WorkTab = .sessions
    @State private var periodMode: PeriodMode = .monthly
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date()) - 1
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var searchText: String = ""

    @State private var sessions: [WorkSessionRecord] = []
    @State private var expenses: [ExpenseRecord] = []

    // Work session form
    @State private var wsDate: Date = Date()
    @State private var wsStart: Date = Date()
    @State private var wsEnd: Date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var wsRate: String = ""
    @State private var wsNotes: String = ""

    // Expense form
    @State private var exDate: Date = Date()
    @State private var exName: String = ""
    @State private var exType: ExpenseType = .food
    @State private var exWhere: String = ""
    @State private var exAmount: String = ""

    private let monthNames = Calendar.current.monthSymbols
    private let sessionsKey = "taskflow_work_sessions_v1"
    private let expensesKey = "taskflow_work_expenses_v1"

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
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadData()
            }
        }
    }

    // MARK: - UI

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Work Hours")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)

            Text("Track your work sessions and earnings")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.88))

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
                    .background(Color.white)
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
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var topStatsSection: some View {
        let stats = currentStats

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 14) {
            statCard(
                title: "Total Hours",
                value: hoursText(stats.totalHours),
                subtitle: "vs \(previousLabel)",
                accent: .purple
            )

            statCard(
                title: "Total Earnings",
                value: money(stats.totalEarnings),
                subtitle: "vs \(previousLabel)",
                accent: .orange
            )

            statCard(
                title: "Sessions",
                value: String(stats.totalSessions),
                subtitle: "in \(currentLabel)",
                accent: .purple
            )
        }
    }

    private var extraStatsSection: some View {
        let stats = currentStats

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 2), spacing: 14) {
            pastelCard(
                title: "Avg Daily Hours",
                value: hoursText(stats.avgDailyHours),
                subtitle: "per day worked",
                tint: Color(red: 0.91, green: 0.95, blue: 1.0)
            )

            pastelCard(
                title: "Earnings/Hour",
                value: money(stats.earningsPerHour),
                subtitle: "average rate",
                tint: Color(red: 0.91, green: 0.98, blue: 0.92)
            )

            pastelCard(
                title: "Days Worked",
                value: String(stats.daysWorked),
                subtitle: "in this period",
                tint: Color(red: 0.96, green: 0.92, blue: 1.0)
            )

            pastelCard(
                title: "Busiest Day",
                value: stats.busiestDay,
                subtitle: stats.busiestDay == "—" ? "no data" : "\(shortHours(stats.busiestDayHours)) worked",
                tint: Color(red: 0.97, green: 0.94, blue: 0.85)
            )
        }
    }

    private var controlsSection: some View {
        VStack(spacing: 12) {
            TextField("Search sessions or expenses...", text: $searchText)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.white)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            HStack(spacing: 12) {
                tabButton(.sessions)
                tabButton(.expenses)
            }
        }
    }

    private var formsSection: some View {
        VStack(spacing: 16) {
            workSessionForm
            expenseForm
        }
    }

    private var workSessionForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Enter Work Time")
                .font(.title3.weight(.bold))
                .foregroundStyle(.black)

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
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var expenseForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Enter Expense")
                .font(.title3.weight(.bold))
                .foregroundStyle(.black)

            twoColumnGrid {
                labeledDatePicker("Date", selection: $exDate, displayed: [.date])
                labeledTextField("Amount ($)", text: $exAmount, placeholder: "e.g. 12.50", keyboard: .decimalPad)
                labeledTextField("Expense Name", text: $exName, placeholder: "e.g. Grocery", keyboard: .default)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Type")
                        .font(.headline)
                        .foregroundStyle(Color.black.opacity(0.82))

                    Picker("Type", selection: $exType) {
                        ForEach(ExpenseType.allCases, id: \.self) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .padding(.horizontal, 12)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.black.opacity(0.12), lineWidth: 1)
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
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var recordsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(tab == .sessions ? "Work Sessions" : "Expenses")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

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

    // MARK: - Small UI helpers

    private func periodButton(_ title: String, mode: PeriodMode) -> some View {
        Button {
            periodMode = mode
        } label: {
            Text(title)
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(periodMode == mode ? Color.purple : Color.white)
                .foregroundStyle(periodMode == mode ? .white : .black)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func tabButton(_ value: WorkTab) -> some View {
        Button {
            tab = value
        } label: {
            Text(value.title)
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(tab == value ? Color.purple : Color.white.opacity(0.15))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func statCard(title: String, value: String, subtitle: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.black.opacity(0.78))

            Text(value)
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(.black)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color.black.opacity(0.62))
        }
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .padding(18)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(accent.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func pastelCard(title: String, value: String, subtitle: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.heavy))
                .foregroundStyle(Color.black.opacity(0.78))

            Text(value)
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(.black)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color.black.opacity(0.62))
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .padding(18)
        .background(tint)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func liveValueCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.black.opacity(0.72))

            Text(value)
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(Color(red: 0.36, green: 0.18, blue: 0.78))
        }
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
        .padding(14)
        .background(Color(red: 0.95, green: 0.94, blue: 0.98))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.purple.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func labeledTextField(_ label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.headline)
                .foregroundStyle(Color.black.opacity(0.82))

            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .foregroundStyle(.black)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func labeledDatePicker(_ label: String, selection: Binding<Date>, displayed: DatePickerComponents) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.headline)
                .foregroundStyle(Color.black.opacity(0.82))

            DatePicker("", selection: selection, displayedComponents: displayed)
                .labelsHidden()
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                .padding(.horizontal, 14)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func twoColumnGrid<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            content()
        }
    }

    private func sessionRow(_ session: WorkSessionRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(formatDate(session.date))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.black)

                Spacer()

                Text(money(session.earnings))
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Color(red: 0.36, green: 0.18, blue: 0.78))
            }

            Text("\(weekdayName(session.date)) • \(formatTime(session.startTime)) → \(formatTime(session.endTime))")
                .font(.subheadline)
                .foregroundStyle(Color.black.opacity(0.72))

            HStack {
                Text("Hours: \(shortHours(session.hours))")
                Spacer()
                Text("Pay: \(money(session.hourlyPay))")
            }
            .font(.subheadline)
            .foregroundStyle(Color.black.opacity(0.78))

            if !session.notes.isEmpty {
                Text(session.notes)
                    .font(.subheadline)
                    .foregroundStyle(Color.black.opacity(0.64))
            }

            Button(role: .destructive) {
                deleteSession(session)
            } label: {
                Text("Delete")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.red)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func expenseRow(_ expense: ExpenseRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(expense.name)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.black)

                Spacer()

                Text(money(expense.amount))
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.black)
            }

            Text("\(formatDate(expense.date)) • \(expense.type.rawValue)")
                .font(.subheadline)
                .foregroundStyle(Color.black.opacity(0.72))

            Text(expense.whereUsed.isEmpty ? "—" : expense.whereUsed)
                .font(.subheadline)
                .foregroundStyle(Color.black.opacity(0.64))

            Button(role: .destructive) {
                deleteExpense(expense)
            } label: {
                Text("Delete")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.red)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func emptyCard(_ message: String) -> some View {
        Text(message)
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 110)
            .background(Color.white.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var cardBackground: some View {
        Color.white.opacity(0.08)
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.16, blue: 0.32),
                Color(red: 0.04, green: 0.05, blue: 0.14),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Derived values

    private var availableYears: [Int] {
        let sessionYears = sessions.map { Calendar.current.component(.year, from: $0.date) }
        let expenseYears = expenses.map { Calendar.current.component(.year, from: $0.date) }
        let set = Set(sessionYears + expenseYears + [Calendar.current.component(.year, from: Date())])
        return set.sorted(by: >)
    }

    private var filteredSessions: [WorkSessionRecord] {
        sessions.filter { isInSelectedPeriod($0.date) }
    }

    private var filteredExpenses: [ExpenseRecord] {
        expenses.filter { isInSelectedPeriod($0.date) }
    }

    private var visibleSessions: [WorkSessionRecord] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return filteredSessions }

        return filteredSessions.filter { s in
            formatDate(s.date).lowercased().contains(q) ||
            weekdayName(s.date).lowercased().contains(q) ||
            formatTime(s.startTime).lowercased().contains(q) ||
            formatTime(s.endTime).lowercased().contains(q) ||
            s.notes.lowercased().contains(q) ||
            money(s.hourlyPay).lowercased().contains(q)
        }
    }

    private var visibleExpenses: [ExpenseRecord] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return filteredExpenses }

        return filteredExpenses.filter { e in
            formatDate(e.date).lowercased().contains(q) ||
            e.name.lowercased().contains(q) ||
            e.type.rawValue.lowercased().contains(q) ||
            e.whereUsed.lowercased().contains(q) ||
            money(e.amount).lowercased().contains(q)
        }
    }

    private var wsHours: Double {
        diffHours(start: wsStart, end: wsEnd)
    }

    private var wsEarnings: Double {
        wsHours * (Double(wsRate) ?? 0)
    }

    private var currentStats: WorkStats {
        makeStats(from: filteredSessions)
    }

    private var previousLabel: String {
        let previous = previousPeriod()
        return periodLabel(mode: previous.mode, month: previous.month, year: previous.year)
    }

    private var currentLabel: String {
        periodLabel(mode: periodMode, month: selectedMonth, year: selectedYear)
    }

    // MARK: - Actions

    private func addWorkSession() {
        guard wsHours > 0 else { return }

        let rate = Double(wsRate) ?? 0
        let start = mergedDate(date: wsDate, time: wsStart)
        let rawEnd = mergedDate(date: wsDate, time: wsEnd)
        let end = adjustedEndDate(start: start, end: rawEnd)

        let entry = WorkSessionRecord(
            date: wsDate,
            startTime: start,
            endTime: end,
            hourlyPay: rate,
            notes: wsNotes
        )

        sessions.insert(entry, at: 0)
        saveSessions()

        wsRate = ""
        wsNotes = ""
        wsStart = Date()
        wsEnd = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    }

    private func deleteSession(_ session: WorkSessionRecord) {
        sessions.removeAll { $0.id == session.id }
        saveSessions()
    }

    private func addExpense() {
        guard let amount = Double(exAmount), amount > 0 else { return }

        let entry = ExpenseRecord(
            date: exDate,
            name: exName.isEmpty ? "Expense" : exName,
            type: exType,
            whereUsed: exWhere,
            amount: amount
        )

        expenses.insert(entry, at: 0)
        saveExpenses()

        exName = ""
        exWhere = ""
        exAmount = ""
        exType = .food
    }

    private func deleteExpense(_ expense: ExpenseRecord) {
        expenses.removeAll { $0.id == expense.id }
        saveExpenses()
    }

    // MARK: - Persistence

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([WorkSessionRecord].self, from: data) {
            sessions = decoded
        }

        if let data = UserDefaults.standard.data(forKey: expensesKey),
           let decoded = try? JSONDecoder().decode([ExpenseRecord].self, from: data) {
            expenses = decoded
        }
    }

    private func saveSessions() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: sessionsKey)
        }
    }

    private func saveExpenses() {
        if let data = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(data, forKey: expensesKey)
        }
    }

    // MARK: - Logic

    private func diffHours(start: Date, end: Date) -> Double {
        let startMinutes = Calendar.current.component(.hour, from: start) * 60
            + Calendar.current.component(.minute, from: start)
        let endMinutes = Calendar.current.component(.hour, from: end) * 60
            + Calendar.current.component(.minute, from: end)

        let minutes = endMinutes >= startMinutes
            ? endMinutes - startMinutes
            : endMinutes + (24 * 60) - startMinutes

        return Double(minutes) / 60.0
    }

    private func isInSelectedPeriod(_ date: Date) -> Bool {
        let y = Calendar.current.component(.year, from: date)
        let m = Calendar.current.component(.month, from: date) - 1

        if periodMode == .yearly {
            return y == selectedYear
        }

        return y == selectedYear && m == selectedMonth
    }

    private func previousPeriod() -> (mode: PeriodMode, month: Int, year: Int) {
        if periodMode == .yearly {
            return (.yearly, selectedMonth, selectedYear - 1)
        }

        if selectedMonth == 0 {
            return (.monthly, 11, selectedYear - 1)
        }

        return (.monthly, selectedMonth - 1, selectedYear)
    }

    private func periodLabel(mode: PeriodMode, month: Int, year: Int) -> String {
        mode == .yearly ? "\(year)" : "\(monthNames[month]) \(year)"
    }

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

    private func adjustedEndDate(start: Date, end: Date) -> Date {
        if end >= start { return end }
        return Calendar.current.date(byAdding: .day, value: 1, to: end) ?? end
    }

    private func formatDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    private func weekdayName(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide))
    }

    private func formatTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    private func money(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }

    private func hoursText(_ value: Double) -> String {
        "\(String(format: "%.1f", value))h"
    }

    private func shortHours(_ value: Double) -> String {
        "\(String(format: "%.2f", value))h"
    }
}

// MARK: - Local models

enum WorkTab {
    case sessions
    case expenses

    var title: String {
        switch self {
        case .sessions: return "Sessions"
        case .expenses: return "Expenses"
        }
    }
}

enum PeriodMode {
    case monthly
    case yearly
}

enum ExpenseType: String, CaseIterable, Codable {
    case food = "Food"
    case transport = "Transport"
    case bills = "Bills"
    case shopping = "Shopping"
    case health = "Health"
    case entertainment = "Entertainment"
    case other = "Other"
}

struct WorkSessionRecord: Identifiable, Codable {
    var id = UUID()
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

struct ExpenseRecord: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var name: String
    var type: ExpenseType
    var whereUsed: String
    var amount: Double
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
