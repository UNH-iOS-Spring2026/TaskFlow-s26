//
//  GoalsView.swift
//  Task_Flow
//
//  Created by Aravind Ganipisetty on 2/11/26.
//

import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.goals.sorted(by: { $0.createdAt > $1.createdAt })) { g in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(g.title).font(.headline)
                        ProgressView(value: g.progress)
                        Text("Target: \(g.targetDate.formatted(date: .abbreviated, time: .omitted))")
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { idx in
                    let sorted = store.goals.sorted(by: { $0.createdAt > $1.createdAt })
                    let ids = idx.map { sorted[$0].id }
                    store.goals.removeAll { ids.contains($0.id) }
                    store.saveAll()
                }
            }
            .navigationTitle("Goals")
            .toolbar { Button { showAdd = true } label: { Image(systemName: "plus") } }
            .sheet(isPresented: $showAdd) { AddGoalSheet() }
        }
    }
}

struct AddGoalSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var target = Date().addingTimeInterval(86400 * 7)
    @State private var progress = 0.0

    var body: some View {
        NavigationStack {
            Form {
                TextField("Goal title", text: $title)
                DatePicker("Target date", selection: $target, displayedComponents: .date)
                Slider(value: $progress, in: 0...1, step: 0.05) {
                    Text("Progress")
                }
                Text("Progress: \(Int(progress * 100))%")
            }
            .navigationTitle("New Goal")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !t.isEmpty else { return }
                        store.goals.insert(GoalItem(title: t, targetDate: target, progress: progress), at: 0)
                        store.saveAll()
                        dismiss()
                    }
                }
            }
        }
    }
}

