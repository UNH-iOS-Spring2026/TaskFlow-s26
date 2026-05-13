//
//  HabitsView.swift
//  Task_Flow
//
//  Created by Aravind Ganipisetty
//

import SwiftUI

struct HabitsView: View {
    @EnvironmentObject var store: AppStore
    @AppStorage("tf_dark_mode") private var darkMode = false

    // MARK: - View State

    // Controls the Add Habit sheet.
    @State private var showAddHabitSheet = false

    // Stores the habit selected for deletion.
    @State private var habitToDelete: HabitItem?

    // Controls the delete confirmation alert.
    @State private var showDeleteAlert = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if sortedHabits.isEmpty {
                        emptyState
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 14) {
                                ForEach(sortedHabits) { habit in
                                    habitCard(habit)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddHabitSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                            .frame(width: 38, height: 38)
                            .background(cardBackground)
                            .overlay(
                                Circle()
                                    .stroke(cardBorder, lineWidth: 1)
                            )
                            .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $showAddHabitSheet) {
                AddHabitSheet()
                    .environmentObject(store)
                    .preferredColorScheme(darkMode ? .dark : .light)
            }
            .alert("Delete Habit", isPresented: $showDeleteAlert, presenting: habitToDelete) { habit in
                Button("Cancel", role: .cancel) { }

                Button("Delete", role: .destructive) {
                    store.deleteHabit(habit)
                }
            } message: { habit in
                Text("Are you sure you want to delete \"\(habit.title)\"?")
            }
            .onAppear {
                normalizeCompletedTodayFlags()
            }
        }
    }

    // MARK: - Habit Data

    // Sorts habits so the newest habit appears first.
    private var sortedHabits: [HabitItem] {
        store.habits.sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Empty State

    // Shows a friendly message when the user has not created any habits yet.
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "flame")
                .font(.system(size: 46))
                .foregroundColor(.orange)

            Text("No habits yet")
                .font(.title3.bold())
                .foregroundColor(primaryTextColor)

            Text("Tap the plus button to create your first habit.")
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer()
        }
        .padding()
    }

    // MARK: - Habit Card

    // Displays one habit with streak progress, completion action, and delete option.
    private func habitCard(_ habit: HabitItem) -> some View {
        HStack(spacing: 14) {
            Button {
                toggleHabitCompletion(habit)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(accentTileColor)
                        .frame(width: 54, height: 54)

                    if habit.isCompletedToday {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(habit.title)
                    .font(.headline)
                    .foregroundColor(primaryTextColor)

                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.caption)

                    Text("Streak: \(habit.streak)")
                        .font(.subheadline)
                        .foregroundColor(secondaryTextColor)
                }

                if let lastCompleted = habit.lastCompleted {
                    Text("Last done: \(formattedDate(lastCompleted))")
                        .font(.caption)
                        .foregroundColor(secondaryTextColor.opacity(0.85))
                } else {
                    Text("Tap the box to start")
                        .font(.caption)
                        .foregroundColor(secondaryTextColor.opacity(0.85))
                }
            }

            Spacer()

            if habit.isCompletedToday {
                Button {
                    toggleHabitCompletion(habit)
                } label: {
                    Text("Done")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Button {
                habitToDelete = habit
                showDeleteAlert = true
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .frame(width: 34, height: 34)
                    .background(Color.red.opacity(darkMode ? 0.12 : 0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(cardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Habit Completion Logic

    // Toggles a habit between completed today and not completed today.
    private func toggleHabitCompletion(_ habit: HabitItem) {
        var updatedHabit = habit

        if updatedHabit.isCompletedToday {
            undoHabitForToday(&updatedHabit)
        } else {
            markHabitDone(&updatedHabit)
        }

        store.updateHabit(updatedHabit)
    }

    // Marks a habit as completed and updates the streak based on the last completed date.
    private func markHabitDone(_ habit: inout HabitItem) {
        let now = Date()
        let calendar = Calendar.current

        if let lastCompleted = habit.lastCompleted {
            if calendar.isDateInToday(lastCompleted) {
                habit.isCompletedToday = true
                return
            }

            let startOfLast = calendar.startOfDay(for: lastCompleted)
            let startOfNow = calendar.startOfDay(for: now)
            let dayDifference = calendar.dateComponents([.day], from: startOfLast, to: startOfNow).day ?? 0

            if dayDifference == 1 {
                habit.streak += 1
            } else {
                habit.streak = 1
            }
        } else {
            habit.streak = 1
        }

        habit.lastCompleted = now
        habit.isCompletedToday = true
    }

    // Reverts today's completion and safely adjusts the streak count.
    private func undoHabitForToday(_ habit: inout HabitItem) {
        guard habit.isCompletedToday else {
            return
        }

        if habit.streak > 0 {
            habit.streak -= 1
        }

        if habit.streak == 0 {
            habit.lastCompleted = nil
        } else {
            habit.lastCompleted = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        }

        habit.isCompletedToday = false
    }

    // Updates the completed-today flag when the screen opens on a new day.
    private func normalizeCompletedTodayFlags() {
        let calendar = Calendar.current

        for habit in store.habits {
            let isToday: Bool

            if let lastCompleted = habit.lastCompleted {
                isToday = calendar.isDateInToday(lastCompleted)
            } else {
                isToday = false
            }

            if habit.isCompletedToday != isToday {
                var updatedHabit = habit
                updatedHabit.isCompletedToday = isToday
                store.updateHabit(updatedHabit)
            }
        }
    }

    // MARK: - Formatting

    // Formats the last completed date shown on each habit card.
    private func formattedDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    // MARK: - Theme Colors

    // Main text color based on the selected theme.
    private var primaryTextColor: Color {
        darkMode ? .white : .black
    }

    // Secondary text color used for streak text and helper text.
    private var secondaryTextColor: Color {
        darkMode ? .white.opacity(0.72) : .black.opacity(0.65)
    }

    // Card background color for each habit row.
    private var cardBackground: Color {
        darkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.04)
    }

    // Border color around habit cards.
    private var cardBorder: Color {
        darkMode ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    // Orange tile color used for the habit completion button.
    private var accentTileColor: Color {
        darkMode ? Color.orange.opacity(0.9) : Color.orange
    }

    // Main screen background for light and dark mode.
    private var backgroundView: some View {
        Group {
            if darkMode {
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 0.05, green: 0.05, blue: 0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [
                        Color.white,
                        Color(red: 0.95, green: 0.97, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

// MARK: - Add Habit Sheet

// Sheet used to create a new habit.
struct AddHabitSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("tf_dark_mode") private var darkMode = false

    // Stores the habit title entered by the user.
    @State private var title = ""

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    Text("New Habit")
                        .font(.largeTitle.bold())
                        .foregroundColor(primaryTextColor)

                    TextField("Habit name", text: $title)
                        .padding(14)
                        .background(fieldBackgroundColor)
                        .foregroundColor(primaryTextColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Spacer()
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(primaryTextColor)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveHabit()
                    }
                    .foregroundColor(canSave ? .blue : .gray)
                    .disabled(!canSave)
                }
            }
        }
    }

    // MARK: - Save Logic

    // Checks whether the habit title is valid before enabling Save.
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // Saves the new habit through AppStore and closes the sheet.
    private func saveHabit() {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedTitle.isEmpty else {
            return
        }

        store.addHabit(title: cleanedTitle)
        dismiss()
    }

    // MARK: - Theme Colors

    // Main text color based on the selected theme.
    private var primaryTextColor: Color {
        darkMode ? .white : .black
    }

    // Text field background color.
    private var fieldBackgroundColor: Color {
        darkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.05)
    }

    // Background used for the Add Habit sheet.
    private var backgroundView: some View {
        Group {
            if darkMode {
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 0.05, green: 0.05, blue: 0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [
                        Color.white,
                        Color(red: 0.95, green: 0.97, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

// MARK: - Preview

// Preview creates local store objects so the Habits screen can render in Xcode canvas.
#Preview {
    let auth = AuthStore()
    let store = AppStore(auth: auth)

    return HabitsView()
        .environmentObject(store)
}
