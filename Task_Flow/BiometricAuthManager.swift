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
        let ctx = LAContext()
        var err: NSError?
        let ok = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)

        DispatchQueue.main.async {
            self.isAvailable = ok
            if ok {
                switch ctx.biometryType {
                case .faceID: self.kind = .faceID
                case .touchID: self.kind = .touchID
                default: self.kind = .none
                }
                self.lastErrorMessage = nil
            } else {
                self.kind = .none
                self.lastErrorMessage = err?.localizedDescription
            }
        }
    }

    func authenticate(reason: String, completion: @escaping (Bool, String?) -> Void) {
        let ctx = LAContext()
        ctx.localizedCancelTitle = "Cancel"

        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
            completion(false, err?.localizedDescription ?? "Biometrics not available.")
            return
        }

        ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            completion(success, error?.localizedDescription)
        }
    }
}
