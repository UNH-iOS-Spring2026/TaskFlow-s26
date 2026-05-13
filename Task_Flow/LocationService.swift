//
//  LocationService.swift
//  Task_Flow
//
//  Created by Aravind Ganipisetty
//

import Foundation
import Combine
import CoreLocation

// Manages Core Location permission and current location updates for Task Flow.
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    // MARK: - Published Location State

    // Stores the current location permission status.
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    // Stores the latest location returned by Core Location.
    @Published var currentLocation: CLLocation?

    // Stores the latest location error message.
    @Published var lastError: String?

    // MARK: - Location Manager

    // CLLocationManager is responsible for requesting permission and reading device location.
    private let manager = CLLocationManager()

    // MARK: - Initialization

    private override init() {
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    // MARK: - Permission Request

    // Requests location permission from the user.
    // Always permission is requested because location reminders may need to work in the background.
    func requestPermission() {
        let status = manager.authorizationStatus
        authorizationStatus = status

        switch status {
        case .notDetermined:
            manager.requestAlwaysAuthorization()

        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
            manager.requestLocation()

        case .authorizedAlways:
            manager.requestLocation()

        case .denied, .restricted:
            lastError = "Location permission is disabled. Enable it in Settings."

        @unknown default:
            lastError = "Unknown location permission status."
        }
    }

    // MARK: - Current Location

    // Requests the user's current location once permission is available.
    func requestCurrentLocation() {
        let status = manager.authorizationStatus
        authorizationStatus = status

        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()

        case .notDetermined:
            manager.requestAlwaysAuthorization()

        case .denied, .restricted:
            lastError = "Location permission is disabled. Enable it in Settings."

        @unknown default:
            lastError = "Unknown location permission status."
        }
    }

    // MARK: - CLLocationManagerDelegate

    // Runs when the user changes location permission.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }

    // Runs when Core Location successfully returns a location.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        lastError = nil
    }

    // Runs when Core Location fails to return a location.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastError = error.localizedDescription
    }
}
