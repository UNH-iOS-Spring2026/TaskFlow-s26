//
//  WorkHoursView.swift
//  Task_Flow
//
//  Created by Aravind Ganipisetty on 2/11/26.
//

import SwiftUI

struct WorkHoursView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.workHours.sorted(by: { $0.date > $1.date })) { e in
                    VStack(alignment: .leading, spacing: 6) {
                        let day = e.date.formatted(.dateTime.weekday(.wide))
                        let dateStr = e.date.formatted(date: .abbreviated, time: .omitted)
                        Text("\(day) • \(dateStr)").font(.headline)

                        Text("Start: \(e.startTime.formatted(date: .omitted, time: .shortened))  |  End: \(e.endTime.formatted(date: .omitted, time: .shortened))")
                            .foregroundStyle(.secondary)

                        Text("Break: \(e.breakMinutes) min")
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { idx in
                    let sorted = store.workHours.sorted(by: { $0.date > $1.date })
                    let ids = idx.map { sorted[$0].id }
                    store.workHours.removeAll { ids.contains($0.id) }
                    store.saveAll()
                }
            }
            .navigationTitle("Work Hours")
            .toolbar {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
            .sheet(isPresented: $showAdd) {
                AddWorkHourSheet()
            }
        }
    }
}

struct AddWorkHourSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    @State private var date = Date()
    @State private var start = Date()
    @State private var end = Date().addingTimeInterval(3600)
    @State private var breakMin = 30

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                DatePicker("Start", selection: $start, displayedComponents: .hourAndMinute)
                DatePicker("End", selection: $end, displayedComponents: .hourAndMinute)
                Stepper("Break (min): \(breakMin)", value: $breakMin, in: 0...180, step: 5)
            }
            .navigationTitle("Add Work Entry")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        store.workHours.insert(
                            WorkHourEntry(date: date, startTime: start, endTime: end, breakMinutes: breakMin),
                            at: 0
                        )
                        store.saveAll()
                        dismiss()
                    }
                }
            }
        }
    }
}

