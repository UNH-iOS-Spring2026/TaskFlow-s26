//
//  LocalAuthGate.swift
//  Task_Flow

import Foundation
import Combine
import LocalAuthentication

// Manages biometric unlock access for protected areas like Vault.
final class LocalAuthGate: ObservableObject {

    // MARK: - Published Auth State

    // Tracks whether the protected screen is currently unlocked.
    @Published var unlocked: Bool = false

    // Stores the latest biometric authentication error message.
    @Published var lastError: String? = nil

    // Tracks whether Face ID or Touch ID authentication is currently running.
    @Published var isAuthenticating: Bool = false

    // MARK: - Unlock

    // Starts biometric authentication and unlocks the protected screen if successful.
    func unlock() {
        lastError = nil
        isAuthenticating = true

        let ctx = LAContext()

        // Empty fallback title removes the passcode fallback button.
        ctx.localizedFallbackTitle = ""
        ctx.localizedCancelTitle = "Cancel"

        var err: NSError?

        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
            DispatchQueue.main.async {
                self.isAuthenticating = false
                self.unlocked = false
                self.lastError = self.biometricErrorMessage(err)
            }

            return
        }

        ctx.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Unlock Task Flow using Face ID"
        ) { success, error in
            DispatchQueue.main.async {
                self.isAuthenticating = false
                self.unlocked = success

                if success {
                    self.lastError = nil
                } else {
                    self.lastError = self.biometricErrorMessage(error as NSError?)
                }
            }
        }
    }

    // MARK: - Lock

    // Locks the protected screen and clears any previous authentication message.
    func lock() {
        unlocked = false
        lastError = nil
        isAuthenticating = false
    }

    // MARK: - Error Handling

    // Converts LocalAuthentication errors into clear user-facing messages.
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
