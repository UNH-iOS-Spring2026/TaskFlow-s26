import Foundation
import Combine
import FirebaseAuth
import FirebaseCore

final class AuthStore: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentEmail: String? = nil
    @Published var currentUserId: String? = nil

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isLoggedIn = (user != nil)
                self?.currentEmail = user?.email
                self?.currentUserId = user?.uid
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func createAccount(
        email: String,
        password: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        let e = normalize(email)
        let p = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidEmail(e) else {
            completion(false, "Enter a valid email address.")
            return
        }

        guard p.count >= 6 else {
            completion(false, "Password must be at least 6 characters.")
            return
        }

        Auth.auth().createUser(withEmail: e, password: p) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error.localizedDescription)
                    return
                }

                self?.isLoggedIn = true
                self?.currentEmail = result?.user.email
                self?.currentUserId = result?.user.uid
                completion(true, nil)
            }
        }
    }

    func login(
        email: String,
        password: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        let e = normalize(email)
        let p = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidEmail(e) else {
            completion(false, "Enter a valid email address.")
            return
        }

        guard !p.isEmpty else {
            completion(false, "Password cannot be empty.")
            return
        }

        Auth.auth().signIn(withEmail: e, password: p) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error.localizedDescription)
                    return
                }

                self?.isLoggedIn = true
                self?.currentEmail = result?.user.email
                self?.currentUserId = result?.user.uid
                completion(true, nil)
            }
        }
    }

    func logout(completion: ((Bool, String?) -> Void)? = nil) {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.isLoggedIn = false
                self.currentEmail = nil
                self.currentUserId = nil
                completion?(true, nil)
            }
        } catch {
            DispatchQueue.main.async {
                completion?(false, error.localizedDescription)
            }
        }
    }

    func resetPassword(email: String, completion: @escaping (Bool, String?) -> Void) {
        let e = normalize(email)

        guard isValidEmail(e) else {
            completion(false, "Enter a valid email address.")
            return
        }

        Auth.auth().sendPasswordReset(withEmail: e) { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        }
    }

    private func normalize(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func isValidEmail(_ s: String) -> Bool {
        s.contains("@") && s.contains(".") && s.count >= 5
    }
}
