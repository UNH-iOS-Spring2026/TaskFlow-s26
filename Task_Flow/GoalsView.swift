//
//  GoalsView.swift
//  Task_Flow
import SwiftUI

struct GoalRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var goalName: String
    var goalDescription: String
    var targetDate: Date

    init(
        id: UUID = UUID(),
        goalName: String,
        goalDescription: String,
        targetDate: Date
    ) {
        self.id = id
        self.goalName = goalName
        self.goalDescription = goalDescription
        self.targetDate = targetDate
    }
}

struct GoalsView: View {
    @State private var goalName: String = ""
    @State private var goalDescription: String = ""
    @State private var targetDate: Date = Date()

    @State private var goals: [GoalRecord] = []
    @State private var showValidationAlert = false
    @State private var selectedGoal: GoalRecord?

    private let storageKey = "saved_goals_records"

    var body: some View {
        NavigationView {
            VStack(spacing: 18) {
                createGoalSection

                if goals.isEmpty {
                    Spacer()
                    Text("No goals saved yet")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(goals) { goal in
                                goalCard(goal)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    }
                }
            }
            .navigationTitle("Goals")
            .onAppear(perform: loadGoals)
            .alert("Please enter a goal name", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            }
            .sheet(item: $selectedGoal) { goal in
                GoalDetailSheet(
                    goal: goal,
                    onSave: { updatedGoal in
                        updateGoal(updatedGoal)
                    },
                    onDelete: { goalToDelete in
                        deleteGoal(goalToDelete)
                    }
                )
            }
        }
    }

    private var createGoalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create Goal")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 8) {
                Text("Goal Name")
                    .font(.headline)

                TextField("Enter goal name", text: $goalName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)

                TextField("Enter description", text: $goalDescription, axis: .vertical)
                    .lineLimit(3...5)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Target Date & Time")
                    .font(.headline)

                DatePicker(
                    "Select Date & Time",
                    selection: $targetDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
            }

            HStack(spacing: 12) {
                Button(action: saveGoal) {
                    Text("Save Goal")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: clearForm) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(14)
        .padding(.horizontal)
    }

    private func goalCard(_ goal: GoalRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(goal.goalName)
                        .font(.headline)
                        .foregroundColor(.white)

                    if !goal.goalDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(goal.goalDescription)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                }

                Spacer()

                Button {
                    deleteGoal(goal)
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.white.opacity(0.08))
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
        .background(Color(.secondarySystemBackground).opacity(0.35))
        .cornerRadius(14)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedGoal = goal
        }
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

        goals.append(newGoal)
        saveGoalsToStorage()
        clearForm()
    }

    private func clearForm() {
        goalName = ""
        goalDescription = ""
        targetDate = Date()
    }

    private func updateGoal(_ updatedGoal: GoalRecord) {
        if let index = goals.firstIndex(where: { $0.id == updatedGoal.id }) {
            goals[index] = updatedGoal
            saveGoalsToStorage()
        }
    }

    private func deleteGoal(_ goal: GoalRecord) {
        goals.removeAll { $0.id == goal.id }
        saveGoalsToStorage()

        if selectedGoal?.id == goal.id {
            selectedGoal = nil
        }
    }

    private func saveGoalsToStorage() {
        do {
            let data = try JSONEncoder().encode(goals)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save goals: \(error.localizedDescription)")
        }
    }

    private func loadGoals() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }

        do {
            goals = try JSONDecoder().decode([GoalRecord].self, from: data)
        } catch {
            print("Failed to load goals: \(error.localizedDescription)")
        }
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
    let onSave: (GoalRecord) -> Void
    let onDelete: (GoalRecord) -> Void

    init(
        goal: GoalRecord,
        onSave: @escaping (GoalRecord) -> Void,
        onDelete: @escaping (GoalRecord) -> Void
    ) {
        _editableGoal = State(initialValue: goal)
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Goal Information")) {
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    GoalsView()
        .preferredColorScheme(.dark)
}
