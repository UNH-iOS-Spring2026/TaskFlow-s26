//
//  NotificationManager.swift
//  Task_Flow

import Foundation
import UserNotifications
import CoreLocation

// Manages local notifications for test alerts, deadline reminders, and location reminders.
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private override init() {
        super.init()
    }

    // MARK: - Setup

    // Configures the notification center and asks the user for notification permission.
    func configure() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        requestAuthorization()
    }

    // Requests permission to show alerts, play sounds, and update badges.
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error {
                print("NOTIFICATION AUTH ERROR:", error.localizedDescription)
            }

            print("NOTIFICATION PERMISSION GRANTED:", granted)
        }
    }

    // MARK: - Test Notification

    // Schedules a simple test notification after 5 seconds.
    func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Task Flow Test"
        content.body = "Notifications are working."
        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 5,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "taskflow-test-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("TEST NOTIFICATION ERROR:", error.localizedDescription)
            } else {
                print("TEST NOTIFICATION SCHEDULED FOR 5 SECONDS")
            }
        }

        printPendingNotifications()
    }

    // MARK: - Reminder Notifications

    // Schedules both deadline and location notifications for a reminder.
    func scheduleNotifications(for reminder: ReminderItem) {
        removeNotifications(for: reminder)

        guard reminder.isDone == false else {
            print("NOTIFICATION SKIPPED: reminder is completed")
            return
        }

        scheduleDeadlineNotification(for: reminder)

        if reminder.hasLocationReminder {
            scheduleLocationNotification(for: reminder)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.printPendingNotifications()
        }
    }

    // Removes pending and delivered notifications connected to one reminder.
    func removeNotifications(for reminder: ReminderItem) {
        let ids = [
            reminder.deadlineNotificationId,
            reminder.locationNotificationId
        ]

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)

        print("REMOVED NOTIFICATIONS:", ids)
    }

    // Schedules the normal time-based reminder notification.
    private func scheduleDeadlineNotification(for reminder: ReminderItem) {
        let secondsUntilDue = reminder.dueAt.timeIntervalSinceNow

        print("========== DEADLINE NOTIFICATION DEBUG ==========")
        print("REMINDER TITLE:", reminder.title)
        print("REMINDER DUE DATE:", reminder.dueAt)
        print("CURRENT DATE:", Date())
        print("SECONDS UNTIL DUE:", secondsUntilDue)

        let fireAfter: TimeInterval

        if secondsUntilDue > 10 {
            fireAfter = secondsUntilDue
        } else if secondsUntilDue > -60 {
            // If the selected reminder time is very close, schedule a short demo notification.
            fireAfter = 15
            print("DEADLINE TIME TOO CLOSE - SCHEDULING DEMO NOTIFICATION IN 15 SECONDS")
        } else {
            print("DEADLINE NOTIFICATION SKIPPED: reminder time is already too old")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Task Flow Reminder"
        content.body = reminder.title
        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: fireAfter,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: reminder.deadlineNotificationId,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("DEADLINE NOTIFICATION ERROR:", error.localizedDescription)
            } else {
                print("DEADLINE NOTIFICATION SCHEDULED:", reminder.deadlineNotificationId)
                print("WILL FIRE IN:", fireAfter, "seconds")
            }
        }
    }

    // Schedules the location-based notification using a circular region.
    private func scheduleLocationNotification(for reminder: ReminderItem) {
        guard let latitude = reminder.latitude,
              let longitude = reminder.longitude
        else {
            print("LOCATION NOTIFICATION SKIPPED: missing coordinates")
            return
        }

        print("========== LOCATION NOTIFICATION DEBUG ==========")
        print("REMINDER TITLE:", reminder.title)
        print("LATITUDE:", latitude)
        print("LONGITUDE:", longitude)
        print("RADIUS:", reminder.radiusMeters)
        print("ENTRY:", reminder.notifyOnEntry)
        print("EXIT:", reminder.notifyOnExit)

        let center = CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )

        let region = CLCircularRegion(
            center: center,
            radius: max(50, reminder.radiusMeters),
            identifier: reminder.locationNotificationId
        )

        region.notifyOnEntry = reminder.notifyOnEntry
        region.notifyOnExit = reminder.notifyOnExit

        let content = UNMutableNotificationContent()
        content.title = "Location Reminder"

        if let locationName = reminder.locationName, !locationName.isEmpty {
            content.body = "\(reminder.title) near \(locationName)"
        } else {
            content.body = reminder.title
        }

        content.sound = .default
        content.badge = 1

        let trigger = UNLocationNotificationTrigger(
            region: region,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: reminder.locationNotificationId,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("LOCATION NOTIFICATION ERROR:", error.localizedDescription)
            } else {
                print("LOCATION NOTIFICATION SCHEDULED:", reminder.locationNotificationId)
            }
        }
    }

    // MARK: - Debug

    // Prints all pending notifications in the Xcode console.
    func printPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("========== PENDING NOTIFICATIONS ==========")
            print("PENDING NOTIFICATIONS COUNT:", requests.count)

            for request in requests {
                print("PENDING NOTIFICATION ID:", request.identifier)
                print("TITLE:", request.content.title)
                print("BODY:", request.content.body)
                print("TRIGGER:", String(describing: request.trigger))
                print("------------------------------------------")
            }
        }
    }

    // Removes every pending and delivered notification created by the app.
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        print("ALL NOTIFICATIONS REMOVED")
    }

    // MARK: - Foreground Notification Display

    // Shows notification banners even when the app is open.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("NOTIFICATION WILL PRESENT:", notification.request.content.title)
        completionHandler([.banner, .sound, .badge])
    }

    // Runs when the user taps a delivered notification.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("NOTIFICATION TAPPED:", response.notification.request.content.title)
        completionHandler()
    }
}
