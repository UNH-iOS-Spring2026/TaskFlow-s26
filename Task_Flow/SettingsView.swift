//
//  SettingsView.swift
//  Task_Flow


import SwiftUI
import LocalAuthentication
import UserNotifications
import CoreLocation

struct SettingsView: View {
    @EnvironmentObject var auth: AuthStore

    @AppStorage("tf_dark_mode") private var darkMode = false
    @AppStorage("tf_biometric_enabled") private var biometricEnabled = false

    // MARK: - Managers

    // Handles Face ID or Touch ID availability and authentication.
    @StateObject private var biometricManager = BiometricAuthManager()

    // Shared service used to request location permission and current location.
    @ObservedObject private var locationService = LocationService.shared

    // MARK: - View State

    // Controls the account information sheet.
    @State private var showAccountInfo = false

    // Controls the logout confirmation alert.
    @State private var showLogoutConfirm = false

    // Controls the biometric alert.
    @State private var showBiometricAlert = false

    // Stores biometric alert text.
    @State private var biometricAlertMessage = ""

    // Stores biometric status text shown below the toggle.
    @State private var biometricStatusMessage = ""

    // Stores current notification permission status.
    @State private var notificationStatusMessage = "Checking notification permission..."

    // Stores notification testing messages.
    @State private var notificationTestMessage = ""

    // Stores current location permission status.
    @State private var locationStatusMessage = "Checking location permission..."

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                background

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header

                        settingsCard
                        notificationCard
                        locationCard
                        accountCard
                        logoutCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                biometricManager.refresh()
                refreshNotificationStatus()
                refreshLocationStatus()
            }
            .sheet(isPresented: $showAccountInfo) {
                AccountInfoSheet(email: auth.currentEmail ?? "—")
            }
            .alert("Biometric Login", isPresented: $showBiometricAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(biometricAlertMessage)
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

    // MARK: - Background

    // Main Settings screen background for light and dark mode.
    private var background: some View {
        LinearGradient(
            colors: darkMode
            ? [
                Color(red: 0.06, green: 0.07, blue: 0.12),
                Color(red: 0.10, green: 0.10, blue: 0.18),
                Color.black
            ]
            : [
                Color(red: 0.94, green: 0.96, blue: 1.00),
                Color.white,
                Color(red: 0.90, green: 0.93, blue: 0.98)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Header

    // Displays the Settings title and short screen description.
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Settings")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(primaryText)

            Text("Manage app preferences, account, notifications, and location access")
                .font(.subheadline)
                .foregroundStyle(secondaryText)
        }
        .padding(.top, 6)
    }

    // MARK: - Preferences Card

    // Contains dark mode and biometric login preferences.
    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Preferences")
                .font(.headline.weight(.bold))
                .foregroundStyle(primaryText)

            Toggle(isOn: $darkMode) {
                HStack(spacing: 10) {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(primaryText)

                    Text("Dark Mode")
                        .foregroundStyle(primaryText)
                }
            }
            .tint(Color.purple.opacity(0.9))

            Toggle(isOn: biometricToggleBinding) {
                HStack(spacing: 10) {
                    Image(systemName: biometricManager.kind.iconSystemName)
                        .foregroundStyle(primaryText)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(biometricManager.kind.title) Login")
                            .foregroundStyle(primaryText)

                        Text("Use biometrics to login from the login screen.")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    }
                }
            }
            .tint(Color.purple.opacity(0.9))

            if !biometricManager.isAvailable {
                Text(biometricManager.unavailableReason ?? "Biometrics not available on this device/simulator.")
                    .font(.caption)
                    .foregroundStyle(secondaryText)
            }

            if !biometricStatusMessage.isEmpty {
                Text(biometricStatusMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(biometricEnabled ? .green : secondaryText)
            }
        }
        .cardStyle(cardFill: cardFill, cardBorder: cardBorder)
    }

    // MARK: - Push Notifications Card

    // Allows the user to request notification permission and test local notifications.
    private var notificationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "bell.badge.fill")
                    .foregroundStyle(Color.purple)

                Text("Push Notifications")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(primaryText)
            }

            Text("Used for deadline-based reminders and reminder alerts.")
                .font(.caption)
                .foregroundStyle(secondaryText)

            Text(notificationStatusMessage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(notificationStatusColor)

            Button {
                requestNotificationPermission()
            } label: {
                Label("Request Notification Permission", systemImage: "bell")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.purple.opacity(0.9))

            Button {
                scheduleTestNotification()
            } label: {
                Label("Send Test Notification", systemImage: "paperplane.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.bordered)
            .tint(darkMode ? .white : .black)

            Button {
                clearAllNotifications()
            } label: {
                Label("Clear All Notifications", systemImage: "trash")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.bordered)
            .tint(.red)

            Button {
                printPendingNotifications()
            } label: {
                Label("Print Pending Notifications", systemImage: "list.bullet.clipboard")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.bordered)
            .tint(darkMode ? .white : .black)

            if !notificationTestMessage.isEmpty {
                Text(notificationTestMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(notificationMessageColor)
            }

            Text("For quick testing, tap Send Test Notification, press the simulator Home button immediately, and wait 5 seconds.")
                .font(.caption)
                .foregroundStyle(secondaryText)
        }
        .cardStyle(cardFill: cardFill, cardBorder: cardBorder)
    }

    // MARK: - Location Card

    // Allows the user to request location permission and check the current location.
    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "location.fill")
                    .foregroundStyle(Color.orange)

                Text("Location-Based Reminders")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(primaryText)
            }

            Text("Used to trigger reminders when entering or leaving selected locations.")
                .font(.caption)
                .foregroundStyle(secondaryText)

            Text(locationStatusMessage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(locationStatusColor)

            Button {
                requestLocationPermission()
            } label: {
                Label("Request Location Permission", systemImage: "location.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.orange.opacity(0.9))

            Button {
                locationService.requestCurrentLocation()
                refreshLocationStatus()
            } label: {
                Label("Get Current Location", systemImage: "scope")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.bordered)
            .tint(darkMode ? .white : .black)

            if let location = locationService.currentLocation {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Latitude: \(String(format: "%.6f", location.coordinate.latitude))")
                    Text("Longitude: \(String(format: "%.6f", location.coordinate.longitude))")
                }
                .font(.caption)
                .foregroundStyle(secondaryText)
            }

            if let error = locationService.lastError, !error.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .cardStyle(cardFill: cardFill, cardBorder: cardBorder)
    }

    // MARK: - Account Card

    // Shows the currently signed-in email and opens account details.
    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Account")
                .font(.headline.weight(.bold))
                .foregroundStyle(primaryText)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Signed in as")
                        .font(.caption)
                        .foregroundStyle(secondaryText)

                    Text(auth.currentEmail ?? "—")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(primaryText)
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
        .cardStyle(cardFill: cardFill, cardBorder: cardBorder)
    }

    // MARK: - Logout Card

    // Shows logout action and explains biometric login behavior.
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

            Text("After enabling biometric login, you can logout and use Face ID or Touch ID from the login screen.")
                .font(.caption)
                .foregroundStyle(secondaryText)
        }
        .cardStyle(cardFill: cardFill, cardBorder: cardBorder)
    }

    // MARK: - Theme Colors

    // Main text color based on the selected theme.
    private var primaryText: Color {
        darkMode ? .white.opacity(0.92) : .black.opacity(0.90)
    }

    // Secondary text color used for descriptions and helper messages.
    private var secondaryText: Color {
        darkMode ? .white.opacity(0.62) : .black.opacity(0.55)
    }

    // Card background color.
    private var cardFill: Color {
        darkMode ? Color.white.opacity(0.06) : Color.white.opacity(0.84)
    }

    // Card border color.
    private var cardBorder: Color {
        darkMode ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    // Color for notification permission status.
    private var notificationStatusColor: Color {
        if notificationStatusMessage.lowercased().contains("authorized") {
            return .green
        }

        if notificationStatusMessage.lowercased().contains("denied") {
            return .red
        }

        return secondaryText
    }

    // Color for notification test messages.
    private var notificationMessageColor: Color {
        let lower = notificationTestMessage.lowercased()

        if lower.contains("scheduled") || lower.contains("cleared") || lower.contains("printed") {
            return .green
        }

        if lower.contains("failed") || lower.contains("not enabled") {
            return .red
        }

        return secondaryText
    }

    // Color for location permission status.
    private var locationStatusColor: Color {
        if locationStatusMessage.lowercased().contains("always") ||
            locationStatusMessage.lowercased().contains("when in use") {
            return .green
        }

        if locationStatusMessage.lowercased().contains("denied") ||
            locationStatusMessage.lowercased().contains("restricted") {
            return .red
        }

        return secondaryText
    }

    // MARK: - Biometric Logic

    // Custom binding used to validate biometric access before turning on the toggle.
    private var biometricToggleBinding: Binding<Bool> {
        Binding(
            get: { biometricEnabled },
            set: { newValue in
                biometricStatusMessage = ""

                if newValue {
                    enableBiometricLogin()
                } else {
                    biometricEnabled = false
                    biometricStatusMessage = "Biometric login is turned off."
                }
            }
        )
    }

    // Enables biometric login after Face ID or Touch ID authentication succeeds.
    private func enableBiometricLogin() {
        biometricManager.refresh()

        guard biometricManager.isAvailable else {
            biometricEnabled = false
            biometricAlertMessage = biometricManager.unavailableReason ?? "Face ID or Touch ID is not available on this device."
            showBiometricAlert = true
            return
        }

        biometricManager.authenticate(reason: "Enable biometric login for Task Flow") { success, message in
            if success {
                biometricEnabled = true
                biometricStatusMessage = "Biometric login is turned on. Logout and use it from the login page."
            } else {
                biometricEnabled = false
                biometricAlertMessage = message ?? "Could not enable biometric login. Try again."
                showBiometricAlert = true
            }
        }
    }

    // MARK: - Notification Logic

    // Reads the current iOS notification permission status.
    private func refreshNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    notificationStatusMessage = "Authorized"

                case .provisional:
                    notificationStatusMessage = "Provisionally authorized"

                case .ephemeral:
                    notificationStatusMessage = "Temporarily authorized"

                case .denied:
                    notificationStatusMessage = "Denied. Enable notifications in iPhone Settings."

                case .notDetermined:
                    notificationStatusMessage = "Not requested yet"

                @unknown default:
                    notificationStatusMessage = "Unknown notification status"
                }
            }
        }
    }

    // Requests permission for local notifications.
    private func requestNotificationPermission() {
        NotificationManager.shared.requestAuthorization()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            refreshNotificationStatus()
            notificationTestMessage = "Notification permission requested."
        }
    }

    // Schedules a 5-second test notification through NotificationManager.
    private func scheduleTestNotification() {
        notificationTestMessage = ""

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let isAllowed =
                settings.authorizationStatus == .authorized ||
                settings.authorizationStatus == .provisional ||
                settings.authorizationStatus == .ephemeral

            DispatchQueue.main.async {
                if !isAllowed {
                    notificationTestMessage = "Notification permission is not enabled yet."
                    refreshNotificationStatus()
                    return
                }

                NotificationManager.shared.scheduleTestNotification()
                notificationTestMessage = "Test notification scheduled. Press Home and wait 5 seconds."

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    printPendingNotifications()
                }
            }
        }
    }

    // Clears all pending and delivered local notifications.
    private func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()

        notificationTestMessage = "All pending notifications cleared."

        print("ALL NOTIFICATIONS REMOVED FROM SETTINGS")
        printPendingNotifications()
    }

    // Prints pending notifications in the Xcode console for debugging.
    private func printPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("========== SETTINGS PENDING NOTIFICATIONS ==========")
            print("PENDING NOTIFICATIONS COUNT:", requests.count)

            for request in requests {
                print("PENDING ID:", request.identifier)
                print("TITLE:", request.content.title)
                print("BODY:", request.content.body)
                print("TRIGGER:", String(describing: request.trigger))
                print("------------------------------------------")
            }

            DispatchQueue.main.async {
                notificationTestMessage = "Pending notifications printed in Xcode console."
            }
        }
    }

    // MARK: - Location Logic

    // Reads the current Core Location permission status.
    private func refreshLocationStatus() {
        let status = locationService.authorizationStatus

        switch status {
        case .notDetermined:
            locationStatusMessage = "Not requested yet"

        case .restricted:
            locationStatusMessage = "Restricted"

        case .denied:
            locationStatusMessage = "Denied. Enable location in iPhone Settings."

        case .authorizedAlways:
            locationStatusMessage = "Authorized Always"

        case .authorizedWhenInUse:
            locationStatusMessage = "Authorized When In Use"

        @unknown default:
            locationStatusMessage = "Unknown location status"
        }
    }

    // Requests location permission through LocationService.
    private func requestLocationPermission() {
        locationService.requestPermission()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            refreshLocationStatus()
        }
    }
}

// MARK: - Account Info Sheet

// Sheet that displays the current user's account email.
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
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Card Modifier

// Shared card style used across the Settings screen.
private extension View {
    func cardStyle(cardFill: Color, cardBorder: Color) -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardFill)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(cardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
