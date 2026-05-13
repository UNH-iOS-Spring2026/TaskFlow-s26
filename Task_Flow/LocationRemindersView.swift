//
//  LocationRemindersView.swift
//  Task_Flow

import SwiftUI
import Combine
import CoreLocation

struct LocationRemindersView: View {
    @EnvironmentObject var store: AppStore
    @AppStorage("tf_dark_mode") private var darkMode = false

    // MARK: - Services

    // Shared location service used to request permission and read the current location.
    @ObservedObject private var locationService = LocationService.shared

    // MARK: - Form State

    // Stores the reminder title entered by the user.
    @State private var reminderTitle = ""

    // Stores the readable name for the selected location.
    @State private var locationName = ""

    // Backup time-based deadline for the reminder.
    @State private var dueAt = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

    // Stores the selected latitude and longitude before saving.
    @State private var selectedLatitude: Double?
    @State private var selectedLongitude: Double?

    // Radius used for the enter or leave location trigger.
    @State private var radiusMeters: Double = 150

    // Stores whether the reminder should trigger on arrival, leaving, or both.
    @State private var triggerType: LocationTriggerType = .arriving

    // MARK: - View State

    // Shows status updates such as permission, location, and save messages.
    @State private var statusMessage = ""

    // Controls validation alert display.
    @State private var showAlert = false

    // Stores alert text shown to the user.
    @State private var alertMessage = ""

    // MARK: - Filtered Location Reminders

    // Shows only reminders that have location reminder fields.
    private var locationReminders: [ReminderItem] {
        store.reminders
            .filter { $0.hasLocationReminder }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                background

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        permissionCard
                        createCard
                        savedLocationRemindersCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 110)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                NotificationManager.shared.requestAuthorization()
                locationService.requestPermission()
            }
            .onReceive(locationService.$currentLocation.compactMap { $0 }) { location in
                selectedLatitude = location.coordinate.latitude
                selectedLongitude = location.coordinate.longitude

                if locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    locationName = "Current Location"
                }

                statusMessage = "Current location added successfully."
            }
            .alert("Location Reminder", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - Header

    // Displays the screen title and short feature explanation.
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .foregroundStyle(Color.orange)

                Text("Location Reminders")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(primaryText)
            }

            Text("Attach a geographic location to a reminder and get notified when entering or leaving that area.")
                .font(.subheadline)
                .foregroundStyle(secondaryText)
        }
    }

    // MARK: - Permission Card

    // Lets the user request location and notification permissions.
    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Permissions")
                .font(.headline.weight(.bold))
                .foregroundStyle(primaryText)

            Text("This feature uses Core Location and UserNotifications.")
                .font(.caption)
                .foregroundStyle(secondaryText)

            HStack(spacing: 12) {
                Button {
                    locationService.requestPermission()
                    statusMessage = "Location permission requested."
                } label: {
                    Label("Location", systemImage: "location.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Button {
                    NotificationManager.shared.requestAuthorization()
                    statusMessage = "Notification permission requested."
                } label: {
                    Label("Notify", systemImage: "bell.badge.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }

            Text(locationPermissionText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(locationPermissionColor)
        }
        .cardStyle(cardFill: cardFill, cardBorder: cardBorder)
    }

    // MARK: - Create Reminder Card

    // Form used to create a new location-based reminder.
    private var createCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create Location Reminder")
                .font(.headline.weight(.bold))
                .foregroundStyle(primaryText)

            VStack(alignment: .leading, spacing: 8) {
                Text("Reminder Title")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primaryText)

                TextField("Example: Pick up groceries", text: $reminderTitle)
                    .textInputAutocapitalization(.sentences)
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .foregroundStyle(primaryText)
                    .background(fieldFill)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Location Name")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primaryText)

                TextField("Example: Home, Campus, Walmart", text: $locationName)
                    .textInputAutocapitalization(.words)
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .foregroundStyle(primaryText)
                    .background(fieldFill)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            VStack(spacing: 10) {
                Button {
                    useCurrentLocation()
                } label: {
                    Label("Use Current Location", systemImage: "scope")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Button {
                    useDemoLocation()
                } label: {
                    Label("Use Demo Location", systemImage: "mappin.and.ellipse")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }

            if let lat = selectedLatitude, let lon = selectedLongitude {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Selected Coordinates")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(primaryText)

                    Text("Latitude: \(String(format: "%.6f", lat))")
                    Text("Longitude: \(String(format: "%.6f", lon))")
                }
                .font(.caption)
                .foregroundStyle(secondaryText)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(rowFill)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Trigger Type")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primaryText)

                Picker("Trigger Type", selection: $triggerType) {
                    ForEach(LocationTriggerType.allCases) { type in
                        Text(type.title).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Radius: \(Int(radiusMeters)) meters")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primaryText)

                Slider(value: $radiusMeters, in: 50...1000, step: 50)
                    .tint(.orange)

                Text("The reminder triggers when the device enters or leaves this radius.")
                    .font(.caption)
                    .foregroundStyle(secondaryText)
            }

            DatePicker(
                "Backup Deadline",
                selection: $dueAt,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .foregroundStyle(primaryText)

            Text("Backup deadline is used for the normal time-based reminder. The location trigger works separately using Core Location.")
                .font(.caption)
                .foregroundStyle(secondaryText)

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusMessageColor)
            }

            Button {
                saveLocationReminder()
            } label: {
                Label("Save Location Reminder", systemImage: "location.fill")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(.white)
                    .background(canSave ? Color.purple : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(!canSave)
        }
        .cardStyle(cardFill: cardFill, cardBorder: cardBorder)
    }

    // MARK: - Saved Reminders Card

    // Displays all saved reminders that include location data.
    private var savedLocationRemindersCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Saved Location Reminders")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(primaryText)

                Spacer()

                Text("\(locationReminders.count)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(primaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(buttonFill)
                    .clipShape(Capsule())
            }

            if locationReminders.isEmpty {
                Text("No location reminders yet. Create one using current location or demo location.")
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
            } else {
                VStack(spacing: 12) {
                    ForEach(locationReminders) { reminder in
                        locationReminderRow(reminder)
                    }
                }
            }
        }
        .cardStyle(cardFill: cardFill, cardBorder: cardBorder)
    }

    // MARK: - Location Reminder Row

    // Displays one saved location reminder with trigger, radius, coordinates, and delete action.
    private func locationReminderRow(_ reminder: ReminderItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(primaryText)

                    Text(reminder.locationName ?? "Selected Location")
                        .font(.subheadline)
                        .foregroundStyle(secondaryText)
                }

                Spacer()

                Button(role: .destructive) {
                    store.deleteReminder(reminder)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                        .padding(8)
                        .background(buttonFill)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Label(triggerText(for: reminder), systemImage: "arrow.triangle.turn.up.right.circle.fill")

                Spacer()

                Text("\(Int(reminder.radiusMeters))m radius")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.orange)

            if let lat = reminder.latitude, let lon = reminder.longitude {
                Text("Coordinates: \(String(format: "%.5f", lat)), \(String(format: "%.5f", lon))")
                    .font(.caption)
                    .foregroundStyle(secondaryText)
            }

            Text("Backup deadline: \(reminder.dueAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(secondaryText)
        }
        .padding(14)
        .background(rowFill)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Validation

    // Save button becomes active only after a title and coordinates are available.
    private var canSave: Bool {
        let cleanTitle = reminderTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return !cleanTitle.isEmpty && selectedLatitude != nil && selectedLongitude != nil
    }

    // MARK: - Location Actions

    // Requests the current location from Core Location.
    private func useCurrentLocation() {
        statusMessage = "Getting current location..."
        locationService.requestPermission()
        locationService.requestCurrentLocation()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if selectedLatitude == nil || selectedLongitude == nil {
                statusMessage = "Location not found yet. Use Demo Location for simulator demo."
            }
        }
    }

    // Adds fixed demo coordinates for reliable simulator demonstration.
    private func useDemoLocation() {
        selectedLatitude = 41.3083
        selectedLongitude = -72.9279

        if locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            locationName = "University / Demo Location"
        }

        statusMessage = "Demo location added successfully."
    }

    // MARK: - Save Reminder

    // Saves the location reminder through AppStore.
    private func saveLocationReminder() {
        let cleanTitle = reminderTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanLocationName = locationName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanTitle.isEmpty else {
            alertMessage = "Enter a reminder title."
            showAlert = true
            return
        }

        guard let lat = selectedLatitude, let lon = selectedLongitude else {
            alertMessage = "Tap Use Current Location or Use Demo Location before saving."
            showAlert = true
            return
        }

        store.addReminder(
            title: cleanTitle,
            dueAt: dueAt,
            locationName: cleanLocationName.isEmpty ? "Demo Location" : cleanLocationName,
            latitude: lat,
            longitude: lon,
            radiusMeters: radiusMeters,
            notifyOnEntry: triggerType.notifyOnEntry,
            notifyOnExit: triggerType.notifyOnExit
        ) { success in
            if success {
                reminderTitle = ""
                locationName = ""
                selectedLatitude = nil
                selectedLongitude = nil
                radiusMeters = 150
                triggerType = .arriving
                dueAt = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                statusMessage = "Location reminder saved successfully."
            } else {
                statusMessage = "Could not save location reminder."
            }
        }
    }

    // MARK: - Trigger Text

    // Converts reminder trigger flags into readable text.
    private func triggerText(for reminder: ReminderItem) -> String {
        if reminder.notifyOnEntry && reminder.notifyOnExit {
            return "Arriving or leaving"
        }

        if reminder.notifyOnExit {
            return "When leaving"
        }

        return "When arriving"
    }

    // MARK: - Permission Status

    // Shows the current Core Location permission status.
    private var locationPermissionText: String {
        switch locationService.authorizationStatus {
        case .notDetermined:
            return "Location permission not requested yet."

        case .restricted:
            return "Location permission is restricted."

        case .denied:
            return "Location permission denied. Enable it in iPhone Settings."

        case .authorizedAlways:
            return "Location permission: Always"

        case .authorizedWhenInUse:
            return "Location permission: When In Use"

        @unknown default:
            return "Unknown location permission."
        }
    }

    // Color used for the location permission status text.
    private var locationPermissionColor: Color {
        switch locationService.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return .green

        case .denied, .restricted:
            return .red

        default:
            return secondaryText
        }
    }

    // Color used for success, warning, and neutral status messages.
    private var statusMessageColor: Color {
        let lower = statusMessage.lowercased()

        if lower.contains("success") || lower.contains("saved") {
            return .green
        }

        if lower.contains("not found") || lower.contains("could not") {
            return .orange
        }

        return secondaryText
    }

    // MARK: - Theme

    // Main background for light and dark mode.
    private var background: some View {
        LinearGradient(
            colors: darkMode
            ? [
                Color.black,
                Color(red: 8/255, green: 12/255, blue: 42/255),
                Color.black
            ]
            : [
                Color(red: 0.96, green: 0.97, blue: 1.00),
                Color.white,
                Color(red: 0.91, green: 0.94, blue: 1.00)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // Primary text color based on the selected theme.
    private var primaryText: Color {
        darkMode ? .white.opacity(0.94) : .black.opacity(0.90)
    }

    // Secondary text color used for helper text.
    private var secondaryText: Color {
        darkMode ? .white.opacity(0.64) : .black.opacity(0.58)
    }

    // Card background color.
    private var cardFill: Color {
        darkMode ? Color.white.opacity(0.07) : Color.white.opacity(0.88)
    }

    // Row background color.
    private var rowFill: Color {
        darkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.04)
    }

    // Text field background color.
    private var fieldFill: Color {
        darkMode ? Color.white.opacity(0.10) : Color.white
    }

    // Small button background color.
    private var buttonFill: Color {
        darkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.06)
    }

    // Card border color.
    private var cardBorder: Color {
        darkMode ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }
}

// MARK: - Location Trigger Type

// Defines when a location reminder should fire.
enum LocationTriggerType: String, CaseIterable, Identifiable {
    case arriving
    case leaving
    case both

    var id: String {
        rawValue
    }

    // Text shown in the trigger type picker.
    var title: String {
        switch self {
        case .arriving:
            return "Arrive"
        case .leaving:
            return "Leave"
        case .both:
            return "Both"
        }
    }

    // Controls whether the notification fires on location entry.
    var notifyOnEntry: Bool {
        switch self {
        case .arriving, .both:
            return true
        case .leaving:
            return false
        }
    }

    // Controls whether the notification fires on location exit.
    var notifyOnExit: Bool {
        switch self {
        case .leaving, .both:
            return true
        case .arriving:
            return false
        }
    }
}

// MARK: - Card Style Modifier

// Shared card style used by this screen.
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
