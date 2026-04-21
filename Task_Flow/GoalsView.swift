import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var store: AppStore
    @AppStorage("tf_dark_mode") private var darkMode = false

    @State private var goalName: String = ""
    @State private var goalDescription: String = ""
    @State private var targetDate: Date = Date()

    @State private var showValidationAlert = false
    @State private var selectedGoal: GoalRecord?

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                    .ignoresSafeArea()

                VStack(spacing: 18) {
                    createGoalSection

                    if store.goalRecords.isEmpty {
                        Spacer()
                        Text("No goals saved yet")
                            .foregroundColor(secondaryTextColor)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(store.goalRecords) { goal in
                                    goalCard(goal)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 12)
                        }
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("Goals")
            .navigationBarTitleDisplayMode(.large)
            .alert("Please enter a goal name", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            }
            .sheet(item: $selectedGoal) { goal in
                GoalDetailSheet(
                    goal: goal,
                    darkMode: darkMode,
                    onSave: { updatedGoal in
                        store.updateGoalRecord(updatedGoal)
                    },
                    onDelete: { goalToDelete in
                        store.deleteGoalRecord(goalToDelete)
                    }
                )
            }
        }
    }

    private var backgroundView: some View {
        Group {
            if darkMode {
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 0.03, green: 0.05, blue: 0.16),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color.white,
                        Color(red: 0.92, green: 0.95, blue: 0.99)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    private var createGoalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create Goal")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(primaryTextColor)

            VStack(alignment: .leading, spacing: 8) {
                Text("Goal Name")
                    .font(.headline)
                    .foregroundColor(primaryTextColor)

                TextField("Enter goal name", text: $goalName)
                    .padding(12)
                    .background(fieldBackgroundColor)
                    .foregroundColor(primaryTextColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                    .foregroundColor(primaryTextColor)

                TextField("Enter description", text: $goalDescription, axis: .vertical)
                    .lineLimit(3...5)
                    .padding(12)
                    .background(fieldBackgroundColor)
                    .foregroundColor(primaryTextColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Target Date & Time")
                    .font(.headline)
                    .foregroundColor(primaryTextColor)

                DatePicker(
                    "Select Date & Time",
                    selection: $targetDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .colorScheme(darkMode ? .dark : .light)
                .foregroundColor(primaryTextColor)
            }

            HStack(spacing: 12) {
                Button(action: saveGoal) {
                    Text("Save Goal")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                Button(action: clearForm) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(buttonSecondaryBackground)
                        .foregroundColor(primaryTextColor)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .padding()
        .background(cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(cardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal)
    }

    private func goalCard(_ goal: GoalRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(goal.goalName)
                        .font(.headline)
                        .foregroundColor(primaryTextColor)

                    if !goal.goalDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(goal.goalDescription)
                            .font(.subheadline)
                            .foregroundColor(secondaryTextColor)
                            .lineLimit(2)
                    }
                }

                Spacer()

                Button {
                    store.deleteGoalRecord(goal)
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(darkMode ? 0.12 : 0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Text("Target: \(formattedDate(goal.targetDate))")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(cardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            selectedGoal = goal
        }
    }

    private var primaryTextColor: Color {
        darkMode ? .white : .black
    }

    private var secondaryTextColor: Color {
        darkMode ? Color.white.opacity(0.7) : Color.black.opacity(0.6)
    }

    private var cardBackground: Color {
        darkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.9)
    }

    private var cardBorder: Color {
        darkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }

    private var fieldBackgroundColor: Color {
        darkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.04)
    }

    private var buttonSecondaryBackground: Color {
        darkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.06)
    }

    private func saveGoal() {
        let trimmedName = goalName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = goalDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            showValidationAlert = true
            return
        }

        let newGoal = GoalRecord(
            goalName: trimmedName,
            goalDescription: trimmedDescription,
            targetDate: targetDate
        )

        store.addGoalRecord(newGoal)
        clearForm()
    }

    private func clearForm() {
        goalName = ""
        goalDescription = ""
        targetDate = Date()
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct GoalDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var editableGoal: GoalRecord

    let darkMode: Bool
    let onSave: (GoalRecord) -> Void
    let onDelete: (GoalRecord) -> Void

    init(
        goal: GoalRecord,
        darkMode: Bool,
        onSave: @escaping (GoalRecord) -> Void,
        onDelete: @escaping (GoalRecord) -> Void
    ) {
        _editableGoal = State(initialValue: goal)
        self.darkMode = darkMode
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Information") {
                    TextField("Goal Name", text: $editableGoal.goalName)

                    TextField("Description", text: $editableGoal.goalDescription, axis: .vertical)
                        .lineLimit(3...6)

                    DatePicker(
                        "Target Date & Time",
                        selection: $editableGoal.targetDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Section {
                    Button("Save Changes") {
                        let cleanedName = editableGoal.goalName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !cleanedName.isEmpty else { return }

                        editableGoal.goalName = cleanedName
                        editableGoal.goalDescription = editableGoal.goalDescription.trimmingCharacters(in: .whitespacesAndNewlines)

                        onSave(editableGoal)
                        dismiss()
                    }
                    .foregroundColor(.purple)

                    Button("Delete Goal", role: .destructive) {
                        onDelete(editableGoal)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Goal Details")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(darkMode ? .dark : .light)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let auth = AuthStore()
    let store = AppStore(auth: auth)

    return GoalsView()
        .environmentObject(store)
}
