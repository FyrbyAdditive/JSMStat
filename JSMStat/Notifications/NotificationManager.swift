import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    nonisolated(unsafe) static let shared = NotificationManager()

    /// Tracks whether the OS has granted notification permission (not the user's preference toggle).
    var isAuthorized = false

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            return false
        }
    }

    func postNotification(for event: ChangeEvent) {
        guard isAuthorized, UserSettings.notificationsEnabled else { return }

        let content = UNMutableNotificationContent()

        switch event.kind {
        case .newTicket:
            content.title = "New Ticket: \(event.issueKey)"
            content.body = event.summary
        case .statusChanged:
            content.title = "Status Changed: \(event.issueKey)"
            content.body = "\(event.summary)\n\(event.detail)"
        case .assigned:
            content.title = "Assigned: \(event.issueKey)"
            content.body = event.summary
        }

        content.sound = .default
        content.categoryIdentifier = "TICKET_UPDATE"

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func setupCategories() {
        let openAction = UNNotificationAction(identifier: "OPEN_IN_JIRA", title: "Open in JIRA", options: [.foreground])
        let category = UNNotificationCategory(
            identifier: "TICKET_UPDATE",
            actions: [openAction],
            intentIdentifiers: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
