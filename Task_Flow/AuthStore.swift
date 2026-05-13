//
//  AuthStore.swift
//  Task_Flow
import Foundation
import Combine
import FirebaseAuth
import FirebaseCore
import LocalAuthentication
import Security

// This class manages authentication (login, signup, logout)
final class AuthStore: ObservableObject {

    // MARK: - Published Authentication State

    // Tracks whether a Firebase user is currently signed in.
    @Published var isLoggedIn: Bool = false

    // Stores the signed-in user's email for display in the app.
    @Published var currentEmail: String? = nil

    // Stores the signed-in user's Firebase UID.
    @Published var currentUserId: String? = nil

    // Used to show loading state while Firebase checks the saved session.
    @Published var isCheckingAuth: Bool = true

    // MARK: - Firebase Auth Listener

    // Firebase listener handle used to track login/logout changes.
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    // MARK: - Initialization

    init() {
        // Firebase must be configured before using FirebaseAuth.
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // This listener keeps the app authentication state synced with Firebase.
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isLoggedIn = user != nil
                self?.currentEmail = user?.email
                self?.currentUserId = user?.uid
                self?.isCheckingAuth = false
            }
        }
    }

    deinit {
        // Removes Firebase auth listener when AuthStore is released.
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Create Account

    // Creates a new Firebase account using email and password.
    func createAccount(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        let cleanEmail = normalizeEmail(email)
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidEmail(cleanEmail) else {
            completion(false, "Enter a valid email address.")
            return
        }

        guard cleanPassword.count >= 6 else {
            completion(false, "Password must be at least 6 characters.")
            return
        }

        Auth.auth().createUser(withEmail: cleanEmail, password: cleanPassword) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error {
                    completion(false, self?.friendlyMessage(for: error) ?? error.localizedDescription)
                    return
                }

                // Saves login credentials securely for future biometric login.
                BiometricCredentialStore.save(email: cleanEmail, password: cleanPassword)

                self?.isLoggedIn = true
                self?.currentEmail = result?.user.email
                self?.currentUserId = result?.user.uid

                completion(true, nil)
            }
        }
    }

    // MARK: - Login

    // Signs in an existing user with Firebase email/password authentication.
    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        let cleanEmail = normalizeEmail(email)
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidEmail(cleanEmail) else {
            completion(false, "Enter a valid email address.")
            return
        }

        guard !cleanPassword.isEmpty else {
            completion(false, "Enter your password.")
            return
        }

        Auth.auth().signIn(withEmail: cleanEmail, password: cleanPassword) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error {
                    completion(false, self?.friendlyMessage(for: error) ?? error.localizedDescription)
                    return
                }

                // Saves credentials securely so Face ID or Touch ID can login later.
                BiometricCredentialStore.save(email: cleanEmail, password: cleanPassword)

                self?.isLoggedIn = true
                self?.currentEmail = result?.user.email
                self?.currentUserId = result?.user.uid

                completion(true, nil)
            }
        }
    }

    // MARK: - Biometric Login

    // Logs the user in with Face ID or Touch ID after biometric verification succeeds.
    func loginWithBiometrics(completion: @escaping (Bool, String?) -> Void) {
        let biometricEnabled = UserDefaults.standard.bool(forKey: "tf_biometric_enabled")

        guard biometricEnabled else {
            completion(false, "Biometric login is not enabled. Login once and enable it in Settings.")
            return
        }

        guard let savedCredential = BiometricCredentialStore.load() else {
            completion(false, "No saved login found. Login once with email and password, then enable biometric login.")
            return
        }

        let context = LAContext()

        // Empty fallback title removes the passcode fallback button from the biometric prompt.
        context.localizedFallbackTitle = ""
        context.localizedCancelTitle = "Cancel"

        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(false, biometricErrorMessage(error))
            return
        }

        let reason = "Use Face ID to login to Task Flow."

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authError in
            if success {
                Auth.auth().signIn(withEmail: savedCredential.email, password: savedCredential.password) { result, signInError in
                    DispatchQueue.main.async {
                        if let signInError {
                            completion(false, self?.friendlyMessage(for: signInError) ?? signInError.localizedDescription)
                            return
                        }

                        self?.isLoggedIn = true
                        self?.currentEmail = result?.user.email
                        self?.currentUserId = result?.user.uid

                        completion(true, nil)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(false, self?.biometricErrorMessage(authError as NSError?) ?? "Face ID authentication failed.")
                }
            }
        }
    }

    // MARK: - Logout

    // Signs the user out of Firebase.
    func logout(completion: ((Bool, String?) -> Void)? = nil) {
        do {
            // Sign out from Firebase
            try Auth.auth().signOut()

            isLoggedIn = false
            currentEmail = nil
            currentUserId = nil

            // Do not remove biometric settings or Keychain credentials here.
            // If removed, the biometric login button will disappear after logout.
            completion?(true, nil)
        } catch {
            completion?(false, error.localizedDescription)
        }
    }

    // MARK: - Password Reset

    // Sends a Firebase password reset email to the user's registered email address.
    func resetPassword(email: String, completion: @escaping (Bool, String?) -> Void) {
        let cleanEmail = normalizeEmail(email)

        guard isValidEmail(cleanEmail) else {
            completion(false, "Enter the email address used for your account.")
            return
        }

        Auth.auth().sendPasswordReset(withEmail: cleanEmail) { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    completion(false, self?.friendlyMessage(for: error) ?? error.localizedDescription)
                } else {
                    completion(true, "Password reset email sent. Check your inbox or spam folder.")
                }
            }
        }
    }

    // MARK: - Validation Helpers

    // Trims spaces and converts email to lowercase before Firebase authentication.
    private func normalizeEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // Performs a basic email format check before sending requests to Firebase.
    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    // Converts Firebase and system errors into user-friendly messages.
    private func friendlyMessage(for error: Error) -> String {
        error.localizedDescription
    }

    // MARK: - Biometric Error Messages

    // Converts LocalAuthentication errors into clearer messages for the login screen.
    private func biometricErrorMessage(_ error: NSError?) -> String {
        guard let error else {
            return "Face ID is not available."
        }

        guard let code = LAError.Code(rawValue: error.code) else {
            return error.localizedDescription
        }

        switch code {
        case .biometryNotAvailable:
            return "Face ID is not available on this simulator or device."

        case .biometryNotEnrolled:
            return "Face ID is not enrolled. In Simulator, use Features → Face ID → Enrolled."

        case .biometryLockout:
            return "Face ID is locked because of too many failed attempts. Restart the simulator and try again."

        case .authenticationFailed:
            return "Face ID did not match. Try again."

        case .userCancel:
            return "Face ID authentication was cancelled."

        case .userFallback:
            return "Passcode fallback is disabled. Please use Face ID."

        default:
            return error.localizedDescription
        }
    }
}

// MARK: - Saved Firebase Credential Model

// Stores Firebase email and password before saving them securely in Keychain.
private struct SavedFirebaseCredential: Codable {
    let email: String
    let password: String
}

// MARK: - Biometric Credential Store

// Handles secure saving and loading of Firebase credentials from iOS Keychain.
private enum BiometricCredentialStore {
    private static let service = "TaskFlow.BiometricLogin"
    private static let account = "FirebaseEmailPassword"

    // Saves the user's email and password securely in Keychain.
    static func save(email: String, password: String) {
        let credential = SavedFirebaseCredential(email: email, password: password)

        guard let data = try? JSONEncoder().encode(credential) else {
            return
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        // Deletes any previous saved credentials before adding the latest one.
        SecItemDelete(query as CFDictionary)

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        SecItemAdd(attributes as CFDictionary, nil)
    }

    // Loads saved Firebase credentials from Keychain for biometric login.
    static func load() -> SavedFirebaseCredential? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let credential = try? JSONDecoder().decode(SavedFirebaseCredential.self, from: data)
        else {
            return nil
        }

        return credential
    }
}
