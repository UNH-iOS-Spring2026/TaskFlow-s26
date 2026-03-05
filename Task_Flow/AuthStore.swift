import Foundation
import Combine

final class AuthStore: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentEmail: String? = nil

    // Demo local accounts: email -> password
    @Published private(set) var accounts: [String: String] = [:]

    private let kLoggedIn = "tf_logged_in"
    private let kEmail = "tf_email"
    private let kAccounts = "tf_accounts"

    init() {
        // restore session
        isLoggedIn = UserDefaults.standard.bool(forKey: kLoggedIn)
        currentEmail = UserDefaults.standard.string(forKey: kEmail)

        // restore accounts
        if let data = UserDefaults.standard.data(forKey: kAccounts),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            accounts = decoded
        }
    }

    // MARK: - Demo Signup
    @discardableResult
    func createAccount(email: String, password: String) -> Bool {
        let e = normalize(email)
        let p = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidEmail(e), p.count >= 3 else { return false }
        guard accounts[e] == nil else { return false } // already exists

        accounts[e] = p
        persistAccounts()

        // auto-login after signup
        currentEmail = e
        isLoggedIn = true
        persistSession()
        return true
    }

    // MARK: - Demo Login
    @discardableResult
    func login(email: String, password: String) -> Bool {
        let e = normalize(email)
        let p = password.trimmingCharacters(in: .whitespacesAndNewlines)

        // If user never signed up, you said you want “demo”: allow any non-empty login
        if accounts.isEmpty {
            guard isValidEmail(e), !p.isEmpty else { return false }
            currentEmail = e
            isLoggedIn = true
            persistSession()
            return true
        }

        guard let saved = accounts[e], saved == p else { return false }

        currentEmail = e
        isLoggedIn = true
        persistSession()
        return true
    }

    func logout() {
        isLoggedIn = false
        currentEmail = nil
        persistSession()
    }

    // MARK: - Helpers
    private func normalize(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func isValidEmail(_ s: String) -> Bool {
        s.contains("@") && s.contains(".") && s.count >= 5
    }

    private func persistSession() {
        UserDefaults.standard.set(isLoggedIn, forKey: kLoggedIn)
        UserDefaults.standard.set(currentEmail, forKey: kEmail)
    }

    private func persistAccounts() {
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: kAccounts)
        }
    }
}
