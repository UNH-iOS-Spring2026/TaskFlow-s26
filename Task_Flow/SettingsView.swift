//
//  LocalAuthGate.swift
//  Task_Flow
//
//  Created by Aravind Ganipisetty on 3/26/26.
//

import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    @EnvironmentObject var auth: AuthStore

    @AppStorage("tf_dark_mode") private var darkMode = false
    @AppStorage("tf_biometric_enabled") private var biometricEnabled = true

    @State private var showAccountInfo = false
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                background

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header

                        settingsCard
                        accountCard
                        logoutCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAccountInfo) {
                AccountInfoSheet(email: auth.currentEmail ?? "—")
            }
            .alert("Logout", isPresented: $showLogoutConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Logout", role: .destructive) {
                    auth.logout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }

    private var background: some View {
        Group {
            if darkMode {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.07, blue: 0.12),
                        Color(red: 0.10, green: 0.10, blue: 0.18),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.94, green: 0.96, blue: 1.00),
                        Color.white,
                        Color(red: 0.90, green: 0.93, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Settings")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(darkMode ? AnyShapeStyle(.white) : AnyShapeStyle(.black))

            Text("Manage app preferences and account")
                .font(.subheadline)
                .foregroundStyle(darkMode ? AnyShapeStyle(.white.opacity(0.7)) : AnyShapeStyle(.black.opacity(0.6)))
        }
        .padding(.top, 6)
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Preferences")
                .font(.headline.weight(.bold))
                .foregroundStyle(primaryTextStyle)

            Toggle(isOn: $darkMode) {
                HStack(spacing: 10) {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(primaryTextStyle)
                    Text("Dark Mode")
                        .foregroundStyle(primaryTextStyle)
                }
            }
            .tint(Color.purple.opacity(0.9))

            Toggle(isOn: biometricToggleBinding) {
                HStack(spacing: 10) {
                    Image(systemName: "faceid")
                        .foregroundStyle(primaryTextStyle)
                    Text("Biometric Login")
                        .foregroundStyle(primaryTextStyle)
                }
            }
            .tint(Color.purple.opacity(0.9))

            if !deviceSupportsBiometrics {
                Text("Biometrics not available on this device/simulator.")
                    .font(.caption)
                    .foregroundStyle(secondaryTextStyle)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFill)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(cardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Account")
                .font(.headline.weight(.bold))
                .foregroundStyle(primaryTextStyle)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Signed in as")
                        .font(.caption)
                        .foregroundStyle(secondaryTextStyle)

                    Text(auth.currentEmail ?? "—")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(primaryTextStyle)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                Button {
                    showAccountInfo = true
                } label: {
                    Label("Account Info", systemImage: "info.circle")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(darkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.06))
                .foregroundStyle(darkMode ? .white : .black)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFill)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(cardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var logoutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                showLogoutConfirm = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Logout")
                        .font(.headline.weight(.semibold))
                    Spacer()
                }
                .foregroundStyle(.red.opacity(0.95))
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            Text("Logging out will return you to the login screen.")
                .font(.caption)
                .foregroundStyle(secondaryTextStyle)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFill)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(cardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var primaryTextStyle: AnyShapeStyle {
        darkMode ? AnyShapeStyle(.white.opacity(0.92)) : AnyShapeStyle(.black.opacity(0.90))
    }

    private var secondaryTextStyle: AnyShapeStyle {
        darkMode ? AnyShapeStyle(.white.opacity(0.60)) : AnyShapeStyle(.black.opacity(0.55))
    }

    private var cardFill: Color {
        darkMode ? Color.white.opacity(0.06) : Color.white.opacity(0.82)
    }

    private var cardBorder: Color {
        darkMode ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    private var deviceSupportsBiometrics: Bool {
        let ctx = LAContext()
        var err: NSError?
        return ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
    }

    private var biometricToggleBinding: Binding<Bool> {
        Binding(
            get: { biometricEnabled },
            set: { newValue in
                if newValue && !deviceSupportsBiometrics {
                    biometricEnabled = false
                } else {
                    biometricEnabled = newValue
                }
            }
        )
    }
}

private struct AccountInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    let email: String

    var body: some View {
        NavigationStack {
            Form {
                Section("Account Info") {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(email)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
            .navigationTitle("Account Info")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
