//
//  LocalAuthGate.swift
//  Task_Flow
//
//  Created by Aravind Ganipisetty on 2/11/26.
//

import Foundation
import Combine
import LocalAuthentication

final class LocalAuthGate: ObservableObject {
    @Published var unlocked: Bool = false
    @Published var lastError: String? = nil

    func unlock() {
        let ctx = LAContext()
        var err: NSError?

        guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &err) else {
            lastError = "No device passcode/biometrics set."
            return
        }

        ctx.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock Vault") { success, error in
            DispatchQueue.main.async {
                self.unlocked = success
                self.lastError = error?.localizedDescription
            }
        }
    }

    func lock() { unlocked = false }
}

