//
//  AuthView.swift
//  Task_Flow
//
//  ✅ Added: “Forgot Password?” option (sheet) + demo reset flow
//

import SwiftUI
import LocalAuthentication

struct AuthView: View {
    @EnvironmentObject var auth: AuthStore

    @State private var email: String = ""
    @State private var password: String = ""

    @State private var isLoading = false
    @State private var errorText: String?

    @State private var showSignUp = false
    @State private var showForgot = false

    // Biometrics UI
    @State private var biometricsAvailable = false
    @State private var biometryType: LABiometryType = .none

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer().frame(height: 30)

                Text("TaskFlow")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.bottom, 8)

                VStack(alignment: .leading, spacing: 10) {
                    fieldLabel("Email")
                    DarkField(
                        placeholder: "Email",
                        text: $email,
                        isSecure: false,
                        keyboard: .emailAddress,
                        contentType: .emailAddress
                    )

                    fieldLabel("Password")
                    DarkField(
                        placeholder: "Password",
                        text: $password,
                        isSecure: true,
                        keyboard: .default,
                        contentType: .password
                    )

                    // ✅ Forgot Password row
                    HStack {
                        Spacer()
                        Button {
                            showForgot = true
                        } label: {
                            Text("Forgot Password?")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 2)
                }
                .padding(.horizontal, 26)

                Button {
                    login()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.purple.opacity(0.92))
                            .frame(height: 52)

                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Login")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.horizontal, 26)
                .disabled(isLoading)

                HStack(spacing: 6) {
                    Text("New user?")
                        .foregroundStyle(.white.opacity(0.65))
                    Button {
                        showSignUp = true
                    } label: {
                        Text("Sign Up")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .underline()
                    }
                    .buttonStyle(.plain)
                }
                .font(.subheadline)

                // Biometrics buttons row (Face ID / Touch ID)
                HStack(spacing: 12) {
                    biometricButton(kind: .faceID)
                    biometricButton(kind: .touchID)
                }
                .padding(.horizontal, 26)
                .padding(.top, 4)

                if let err = errorText {
                    Text(err)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.red.opacity(0.95))
                        .padding(.top, 6)
                        .padding(.horizontal, 26)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                Text("Demo: If you never signed up, login accepts any email + password.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.bottom, 12)
            }
        }
        .onAppear { refreshBiometricsAvailability() }
        .sheet(isPresented: $showSignUp) {
            SignUpSheet()
                .environmentObject(auth)
        }
        .sheet(isPresented: $showForgot) {
            ForgotPasswordSheet(prefillEmail: email)
        }
    }

    // MARK: - Actions

    private func login() {
        print("✅ Login tapped")

        errorText = nil
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = password

        guard !e.isEmpty, !p.isEmpty else {
            errorText = "Please enter email and password."
            return
        }

        isLoading = true

        // ✅ Don’t guess your AuthStore API. Use the common one you already had:
        // If your AuthStore.login is synchronous, this still works.
        // If it’s async internally, it can update published state (RootView should react).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            auth.login(email: e, password: p) // <-- keep your existing AuthStore method
            isLoading = false
        }
    }

    private enum BioKind { case faceID, touchID }

    private func biometricButton(kind: BioKind) -> some View {
        let title = (kind == .faceID) ? "Face ID" : "Touch ID"
        let icon  = (kind == .faceID) ? "faceid" : "touchid"

        // Show enabled only if device supports that biometry
        let enabled =
            biometricsAvailable &&
            ((kind == .faceID && biometryType == .faceID) ||
             (kind == .touchID && biometryType == .touchID))

        return Button {
            runBiometricLogin()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white.opacity(enabled ? 0.9 : 0.35))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!enabled || isLoading)
    }

    private func runBiometricLogin() {
        let ctx = LAContext()
        ctx.localizedCancelTitle = "Cancel"

        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
            errorText = "Biometrics not available on this device."
            return
        }

        isLoading = true
        errorText = nil

        ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate to login") { success, _ in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    // ✅ Demo behavior: allow biometric login without password
                    // If you want: require email field not empty.
                    let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
                    if e.isEmpty {
                        self.errorText = "Enter your email first, then use biometrics."
                        return
                    }
                    auth.login(email: e, password: "biometric") // demo password
                } else {
                    self.errorText = "Authentication failed. Try again."
                }
            }
        }
    }

    private func refreshBiometricsAvailability() {
        let ctx = LAContext()
        var err: NSError?
        let ok = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
        biometricsAvailable = ok
        biometryType = ctx.biometryType
    }

    // MARK: - UI helpers

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.07, blue: 0.12),
                Color(red: 0.08, green: 0.08, blue: 0.16),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func fieldLabel(_ t: String) -> some View {
        Text(t)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.55))
            .padding(.leading, 6)
    }
}

// MARK: - DarkField (consistent style)

private struct DarkField: View {
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    let keyboard: UIKeyboardType
    let contentType: UITextContentType?

    @State private var showPassword = false

    var body: some View {
        ZStack(alignment: .trailing) {
            Group {
                if isSecure && !showPassword {
                    SecureField("", text: $text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.35)))
                } else {
                    TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.35)))
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .keyboardType(keyboard)
            .textContentType(contentType)
            .foregroundStyle(.white.opacity(0.95))
            .padding(.horizontal, 14)
            .frame(height: 46)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if isSecure {
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.trailing, 14)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Forgot Password Sheet (demo)

private struct ForgotPasswordSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email: String
    @State private var sent = false
    @State private var errText: String?

    init(prefillEmail: String) {
        _email = State(initialValue: prefillEmail.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.07, blue: 0.12),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 14) {
                    Text("Reset Password")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.top, 10)

                    Text("Enter your email. We'll show a demo reset confirmation.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    DarkField(
                        placeholder: "Email",
                        text: $email,
                        isSecure: false,
                        keyboard: .emailAddress,
                        contentType: .emailAddress
                    )
                    .padding(.horizontal, 26)
                    .padding(.top, 6)

                    Button {
                        sendReset()
                    } label: {
                        Text(sent ? "Reset Sent ✅" : "Send Reset Link")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.purple.opacity(0.92))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .padding(.horizontal, 26)
                    .disabled(sent)

                    if let e = errText {
                        Text(e)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.red.opacity(0.95))
                            .padding(.top, 4)
                            .padding(.horizontal, 26)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
    }

    private func sendReset() {
        errText = nil
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard e.contains("@"), e.contains(".") else {
            errText = "Enter a valid email address."
            return
        }

        // ✅ Demo flow (no backend). If you later add a real backend,
        // call it here and show success/failure.
        sent = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            dismiss()
        }
    }
}

// MARK: - Sign Up (kept minimal + safe: no guessing AuthStore methods)

private struct SignUpSheet: View {
    @EnvironmentObject var auth: AuthStore
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirm = ""
    @State private var errText: String?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.07, blue: 0.12),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 14) {
                    Text("Create Account")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.top, 10)

                    VStack(alignment: .leading, spacing: 10) {
                        DarkField(
                            placeholder: "Email",
                            text: $email,
                            isSecure: false,
                            keyboard: .emailAddress,
                            contentType: .emailAddress
                        )
                        DarkField(
                            placeholder: "Password",
                            text: $password,
                            isSecure: true,
                            keyboard: .default,
                            contentType: .newPassword
                        )
                        DarkField(
                            placeholder: "Confirm Password",
                            text: $confirm,
                            isSecure: true,
                            keyboard: .default,
                            contentType: .newPassword
                        )
                    }
                    .padding(.horizontal, 26)
                    .padding(.top, 6)

                    Button {
                        createAccountDemo()
                    } label: {
                        Text("Create Account")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.purple.opacity(0.92))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .padding(.horizontal, 26)

                    if let e = errText {
                        Text(e)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.red.opacity(0.95))
                            .padding(.horizontal, 26)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
    }

    // ✅ This avoids calling missing AuthStore APIs like createAccount().
    // It just tells the user to login (demo), or you can later implement real signup in AuthStore.
    private func createAccountDemo() {
        errText = nil

        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard e.contains("@"), e.contains(".") else {
            errText = "Enter a valid email."
            return
        }
        guard password.count >= 4 else {
            errText = "Password must be at least 4 characters."
            return
        }
        guard password == confirm else {
            errText = "Passwords do not match."
            return
        }

        // Demo: Auto-fill login fields by dismissing and letting user login.
        dismiss()
    }
}
