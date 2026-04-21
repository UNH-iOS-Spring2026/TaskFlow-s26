import SwiftUI

struct AuthView: View {
    @EnvironmentObject var auth: AuthStore

    @State private var isLoginMode = true

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    @State private var forgotEmail = ""
    @State private var showForgotPasswordSheet = false

    @State private var errorMessage = ""
    @State private var infoMessage = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
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

    private var forgotPasswordView: some View {
        NavigationStack {
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

    private func sendReset() {
        clearMessages()
        isLoading = true

        let cleanEmail = forgotEmail.trimmingCharacters(in: .whitespacesAndNewlines)

        auth.resetPassword(email: cleanEmail) { success, message in
            isLoading = false
            if success {
                infoMessage = "Password reset email sent."
            } else {
                errorMessage = message ?? "Could not send reset email."
            }
        }
    }

    private func clearMessages() {
        errorMessage = ""
        infoMessage = ""
    }
}
