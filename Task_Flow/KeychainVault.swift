//
//  KeychainVault.swift
//  Task_Flow

import Foundation
import Security

// MARK: - Vault Item Model

// Represents one saved vault record.
// The item is Codable so it can be converted to Data before saving in Keychain.
struct VaultItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var username: String
    var password: String
    var createdAt: Date = Date()
}

// MARK: - Keychain Vault Manager

// Handles secure saving and loading of vault items using iOS Keychain.
final class KeychainVault {
    static let shared = KeychainVault()

    private init() {}

    // MARK: - Keychain Constants

    // Service name used to identify this app's Keychain data.
    private let service = "com.taskflow.vault"

    // Account key used for the saved vault item list.
    private let account = "vaultItems"

    // MARK: - Save Items

    // Saves all vault items securely in Keychain.
    func save(items: [VaultItem]) throws {
        let data = try JSONEncoder().encode(items)

        // Remove the old saved vault data before writing the updated list.
        SecItemDelete(query() as CFDictionary)

        var q = query()
        q[kSecValueData as String] = data
        q[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let status = SecItemAdd(q as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw NSError(domain: "Keychain", code: Int(status))
        }
    }

    // MARK: - Load Items

    // Loads saved vault items from Keychain.
    func load() throws -> [VaultItem] {
        var q = query()
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(q as CFDictionary, &result)

        // If nothing has been saved yet, return an empty list instead of throwing an error.
        if status == errSecItemNotFound {
            return []
        }

        guard status == errSecSuccess, let data = result as? Data else {
            throw NSError(domain: "Keychain", code: Int(status))
        }

        return try JSONDecoder().decode([VaultItem].self, from: data)
    }

    // MARK: - Keychain Query

    // Builds the shared Keychain query used for saving, loading, and deleting vault data.
    private func query() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
