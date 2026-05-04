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
                self?.isLoggedIn = user != nil
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

    func createAccount(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let password = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard email.contains("@"), email.contains(".") else {
            completion(false, "Enter a valid email.")
            return
        }

        guard password.count >= 6 else {
            completion(false, "Password must be at least 6 characters.")
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error {
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

    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let password = password.trimmingCharacters(in: .whitespacesAndNewlines)

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error {
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
            isLoggedIn = false
            currentEmail = nil
            currentUserId = nil
            completion?(true, nil)
        } catch {
            completion?(false, error.localizedDescription)
        }
    }

    func resetPassword(email: String, completion: @escaping (Bool, String?) -> Void) {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                if let error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        }
    }
}
