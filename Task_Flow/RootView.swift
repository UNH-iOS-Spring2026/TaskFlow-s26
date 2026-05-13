//
//  RootView.swift
//  Task_Flow

import SwiftUI

// RootView decides whether to show introduction pages, loading, login, biometric unlock, or the main app.
struct RootView: View {
    @EnvironmentObject var auth: AuthStore
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Onboarding State

    // Shows onboarding every time the app starts fresh from Xcode.
    // This is not stored permanently, so it resets on every new app run.
    @State private var showOnboarding = true

    // MARK: - Biometric State

    // Stores whether biometric login is enabled from Settings.
    @AppStorage("tf_biometric_enabled") private var biometricEnabled = false

    // Handles Face ID or Touch ID availability and authentication.
    @StateObject private var biometricManager = BiometricAuthManager()

    // Tracks whether the app session has already passed the main biometric unlock.
    @State private var biometricUnlocked = false

    // MARK: - Body

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView {
                    showOnboarding = false
                }
            } else if auth.isCheckingAuth {
                TaskFlowLoadingView()
            } else if auth.isLoggedIn {
                if biometricEnabled && !biometricUnlocked {
                    BiometricUnlockView(
                        biometricManager: biometricManager,
                        onUnlock: {
                            biometricUnlocked = true
                        },
                        onLogout: {
                            biometricUnlocked = false
                            auth.logout()
                        }
                    )
                } else {
                    MainTabView()
                }
            } else {
                AuthView()
            }
        }
        .onAppear {
            biometricManager.refresh()

            // If biometric login is off, let the logged-in user enter the app directly after onboarding.
            biometricUnlocked = auth.isLoggedIn && !biometricEnabled
        }
        .onChange(of: auth.isLoggedIn) { loggedIn in
            // Reset biometric unlock state when Firebase login state changes.
            biometricUnlocked = loggedIn && !biometricEnabled
        }
        .onChange(of: biometricEnabled) { enabled in
            // If biometric login is disabled, do not block the already logged-in user.
            biometricUnlocked = auth.isLoggedIn && !enabled
        }
        .onChange(of: scenePhase) { phase in
            // Do not lock on inactive because Face ID itself makes the app inactive temporarily.
            // Lock only when the app actually goes to the background.
            if auth.isLoggedIn && biometricEnabled && phase == .background {
                biometricUnlocked = false
            }
        }
    }
}

// MARK: - Loading View

// Shows a loading screen while Firebase checks the saved user session.
private struct TaskFlowLoadingView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 8/255, green: 12/255, blue: 42/255),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)

                Text("Loading Task Flow...")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.85))
            }
        }
    }
}

// MARK: - Biometric Unlock View

// Shows the main app biometric lock screen when biometric login is enabled.
private struct BiometricUnlockView: View {
    @ObservedObject var biometricManager: BiometricAuthManager

    let onUnlock: () -> Void
    let onLogout: () -> Void

    // MARK: - View State

    // Prevents multiple biometric prompts from opening at the same time.
    @State private var isAuthenticating = false

    // Stores the latest biometric error message.
    @State private var errorMessage = ""

    // Makes sure the automatic biometric prompt runs only once.
    @State private var hasAutoPrompted = false

    // MARK: - Body

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 8/255, green: 12/255, blue: 42/255),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Image(systemName: biometricManager.kind.iconSystemName)
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 8) {
                    Text("Unlock Task Flow")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)

                    Text("Use \(biometricManager.kind.title) to continue.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red.opacity(0.95))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    unlock()
                } label: {
                    HStack(spacing: 10) {
                        if isAuthenticating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: biometricManager.kind.iconSystemName)
                        }

                        Text("Unlock with \(biometricManager.kind.title)")
                            .font(.headline.bold())
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .disabled(isAuthenticating)

                Button {
                    onLogout()
                } label: {
                    Text("Logout and use another account")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white.opacity(0.78))
                }
                .padding(.top, 4)
            }
            .padding(24)
        }
        .onAppear {
            biometricManager.refresh()

            guard !hasAutoPrompted else {
                return
            }

            hasAutoPrompted = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                unlock()
            }
        }
    }

    // MARK: - Unlock Logic

    // Starts biometric authentication and opens the app if authentication succeeds.
    private func unlock() {
        guard !isAuthenticating else {
            return
        }

        errorMessage = ""
        isAuthenticating = true

        biometricManager.authenticate(reason: "Unlock Task Flow") { success, message in
            isAuthenticating = false

            if success {
                onUnlock()
            } else {
                errorMessage = message ?? "Authentication failed. Try again."
            }
        }
    }
}
