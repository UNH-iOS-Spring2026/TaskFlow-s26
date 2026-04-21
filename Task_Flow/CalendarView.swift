import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var store: AppStore

    @State private var monthOffset: Int = 0
    @State private var selectedDate: Date = Date()

    @State private var showAddReminder = false
    @State private var newTitle = ""
    @State private var newTime = Date()

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
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.07, blue: 0.12),
                Color(red: 0.10, green: 0.10, blue: 0.18),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Calendar")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)

            Text("Manage your reminders, birthdays, and events")
                .foregroundStyle(.white.opacity(0.7))
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var monthCardCompact: some View {
        let monthDate = monthBaseDate
        let monthTitle = monthDate.formatted(.dateTime.month(.wide).year())

        return VStack(spacing: 10) {
            HStack {
                Text(monthTitle)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)

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
                    .background(Color.white.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Button {
                        monthOffset += 1
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                    .background(Color.white.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }

            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.70))
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
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func compactDayCell(_ day: MonthDay) -> some View {
        let isSelected = cal.isDate(day.date, inSameDayAs: selectedDate)
        let isToday = cal.isDateInToday(day.date)
        let inMonth = day.isInMonth
        let hasReminder = store.reminders.contains {
            cal.isDate($0.dueAt, inSameDayAs: day.date)
        }

        return Button {
            selectedDate = day.date
        } label: {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.purple.opacity(0.55) : Color.white.opacity(inMonth ? 0.10 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isToday ? Color.purple.opacity(0.95) : Color.clear, lineWidth: 2)
                    )

                Text("\(cal.component(.day, from: day.date))")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(inMonth ? .white : .white.opacity(0.30))

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

    private var dayPanel: some View {
        let headerDate = selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
        let pending = remindersForSelectedDate.filter { !$0.isDone }
        let completed = remindersForSelectedDate.filter { $0.isDone }

        return VStack(alignment: .leading, spacing: 12) {
            Text(selectedDate.formatted(.dateTime.weekday(.wide)))
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            Text(headerDate)
                .foregroundStyle(.white.opacity(0.75))
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
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            Spacer()

            Text("\(count)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.10))
                .clipShape(Capsule())
        }
        .padding(.top, 2)
    }

    private func emptyLine(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(.white.opacity(0.65))
            .padding(.bottom, 2)
    }

    private func reminderRow(_ reminder: ReminderItem) -> some View {
        HStack(spacing: 10) {
            Button {
                store.toggleReminder(reminder)
            } label: {
                Image(systemName: reminder.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(reminder.isDone ? .green : .white.opacity(0.6))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(reminder.dueAt.formatted(date: .omitted, time: .shortened))
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer()

            Button(role: .destructive) {
                store.deleteReminder(reminder)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(8)
                    .background(Color.white.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

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
                }
            }
        }
    }

    private func saveReminder() {
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        let correctedDate = merge(date: selectedDate, time: newTime)

        store.addReminder(title: title, dueAt: correctedDate)

        newTitle = ""
        newTime = Date()
        showAddReminder = false
    }

    private var weekdays: [String] {
        cal.shortWeekdaySymbols
    }

    private var monthBaseDate: Date {
        let now = Date()
        return cal.date(byAdding: .month, value: monthOffset, to: startOfMonth(now)) ?? now
    }

    private func startOfMonth(_ date: Date) -> Date {
        let comps = cal.dateComponents([.year, .month], from: date)
        return cal.date(from: comps) ?? date
    }

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

    private var remindersForSelectedDate: [ReminderItem] {
        store.reminders
            .filter { cal.isDate($0.dueAt, inSameDayAs: selectedDate) }
            .sorted { $0.dueAt < $1.dueAt }
    }

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
}

struct MonthDay: Identifiable {
    let id = UUID()
    let date: Date
    let isInMonth: Bool
}

#Preview {
    let auth = AuthStore()
    let store = AppStore(auth: auth)

    return CalendarView()
        .environmentObject(store)
}
