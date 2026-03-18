//
//  GoalsView.swift
//  Task_Flow
//
//  Created by Aravind Ganipisetty on 2/11/26.
//

import SwiftUI

struct GoalRecord: Identifiable, Codable {
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

    private let storageKey = "saved_goals_records"

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
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

                if goals.isEmpty {
                    Spacer()
                    Text("No goals saved yet")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    List {
                        ForEach(goals) { goal in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(goal.goalName)
                                        .font(.headline)

                                    if !goal.goalDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Text(goal.goalDescription)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }

                                    Text("Target: \(formattedDate(goal.targetDate))")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }

                                Spacer()

                                Button(role: .destructive) {
                                    deleteGoal(goal)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Goals")
            .onAppear(perform: loadGoals)
            .alert("Please enter a goal name", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            }
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

    private func deleteGoal(_ goal: GoalRecord) {
        goals.removeAll { $0.id == goal.id }
        saveGoalsToStorage()
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

#Preview {
    GoalsView()
}
