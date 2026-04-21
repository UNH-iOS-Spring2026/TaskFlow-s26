//
//  BiometricAuthManager.swift
//  Task_Flow
//
// code is assisted by chatgpt to help through errors

import Foundation
import LocalAuthentication
import Combine

//Manages biometric authentication (Face ID / Touch ID)
final class BiometricAuthManager: ObservableObject {

    //Represents the type of biometric authentication available
    enum Kind {
        case none
        case faceID
        case touchID

        //User-friendly title for UI display
        var title: String {
            switch self {
            case .faceID:
                return "Face ID"
            case .touchID:
                return "Touch ID"
            case .none:
                return "Biometrics"
            }
        }

        //SF Symbol name for corresponding biometric icon
        var iconSystemName: String {
            switch self {
            case .faceID:
                return "faceid"
            case .touchID:
                return "touchid"
            case .none:
                return "lock"
            }
        }
    }

    //Type of biometric available on the device
    @Published private(set) var kind: Kind = .none

    // Indicates whether biometric authentication is available
    @Published private(set) var isAvailable: Bool = false

    //Stores the last error message (if any)
    @Published var lastErrorMessage: String? = nil

    //Initializer automatically checks biometric availability
    init() {
        refresh()
    }

    //Checks and updates the current biometric availability and type
    func refresh() {
        let context = LAContext()
        var error: NSError?

        // Check if biometric authentication can be evaluated
        let canEvaluate = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )

        // Update UI-related properties on main thread
        DispatchQueue.main.async {
            self.isAvailable = canEvaluate

            if canEvaluate {
                // Determine which biometric type is available
                switch context.biometryType {
                case .faceID:
                    self.kind = .faceID
                case .touchID:
                    self.kind = .touchID
                default:
                    self.kind = .none
                }
                self.lastErrorMessage = nil
            } else {
                // If biometrics not available, store error
                self.kind = .none
                self.lastErrorMessage = error?.localizedDescription
            }
        }
    }

    //Performs biometric authentication
    //- Parameters:
    //  - reason: Message shown to user explaining why authentication is needed
    //  - completion: Returns success status and optional error message
    func authenticate(reason: String,
                      completion: @escaping (Bool, String?) -> Void) {

        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var error: NSError?

        // Ensure biometrics can be used before attempting authentication
        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ) else {
            DispatchQueue.main.async {
                completion(false,
                           error?.localizedDescription ?? "Biometrics not available.")
            }
            return
        }

        // Trigger biometric authentication prompt
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        ) { success, authError in

            // Return result on main thread for UI updates
            DispatchQueue.main.async {
                completion(success, authError?.localizedDescription)
            }
        }
    }
}
