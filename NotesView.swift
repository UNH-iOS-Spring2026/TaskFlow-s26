//
//  NotesView.swift
//  Task_Flow
//
//  Created by Aravind Ganipisetty on 2/11/26.
//

import SwiftUI

struct NotesView: View {
    @EnvironmentObject var store: AppStore

    @State private var showAdd = false
    @State private var searchText = ""
    @State private var selectedNoteID: UUID? = nil   // ✅ open full note (no Identifiable hacks)

    var body: some View {
        NavigationStack {
            ZStack {
                background

                ScrollView {
                    VStack(spacing: 14) {
                        header

                        Button {
                            showAdd = true
                        } label: {
                            Text("+ Create Note")
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.purple.opacity(0.9))

                        HStack {
                            Text("Your Notes (\(filteredNotes.count))")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white.opacity(0.9))
                            Spacer()
                        }
                        .padding(.top, 6)

                        if filteredNotes.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredNotes) { note in
                                    NoteCard(
                                        note: note,
                                        onOpen: { selectedNoteID = note.id },
                                        onDelete: { deleteNote(note) }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 110) }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showAdd) {
                AddNoteSheetModern()
                    .environmentObject(store)
            }
            // ✅ Full note screen without `.fullScreenCover(item:)` (prevents Identifiable conflict)
            .fullScreenCover(
                isPresented: Binding(
                    get: { selectedNoteID != nil },
                    set: { if !$0 { selectedNoteID = nil } }
                )
            ) {
                if let id = selectedNoteID {
                    NoteDetailView(noteID: id)
                        .environmentObject(store)
                }
            }
        }
    }

    // MARK: - UI

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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Create and manage your notes")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Button { showAdd = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Color.white.opacity(0.10))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white.opacity(0.65))
                TextField("Search notes...", text: $searchText)
                    .foregroundStyle(.white)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("No notes yet.")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
            Text("Create your first note to capture ideas, tasks, and reminders.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Data

    private var sortedNotes: [NoteItem] {
        store.notes.sorted(by: { $0.createdAt > $1.createdAt })
    }

    private var filteredNotes: [NoteItem] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return sortedNotes }
        return sortedNotes.filter {
            $0.title.lowercased().contains(q) || $0.body.lowercased().contains(q)
        }
    }

    private func deleteNote(_ note: NoteItem) {
        withAnimation {
            store.notes.removeAll { $0.id == note.id }
            store.saveAll()
        }
    }
}

// MARK: - Note Card

private struct NoteCard: View {
    let note: NoteItem
    let onOpen: () -> Void
    let onDelete: () -> Void

    var body: some View {
        let c = NoteColors.color(for: note.colorSeed)
        let title = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = note.body.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstLetter = String((title.isEmpty ? "U" : title.prefix(1))).uppercased()

        Button {
            onOpen()
        } label: {
            HStack(spacing: 12) {
                // ✅ SUPER visible color stripe (fixes "colors not working" complaint)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(c)
                    .frame(width: 10)

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(c.opacity(0.28))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(firstLetter)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(title.isEmpty ? "Untitled" : title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)

                    Text(body.isEmpty ? "No content" : body)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.70))
                        .lineLimit(2)

                    Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }

                Spacer()

                // ✅ visible delete button
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.red)
                        .padding(10)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete note")
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(c.opacity(0.55), lineWidth: 1.4) // ✅ colored border
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Add Note (Full Screen)

struct AddNoteSheetModern: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var bodyText = ""

    // ✅ Use palette indices (0...5). This guarantees the stored value maps to visible colors.
    @State private var selectedSeed: Int = 2
    private let seeds: [Int] = [0, 1, 2, 3, 4, 5]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    HStack {
                        Text("Create New Note")
                            .font(.title2.weight(.bold))
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.secondary)
                                .padding(10)
                                .background(Color.black.opacity(0.06))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title").font(.headline)
                        TextField("Note title...", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Content").font(.headline)
                        TextEditor(text: $bodyText)
                            .frame(height: 260)
                            .padding(10)
                            .background(Color.black.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Color").font(.headline)

                        HStack(spacing: 12) {
                            ForEach(seeds, id: \.self) { s in
                                let isSelected = (s == selectedSeed)

                                ZStack {
                                    Circle()
                                        .fill(NoteColors.color(for: s))
                                        .frame(width: 32, height: 32)

                                    if isSelected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(.black.opacity(0.65))
                                    }
                                }
                                .overlay(
                                    Circle()
                                        .stroke(isSelected ? Color.purple : Color.black.opacity(0.15),
                                                lineWidth: isSelected ? 3 : 1)
                                )
                                .contentShape(Circle())
                                .onTapGesture {
                                    selectedSeed = s
                                }
                            }
                        }

                        // ✅ Live preview (helps you verify the color is actually changing)
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(NoteColors.color(for: selectedSeed).opacity(0.28))
                            .frame(height: 46)
                            .overlay(
                                Text("Selected color preview")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.black.opacity(0.60))
                            )
                            .padding(.top, 6)
                    }

                    HStack(spacing: 12) {
                        Button {
                            let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
                            let b = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !t.isEmpty || !b.isEmpty else { return }

                            store.notes.insert(
                                NoteItem(
                                    title: t.isEmpty ? "Untitled" : t,
                                    body: b,
                                    createdAt: Date(),
                                    colorSeed: selectedSeed // ✅ palette index stored
                                ),
                                at: 0
                            )
                            store.saveAll()
                            dismiss()
                        } label: {
                            Text("Create Note")
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.purple.opacity(0.9))

                        Button { dismiss() } label: {
                            Text("Cancel")
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 6)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Note Detail (Open full note + edit + delete)

struct NoteDetailView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let noteID: UUID

    @State private var isEditing = false
    @State private var title = ""
    @State private var bodyText = ""
    @State private var seed: Int = 2

    private let seeds: [Int] = [0, 1, 2, 3, 4, 5]

    private var noteIndex: Int? {
        store.notes.firstIndex(where: { $0.id == noteID })
    }

    var body: some View {
        ZStack {
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

            if let idx = noteIndex {
                let note = store.notes[idx]
                let c = NoteColors.color(for: note.colorSeed)

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {

                        // Top bar
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(10)
                                    .background(Color.white.opacity(0.10))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button {
                                if isEditing {
                                    saveEdits()
                                }
                                isEditing.toggle()
                            } label: {
                                Text(isEditing ? "Save" : "Edit")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.10))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)

                            Button(role: .destructive) {
                                deleteThisNote()
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.red)
                                    .padding(10)
                                    .background(Color.white.opacity(0.10))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 6)

                        // Header
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(c)
                                .frame(width: 10, height: 52)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Note")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.70))
                                Text(note.createdAt.formatted(date: .complete, time: .shortened))
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.85))
                            }

                            Spacer()
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                        if isEditing {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Title")
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.9))
                                TextField("Title", text: $title)
                                    .textFieldStyle(.roundedBorder)
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Content")
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.9))
                                TextEditor(text: $bodyText)
                                    .frame(minHeight: 260)
                                    .padding(10)
                                    .background(Color.white.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .foregroundStyle(.white)
                            }

                            Text("Color")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.9))

                            HStack(spacing: 12) {
                                ForEach(seeds, id: \.self) { s in
                                    let isSelected = (s == seed)
                                    ZStack {
                                        Circle()
                                            .fill(NoteColors.color(for: s))
                                            .frame(width: 32, height: 32)
                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(.black.opacity(0.65))
                                        }
                                    }
                                    .overlay(
                                        Circle().stroke(isSelected ? Color.purple : Color.white.opacity(0.12),
                                                       lineWidth: isSelected ? 3 : 1)
                                    )
                                    .contentShape(Circle())
                                    .onTapGesture { seed = s }
                                }
                            }
                            .padding(.bottom, 6)

                        } else {
                            // View mode (full text)
                            Text(note.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : note.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.top, 6)

                            Text(note.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No content" : note.body)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.92))
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(c.opacity(0.55), lineWidth: 1.2)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    .padding()
                    .onAppear {
                        // preload editing fields from current note
                        title = note.title
                        bodyText = note.body
                        seed = note.colorSeed
                    }
                }
            } else {
                VStack(spacing: 10) {
                    Text("Note not found")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Button("Close") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                }
            }
        }
    }

    private func saveEdits() {
        guard let idx = noteIndex else { return }
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)

        store.notes[idx] = NoteItem(
            id: store.notes[idx].id,
            title: t.isEmpty ? "Untitled" : t,
            body: b,
            createdAt: store.notes[idx].createdAt,
            colorSeed: seed
        )
        store.saveAll()
    }

    private func deleteThisNote() {
        guard let idx = noteIndex else { return }
        store.notes.remove(at: idx)
        store.saveAll()
        dismiss()
    }
}

// MARK: - Colors (palette)

enum NoteColors {
    static func color(for seed: Int) -> Color {
        let palette: [Color] = [
            Color(red: 0.96, green: 0.90, blue: 0.48), // yellow
            Color(red: 0.81, green: 0.90, blue: 1.00), // blue
            Color(red: 0.92, green: 0.84, blue: 1.00), // purple
            Color(red: 0.82, green: 0.97, blue: 0.87), // green
            Color(red: 0.92, green: 0.92, blue: 0.92), // gray
            Color(red: 1.00, green: 0.90, blue: 0.76)  // orange
        ]
        return palette[abs(seed) % palette.count]
    }
}
