//
//  VaultView.swift
//  Task_Flow


import SwiftUI

struct VaultView: View {
    @AppStorage("tf_dark_mode") private var darkMode = false

    // MARK: - Vault State

    // Controls biometric access before showing saved vault items.
    @StateObject private var gate = LocalAuthGate()

    // Stores saved vault items loaded from Keychain.
    @State private var items: [VaultItem] = []

    // Controls the Add Vault Item sheet.
    @State private var showAdd = false

    // Stores Keychain loading or saving errors.
    @State private var loadError: String? = nil

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                background

                Group {
                    if gate.unlocked {
                        unlockedList
                    } else {
                        lockedView
                    }
                }
            }
            .navigationTitle("Vault")
            .toolbarBackground(darkMode ? Color.black : Color.white, for: .navigationBar)
            .toolbarColorScheme(darkMode ? .dark : .light, for: .navigationBar)
            .toolbar {
                if gate.unlocked {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Lock") {
                            gate.lock()
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showAdd = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddVaultItemSheet { newItem in
                    items.insert(newItem, at: 0)
                    persist()
                }
                .preferredColorScheme(darkMode ? .dark : .light)
            }
            .onAppear {
                loadVaultItems()
            }
            .alert("Vault Error", isPresented: Binding(get: { loadError != nil }, set: { _ in loadError = nil })) {
                Button("OK", role: .cancel) {
                    loadError = nil
                }
            } message: {
                Text(loadError ?? "")
            }
        }
    }

    // MARK: - Unlocked Vault List

    // Shows saved vault items after biometric unlock succeeds.
    private var unlockedList: some View {
        List {
            ForEach(items.sorted(by: { $0.createdAt > $1.createdAt })) { v in
                VStack(alignment: .leading, spacing: 8) {
                    Text(v.title)
                        .font(.headline)
                        .foregroundColor(primaryText)

                    HStack {
                        Text("User: \(v.username)")
                            .foregroundColor(primaryText)

                        Spacer()

                        Button {
                            UIPasteboard.general.string = v.username
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                    }

                    HStack {
                        Text("Pass: ••••••••")
                            .foregroundColor(primaryText)

                        Spacer()

                        Button {
                            UIPasteboard.general.string = v.password
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                }
                .padding(.vertical, 4)
                .listRowBackground(cardBackground)
            }
            .onDelete { idx in
                deleteItems(at: idx)
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
    }

    // MARK: - Locked View

    // Shows the locked vault screen before biometric authentication.
    private var lockedView: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.system(size: 42))
                .foregroundColor(primaryText)

            Text("Vault Locked")
                .font(.headline)
                .foregroundColor(primaryText)

            if let e = gate.lastError {
                Text(e)
                    .font(.footnote)
                    .foregroundColor(secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button("Unlock") {
                gate.unlock()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Theme

    // Main vault background for light and dark mode.
    private var background: some View {
        LinearGradient(
            colors: darkMode
            ? [
                Color.black,
                Color(red: 8/255, green: 12/255, blue: 42/255),
                Color.black
            ]
            : [
                Color(red: 0.96, green: 0.97, blue: 1.00),
                Color.white
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // Row background color for saved vault items.
    private var cardBackground: Color {
        darkMode ? Color.white.opacity(0.08) : Color.white
    }

    // Main text color based on the selected theme.
    private var primaryText: Color {
        darkMode ? .white : .black
    }

    // Secondary text color used for biometric error messages.
    private var secondaryText: Color {
        darkMode ? .white.opacity(0.65) : .black.opacity(0.55)
    }

    // MARK: - Keychain Actions

    // Loads vault items from Keychain when the screen opens.
    private func loadVaultItems() {
        do {
            items = try KeychainVault.shared.load()
        } catch {
            loadError = error.localizedDescription
        }
    }

    // Saves the current vault item list to Keychain.
    private func persist() {
        do {
            try KeychainVault.shared.save(items: items)
        } catch {
            loadError = error.localizedDescription
        }
    }

    // Deletes selected vault items from the list and updates Keychain storage.
    private func deleteItems(at offsets: IndexSet) {
        let sorted = items.sorted(by: { $0.createdAt > $1.createdAt })
        let ids = offsets.map { sorted[$0].id }

        items.removeAll { ids.contains($0.id) }
        persist()
    }
}

// MARK: - Add Vault Item Sheet

// Sheet used to add a new username and password record to the vault.
struct AddVaultItemSheet: View {
    @Environment(\.dismiss) var dismiss

    var onSave: (VaultItem) -> Void

    // MARK: - Form State

    // Stores the display title for the vault item.
    @State private var title = ""

    // Stores the username or email for the vault item.
    @State private var username = ""

    // Stores the password for the vault item.
    @State private var password = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title (ex: Gmail)", text: $title)

                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("Password", text: $password)
            }
            .navigationTitle("Add Login")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveItem()
                    }
                }
            }
        }
    }

    // MARK: - Save Logic

    // Validates the form and sends the new vault item back to VaultView.
    private func saveItem() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanTitle.isEmpty, !cleanUsername.isEmpty, !cleanPassword.isEmpty else {
            return
        }

        onSave(
            VaultItem(
                title: cleanTitle,
                username: cleanUsername,
                password: cleanPassword
            )
        )

        dismiss()
    }
}
