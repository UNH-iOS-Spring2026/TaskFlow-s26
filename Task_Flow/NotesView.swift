import SwiftUI

struct NotesView: View {
    @EnvironmentObject var store: AppStore
    @AppStorage("tf_dark_mode") private var darkMode = false

    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var searchText: String = ""
    @State private var editingNote: NoteItem?

    var filteredNotes: [NoteItem] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return store.notes }

        return store.notes.filter {
            $0.title.lowercased().contains(q) ||
            $0.body.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                background.ignoresSafeArea()

                VStack(spacing: 16) {
                    inputCard

                    searchBar

                    if filteredNotes.isEmpty {
                        Spacer()
                        Text("No notes found")
                            .foregroundColor(secondaryText)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredNotes) { note in
                                    noteCard(note)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
                .padding(.top, 10)
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $editingNote) { note in
                EditNoteSheet(note: note) { updatedNote in
                    store.updateNote(updatedNote)
                } onDelete: { noteToDelete in
                    store.deleteNote(noteToDelete)
                }
                .preferredColorScheme(darkMode ? .dark : .light)
            }
        }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create Note")
                .font(.title2.bold())
                .foregroundColor(primaryText)

            TextField("Title", text: $title)
                .padding(12)
                .background(fieldBackground)
                .foregroundColor(primaryText)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            TextField("Write your note...", text: $bodyText, axis: .vertical)
                .lineLimit(4...8)
                .padding(12)
                .background(fieldBackground)
                .foregroundColor(primaryText)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                addNote()
            } label: {
                Text("Save Note")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(cardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var searchBar: some View {
        TextField("Search notes...", text: $searchText)
            .padding(12)
            .background(cardBackground)
            .foregroundColor(primaryText)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
    }

    private func noteCard(_ note: NoteItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.headline)
                    .foregroundColor(primaryText)

                Spacer()

                Button {
                    store.deleteNote(note)
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }

            if !note.body.isEmpty {
                Text(note.body)
                    .font(.subheadline)
                    .foregroundColor(secondaryText)
                    .lineLimit(4)
            }

            Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(secondaryText)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(noteAccent(note.colorSeed))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            editingNote = note
        }
    }

    private func addNote() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBody = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanTitle.isEmpty || !cleanBody.isEmpty else { return }

        store.addNote(
            title: cleanTitle.isEmpty ? "Untitled" : cleanTitle,
            body: cleanBody
        )

        title = ""
        bodyText = ""
    }

    private func noteAccent(_ seed: Int) -> Color {
        let colors: [Color] = [
            Color.purple.opacity(0.16),
            Color.blue.opacity(0.16),
            Color.orange.opacity(0.18),
            Color.green.opacity(0.16),
            Color.pink.opacity(0.16),
            Color.yellow.opacity(0.18)
        ]

        return colors[abs(seed) % colors.count]
    }

    private var background: some View {
        LinearGradient(
            colors: darkMode
            ? [Color.black, Color(red: 0.04, green: 0.05, blue: 0.14)]
            : [Color(red: 0.96, green: 0.97, blue: 1.0), Color.white],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var primaryText: Color {
        darkMode ? .white : .black
    }

    private var secondaryText: Color {
        darkMode ? .white.opacity(0.7) : .black.opacity(0.6)
    }

    private var cardBackground: Color {
        darkMode ? .white.opacity(0.08) : .white.opacity(0.9)
    }

    private var fieldBackground: Color {
        darkMode ? .white.opacity(0.08) : .black.opacity(0.05)
    }

    private var cardBorder: Color {
        darkMode ? .white.opacity(0.08) : .black.opacity(0.06)
    }
}

struct EditNoteSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var note: NoteItem

    let onSave: (NoteItem) -> Void
    let onDelete: (NoteItem) -> Void

    init(
        note: NoteItem,
        onSave: @escaping (NoteItem) -> Void,
        onDelete: @escaping (NoteItem) -> Void
    ) {
        _note = State(initialValue: note)
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Note") {
                    TextField("Title", text: $note.title)

                    TextField("Body", text: $note.body, axis: .vertical)
                        .lineLimit(6...12)
                }

                Section {
                    Button("Save Changes") {
                        note.title = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
                        note.body = note.body.trimmingCharacters(in: .whitespacesAndNewlines)

                        if note.title.isEmpty {
                            note.title = "Untitled"
                        }

                        onSave(note)
                        dismiss()
                    }

                    Button("Delete Note", role: .destructive) {
                        onDelete(note)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
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
