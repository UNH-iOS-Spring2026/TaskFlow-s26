import SwiftUI

struct NotesView: View {
    @EnvironmentObject var store: AppStore

    @State private var searchText = ""
    @State private var showAddNoteSheet = false

    private var filteredNotes: [NoteItem] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return store.notes }

        return store.notes.filter {
            $0.title.localizedCaseInsensitiveContains(q) ||
            $0.body.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                background

                VStack(spacing: 14) {
                    topBar

                    if filteredNotes.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredNotes) { note in
                                    NavigationLink {
                                        NoteDetailView(noteID: note.id)
                                            .environmentObject(store)
                                    } label: {
                                        noteCard(note)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 4)
                            .padding(.bottom, 100)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showAddNoteSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 58, height: 58)
                                .background(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: .purple.opacity(0.35), radius: 12, x: 0, y: 8)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddNoteSheet) {
                AddNoteSheetModern()
                    .environmentObject(store)
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color.black,
                Color(red: 8/255, green: 12/255, blue: 42/255),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Notes")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.65))

                TextField("Search notes...", text: $searchText)
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: "note.text")
                .font(.system(size: 46))
                .foregroundColor(.white.opacity(0.65))

            Text("No notes yet")
                .font(.title3.bold())
                .foregroundColor(.white)

            Text("Tap the plus button to create your first note.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.72))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func noteCard(_ note: NoteItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Circle()
                    .fill(colorForSeed(note.colorSeed))
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)

                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                Text(note.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.55))
            }

            Text(note.body.isEmpty ? "No content" : note.body)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.78))
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func colorForSeed(_ seed: Int) -> Color {
        let palette: [Color] = [.pink, .purple, .blue, .green, .orange, .yellow, .mint, .teal]
        return palette[abs(seed) % palette.count]
    }
}

struct AddNoteSheetModern: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var bodyText = ""
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Enter title", text: $title)
                }

                Section("Body") {
                    TextEditor(text: $bodyText)
                        .frame(minHeight: 220)
                }

                if let errorText {
                    Section {
                        Text(errorText)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addNote(title: title, body: bodyText) { success in
                            if success {
                                dismiss()
                            } else {
                                errorText = "Could not create note."
                            }
                        }
                    }
                    .disabled(
                        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                        bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
            }
        }
    }
}

struct NoteDetailView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let noteID: UUID

    @State private var title = ""
    @State private var bodyText = ""
    @State private var seed = Int.random(in: 0...10_000)

    @State private var showDeleteAlert = false
    @State private var saveMessage: String?

    private var noteIndex: Int? {
        store.notes.firstIndex(where: { $0.id == noteID })
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 8/255, green: 12/255, blue: 42/255),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                header

                VStack(spacing: 14) {
                    TextField("Title", text: $title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    TextEditor(text: $bodyText)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(.white)
                        .padding(12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                if let saveMessage {
                    Text(saveMessage)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(16)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: loadNote)
        .alert("Delete Note?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteThisNote()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }

            Spacer()

            Button("Save") {
                saveEdits()
            }
            .font(.headline)
            .foregroundColor(.blue)

            Button {
                showDeleteAlert = true
            } label: {
                Image(systemName: "trash")
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
        }
    }

    private func loadNote() {
        guard let idx = noteIndex else { return }
        let note = store.notes[idx]
        title = note.title
        bodyText = note.body
        seed = note.colorSeed
    }

    private func saveEdits() {
        guard let idx = noteIndex else { return }

        let existing = store.notes[idx]
        let updated = NoteItem(
            id: existing.id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : title.trimmingCharacters(in: .whitespacesAndNewlines),
            body: bodyText.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: existing.createdAt,
            colorSeed: seed
        )

        store.updateNote(updated) { success in
            saveMessage = success ? "Saved" : "Could not save note."
        }
    }

    private func deleteThisNote() {
        guard let idx = noteIndex else { return }
        let note = store.notes[idx]
        store.deleteNote(note) { _ in
            dismiss()
        }
    }
}
