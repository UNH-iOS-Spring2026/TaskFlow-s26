import Foundation
import Combine
import FirebaseAuth
import FirebaseCore

// This class manages authentication (login, signup, logout)
final class AuthStore: ObservableObject {
    
    // Tracks if user is logged in
    @Published var isLoggedIn: Bool = false
    
    // Stores current user's email
    @Published var currentEmail: String? = nil
    
    // Stores current user's ID
    @Published var currentUserId: String? = nil

    // Listener for auth state changes
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        // Configure Firebase if not already done
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // Listen for login/logout changes
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isLoggedIn = user != nil
                self?.currentEmail = user?.email
                self?.currentUserId = user?.uid
            }
        }
    }

    deinit {
        // Remove listener when object is destroyed
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // Create a new account
    func createAccount(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        
        // Clean email and password
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let password = password.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check valid email
        guard email.contains("@"), email.contains(".") else {
            completion(false, "Enter a valid email.")
            return
        }

        // Check password length
        guard password.count >= 6 else {
            completion(false, "Password must be at least 6 characters.")
            return
        }

        // Create user using Firebase
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error {
                    completion(false, error.localizedDescription)
                    return
                }

                // Update user info after signup
                self?.isLoggedIn = true
                self?.currentEmail = result?.user.email
                self?.currentUserId = result?.user.uid
                completion(true, nil)
            }
        }
    }

    // Login existing user
    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        
        // Clean input
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let password = password.trimmingCharacters(in: .whitespacesAndNewlines)

        // Sign in with Firebase
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error {
                    completion(false, error.localizedDescription)
                    return
                }

                // Update user info after login
                self?.isLoggedIn = true
                self?.currentEmail = result?.user.email
                self?.currentUserId = result?.user.uid
                completion(true, nil)
            }
        }
    }

    // Logout current user
    func logout(completion: ((Bool, String?) -> Void)? = nil) {
        do {
            // Sign out from Firebase
            try Auth.auth().signOut()
            
            // Clear user data
            isLoggedIn = false
            currentEmail = nil
            currentUserId = nil
            
            completion?(true, nil)
        } catch {
            completion?(false, error.localizedDescription)
        }
    }

    // Send password reset email
    func resetPassword(email: String, completion: @escaping (Bool, String?) -> Void) {
        
        // Clean email
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Request password reset
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
