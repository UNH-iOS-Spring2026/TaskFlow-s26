//
//  KeychainVault.swift
//  Task_Flow
//
//  Created by Aravind Ganipisetty on 2/11/26.
//


import Foundation
import Security

struct VaultItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var username: String
    var password: String
    var createdAt: Date = Date()
}

final class KeychainVault {
    static let shared = KeychainVault()
    private init() {}

    private let service = "com.taskflow.vault"
    private let account = "vaultItems"

    func save(items: [VaultItem]) throws {
        let data = try JSONEncoder().encode(items)

        // delete old
        SecItemDelete(query() as CFDictionary)

        // add new
        var q = query()
        q[kSecValueData as String] = data
        q[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let status = SecItemAdd(q as CFDictionary, nil)
        guard status == errSecSuccess else { throw NSError(domain: "Keychain", code: Int(status)) }
    }

    func load() throws -> [VaultItem] {
        var q = query()
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(q as CFDictionary, &result)

        if status == errSecItemNotFound { return [] }
        guard status == errSecSuccess, let data = result as? Data else {
            throw NSError(domain: "Keychain", code: Int(status))
        }
        return try JSONDecoder().decode([VaultItem].self, from: data)
    }

    private func query() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

