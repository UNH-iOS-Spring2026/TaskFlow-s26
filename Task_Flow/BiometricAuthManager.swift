//
//  BiometricAuthManager.swift
//  Task_Flow
//
//  Created by Aravind Ganipisetty
//

import Foundation
import Combine
import LocalAuthentication

// Defines the type of biometric authentication available on the device.
enum BiometricKind {
    case faceID
    case touchID
    case none

    // Display name used in Settings and Login screens.
    var title: String {
        switch self {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .none:
            return "Biometric"
        }
    }

    // SF Symbol used for the biometric login UI.
    var iconSystemName: String {
        switch self {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .none:
            return "lock.fill"
        }
    }
}

// Manages Face ID or Touch ID availability and authentication.
final class BiometricAuthManager: ObservableObject {

    // MARK: - Published Biometric State

    // Stores whether the current device supports Face ID, Touch ID, or neither.
    @Published var kind: BiometricKind = .none

    // Tracks whether biometric authentication can currently be used.
    @Published var isAvailable: Bool = false

    // Stores a readable reason when biometrics are not available.
    @Published var unavailableReason: String? = nil

    // MARK: - Initialization

    init() {
        refresh()
    }

    // MARK: - Availability Check

    // Checks the device and updates the current biometric type and availability.
    func refresh() {
        let context = LAContext()
        context.localizedFallbackTitle = ""
        context.localizedCancelTitle = "Cancel"

        var error: NSError?

        let canUseBiometrics = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )

        DispatchQueue.main.async {
            self.isAvailable = canUseBiometrics

            switch context.biometryType {
            case .faceID:
                self.kind = .faceID
            case .touchID:
                self.kind = .touchID
            default:
                self.kind = .none
            }

            if canUseBiometrics {
                self.unavailableReason = nil
            } else {
                self.unavailableReason = self.message(for: error)
            }
        }
    }

    // MARK: - Authentication

    // Starts Face ID or Touch ID authentication using the given reason text.
    func authenticate(reason: String, completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()

        // Empty fallback title removes the passcode fallback option.
        context.localizedFallbackTitle = ""
        context.localizedCancelTitle = "Cancel"

        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            DispatchQueue.main.async {
                completion(false, self.message(for: error))
            }
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        ) { success, authError in
            DispatchQueue.main.async {
                if success {
                    completion(true, nil)
                } else {
                    completion(false, self.message(for: authError as NSError?))
                }
            }
        }
    }

    // MARK: - Error Handling

    // Converts LocalAuthentication errors into clear messages for the user.
    private func message(for error: NSError?) -> String {
        guard let error else {
            return "Biometric authentication is not available."
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
