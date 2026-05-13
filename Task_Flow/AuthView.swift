//
//  AuthView.swift
//  Task_Flow
import SwiftUI
import LocalAuthentication

struct AuthView: View {
    @EnvironmentObject var auth: AuthStore

    // Stores whether biometric login is enabled from Settings.
    @AppStorage("tf_biometric_enabled") private var biometricEnabled = false

    // MARK: - Form State

    // Controls whether the screen is in Login mode or Sign Up mode.
    @State private var isLoginMode = true

    // User input fields for authentication.
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    // Used for the forgot password sheet.
    @State private var forgotEmail = ""
    @State private var showForgotPasswordSheet = false

    // Messages shown to the user after login, sign up, reset, or biometric action.
    @State private var errorMessage = ""
    @State private var infoMessage = ""

    // Prevents repeated button taps while Firebase is processing.
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                background

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        header
                        modeSwitcher
                        formCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 30)
                }
            }
            .sheet(isPresented: $showForgotPasswordSheet) {
                forgotPasswordView
            }
        }
    }

    // MARK: - Background

    // Main authentication screen background.
    private var background: some View {
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
    }

    // MARK: - Header

    // Displays the app icon, app name, and short description.
    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist.checked")
                .font(.system(size: 54, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Task Flow")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)

            Text("Organize tasks, notes, reminders, and more")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    // MARK: - Login and Sign Up Switcher

    // Allows the user to switch between Login and Sign Up forms.
    private var modeSwitcher: some View {
        HStack(spacing: 0) {
            Button {
                clearMessages()
                isLoginMode = true
            } label: {
                Text("Login")
                    .font(.headline)
                    .foregroundColor(isLoginMode ? .white : .white.opacity(0.65))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isLoginMode ? Color.white.opacity(0.12) : Color.clear)
            }

            Button {
                clearMessages()
                isLoginMode = false
            } label: {
                Text("Sign Up")
                    .font(.headline)
                    .foregroundColor(!isLoginMode ? .white : .white.opacity(0.65))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(!isLoginMode ? Color.white.opacity(0.12) : Color.clear)
            }
        }
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Authentication Form

    // Main card containing email, password, login, sign up, biometric, and forgot password actions.
    private var formCard: some View {
        VStack(spacing: 16) {
            VStack(spacing: 14) {
                inputField(
                    title: "Email",
                    text: $email,
                    placeholder: "Enter your email",
                    isSecure: false
                )

                inputField(
                    title: "Password",
                    text: $password,
                    placeholder: "Enter your password",
                    isSecure: true
                )

                if !isLoginMode {
                    inputField(
                        title: "Confirm Password",
                        text: $confirmPassword,
                        placeholder: "Confirm your password",
                        isSecure: true
                    )
                }
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !infoMessage.isEmpty {
                Text(infoMessage)
                    .font(.footnote)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                submit()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                    }

                    Text(isLoginMode ? "Login" : "Create Account")
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
            .disabled(isLoading)

            // Shows biometric login only on the login screen after the user enables it in Settings.
            if isLoginMode && biometricEnabled {
                Button {
                    loginWithBiometrics()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: biometricIconName)
                            .font(.headline)

                        Text("Login with \(biometricTitle)")
                            .font(.headline.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .disabled(isLoading)
            }

            if isLoginMode {
                Button {
                    clearMessages()
                    forgotEmail = email
                    showForgotPasswordSheet = true
                } label: {
                    Text("Forgot Password?")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.blue)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Input Field

    // Reusable input field for email, password, and confirm password.
    private func inputField(
        title: String,
        text: Binding<String>,
        placeholder: String,
        isSecure: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white.opacity(0.8))

            Group {
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - Forgot Password Sheet

    // Sheet used to send Firebase password reset email.
    private var forgotPasswordView: some View {
        NavigationStack {
            ZStack {
                background

                VStack(spacing: 18) {
                    Text("Reset Password")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text("Enter your email and we’ll send a reset link.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)

                    TextField("Email", text: $forgotEmail)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Button {
                        sendReset()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                            }

                            Text("Send Reset Link")
                                .font(.headline.bold())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .disabled(isLoading)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if !infoMessage.isEmpty {
                        Text(infoMessage)
                            .font(.footnote)
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Spacer()
                }
                .padding(20)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        showForgotPasswordSheet = false
                    }
                }
            }
        }
    }

    // MARK: - Submit Logic

    // Handles both Login and Sign Up depending on the selected mode.
    private func submit() {
        clearMessages()
        isLoading = true

        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        if isLoginMode {
            auth.login(email: cleanEmail, password: cleanPassword) { success, message in
                isLoading = false

                if success {
                    infoMessage = "Login successful."
                } else {
                    errorMessage = message ?? "Login failed."
                }
            }
        } else {
            let cleanConfirm = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)

            guard cleanPassword == cleanConfirm else {
                isLoading = false
                errorMessage = "Passwords do not match."
                return
            }

            auth.createAccount(email: cleanEmail, password: cleanPassword) { success, message in
                isLoading = false

                if success {
                    infoMessage = "Account created successfully."
                } else {
                    errorMessage = message ?? "Sign up failed."
                }
            }
        }
    }

    // MARK: - Biometric Login

    // Starts Face ID or Touch ID login using AuthStore.
    private func loginWithBiometrics() {
        clearMessages()
        isLoading = true

        auth.loginWithBiometrics { success, message in
            isLoading = false

            if success {
                infoMessage = "Biometric login successful."
            } else {
                errorMessage = message ?? "Biometric login failed."
            }
        }
    }

    // MARK: - Password Reset

    // Sends a password reset link to the entered email address.
    private func sendReset() {
        clearMessages()
        isLoading = true

        let cleanEmail = forgotEmail.trimmingCharacters(in: .whitespacesAndNewlines)

        auth.resetPassword(email: cleanEmail) { success, message in
            isLoading = false

            if success {
                infoMessage = message ?? "Password reset email sent. Check your inbox or spam folder."
            } else {
                errorMessage = message ?? "Could not send reset email."
            }
        }
    }

    // MARK: - Message Helpers

    // Clears old error and success messages before a new action starts.
    private func clearMessages() {
        errorMessage = ""
        infoMessage = ""
    }

    // MARK: - Biometric Display Helpers

    // Returns the correct biometric title based on the current device.
    private var biometricTitle: String {
        let context = LAContext()
        var error: NSError?
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Biometrics"
        }
    }

    // Returns the matching SF Symbol for Face ID, Touch ID, or fallback lock icon.
    private var biometricIconName: String {
        let context = LAContext()
        var error: NSError?
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        switch context.biometryType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "lock.fill"
        }
    }
}
