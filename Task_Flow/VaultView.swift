//
//  VaultView.swift
//  Task_Flow
//
//  Created by Aravind Ganipisetty on 2/11/26.
//

import SwiftUI

struct VaultView: View {
    @StateObject private var gate = LocalAuthGate()
    @State private var items: [VaultItem] = []
    @State private var showAdd = false
    @State private var loadError: String? = nil

    var body: some View {
        NavigationStack {
            Group {
                if gate.unlocked {
                    List {
                        ForEach(items.sorted(by: { $0.createdAt > $1.createdAt })) { v in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(v.title).font(.headline)

                                HStack {
                                    Text("User: \(v.username)")
                                    Spacer()
                                    Button { UIPasteboard.general.string = v.username } label: {
                                        Image(systemName: "doc.on.doc")
                                    }
                                }

                                HStack {
                                    Text("Pass: ••••••••")
                                    Spacer()
                                    Button { UIPasteboard.general.string = v.password } label: {
                                        Image(systemName: "doc.on.doc")
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { idx in
                            let sorted = items.sorted(by: { $0.createdAt > $1.createdAt })
                            let ids = idx.map { sorted[$0].id }
                            items.removeAll { ids.contains($0.id) }
                            persist()
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.fill").font(.system(size: 40))
                        Text("Vault Locked").font(.headline)
                        if let e = gate.lastError { Text(e).foregroundStyle(.secondary).multilineTextAlignment(.center) }
                        Button("Unlock") { gate.unlock() }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .navigationTitle("Vault")
            .toolbar {
                if gate.unlocked {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Lock") { gate.lock() }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showAdd = true } label: { Image(systemName: "plus") }
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddVaultItemSheet { newItem in
                    items.insert(newItem, at: 0)
                    persist()
                }
            }
            .onAppear {
                do { items = try KeychainVault.shared.load() }
                catch { loadError = error.localizedDescription }
            }
            .alert("Vault Error", isPresented: Binding(get: { loadError != nil }, set: { _ in loadError = nil })) {
                Button("OK", role: .cancel) { loadError = nil }
            } message: {
                Text(loadError ?? "")
            }
        }
    }

    private func persist() {
        do { try KeychainVault.shared.save(items: items) }
        catch { loadError = error.localizedDescription }
    }
}

struct AddVaultItemSheet: View {
    @Environment(\.dismiss) var dismiss
    var onSave: (VaultItem) -> Void

    @State private var title = ""
    @State private var username = ""
    @State private var password = ""

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
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !t.isEmpty, !username.isEmpty, !password.isEmpty else { return }
                        onSave(VaultItem(title: t, username: username, password: password))
                        dismiss()
                    }
                }
            }
        }
    }
}

