//
//  BiometricAuthManager.swift
//  Task_Flow
//

import Foundation
import LocalAuthentication
import Combine

final class BiometricAuthManager: ObservableObject {

    enum Kind {
        case none
        case faceID
        case touchID

        var title: String {
            switch self {
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            case .none: return "Biometrics"
            }
        }

        var iconSystemName: String {
            switch self {
            case .faceID: return "faceid"
            case .touchID: return "touchid"
            case .none: return "lock"
            }
        }
    }

    @Published private(set) var kind: Kind = .none
    @Published private(set) var isAvailable: Bool = false
    @Published var lastErrorMessage: String? = nil

    init() {
        refresh()
    }

    func refresh() {
        let context = LAContext()
        var error: NSError?

        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        DispatchQueue.main.async {
            self.isAvailable = canEvaluate

            if canEvaluate {
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
                self.kind = .none
                self.lastErrorMessage = error?.localizedDescription
            }
        }
    }

    func authenticate(reason: String, completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            DispatchQueue.main.async {
                completion(false, error?.localizedDescription ?? "Biometrics not available.")
            }
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                               localizedReason: reason) { success, authError in
            DispatchQueue.main.async {
                completion(success, authError?.localizedDescription)
            }
        }
    }
}
