//
//  HabitsView.swift
//  Task_Flow
//
//  Created by Aravind Ganipisetty on 2/11/26.
//

import SwiftUI

struct HabitsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedHabits) { h in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(h.title).font(.headline)
                            Text("Streak: \(h.streak)")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(action: { complete(h) }) {
                            Text("Done")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .onDelete(perform: deleteHabits)
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddHabitSheet() }
        }
    }

    private var sortedHabits: [HabitItem] {
        store.habits.sorted(by: { $0.createdAt > $1.createdAt })
    }

    private func complete(_ habit: HabitItem) {
        guard let i = store.habits.firstIndex(of: habit) else { return }
        store.habits[i].streak += 1
        store.habits[i].lastCompleted = Date()
        store.saveAll()
    }

    private func deleteHabits(at offsets: IndexSet) {
        let ids = offsets.map { sortedHabits[$0].id }
        store.habits.removeAll { ids.contains($0.id) }
        store.saveAll()
    }
}

struct AddHabitSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State private var title = ""

    var body: some View {
        NavigationStack {
            Form { TextField("Habit name", text: $title) }
                .navigationTitle("New Habit")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !t.isEmpty else { return }
                            store.habits.insert(HabitItem(title: t, streak: 0, lastCompleted: nil, createdAt: Date()), at: 0)
                            store.saveAll()
                            dismiss()
                        }
                    }
                }
        }
    }
}


