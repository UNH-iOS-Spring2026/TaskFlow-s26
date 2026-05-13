//
//  Task_FlowApp.swift
//  Task_Flow
//
//  Created by Aravind Ganipisetty
//

import SwiftUI
import FirebaseCore
import UserNotifications
import UIKit

// MARK: - App Delegate

// Handles app startup setup for Firebase and notifications.
final class AppDelegate: NSObject, UIApplicationDelegate {

    // Runs when the app finishes launching.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure Firebase once before using Firebase Authentication or Firestore.
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("FIREBASE CONFIGURED FROM APPDELEGATE")
        }

        // Configure local notifications when the app launches.
        NotificationManager.shared.configure()
        print("NOTIFICATION MANAGER CONFIGURED FROM APPDELEGATE")

        return true
    }

    // Reconfigures notifications when the app comes back to the foreground.
    func applicationWillEnterForeground(_ application: UIApplication) {
        NotificationManager.shared.configure()
        print("NOTIFICATION MANAGER CONFIGURED WHEN APP ENTERS FOREGROUND")
    }
}

// MARK: - Main App Entry Point

// Main entry point for the Task Flow app.
@main
struct Task_FlowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    // Tracks whether the app is active, inactive, or in the background.
    @Environment(\.scenePhase) private var scenePhase

    // Stores authentication state for the whole app.
    @StateObject private var authStore: AuthStore

    // Stores app data and connects Firestore data with the UI.
    @StateObject private var appStore: AppStore

    // MARK: - Initialization

    init() {
        // Configure Firebase during app initialization if it has not already been configured.
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("FIREBASE CONFIGURED FROM APP INIT")
        }

        let auth = AuthStore()

        // AuthStore must be created first because AppStore depends on the current user.
        _authStore = StateObject(wrappedValue: auth)
        _appStore = StateObject(wrappedValue: AppStore(auth: auth))

        // Configure notifications during initialization.
        NotificationManager.shared.configure()
        print("NOTIFICATION MANAGER CONFIGURED FROM APP INIT")
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authStore)
                .environmentObject(appStore)
                .onAppear {
                    // Recheck notification setup and print pending notifications for debugging.
                    NotificationManager.shared.configure()
                    NotificationManager.shared.printPendingNotifications()
                    print("ROOTVIEW APPEARED - NOTIFICATION CHECK DONE")
                }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // Reconfigure notifications whenever the app becomes active again.
                NotificationManager.shared.configure()
                NotificationManager.shared.printPendingNotifications()
                print("APP ACTIVE - NOTIFICATION MANAGER RECONFIGURED")
            }
        }
    }
}
