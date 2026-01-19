import Foundation
import UserNotifications

struct InsertDeviceTokenRequest: Codable {
    let professionalId: String
    let deviceToken: String
    let platform: String

    enum CodingKeys: String, CodingKey {
        case professionalId = "professional_id"
        case deviceToken = "device_token"
        case platform
    }
}

class NotificationService {
    static let shared = NotificationService()

    private init() {}

    // MARK: - Device Token Registration

    func registerDeviceToken(_ token: String) async {
        guard let userId = await Database.shared.currentUserId else { return }

        do {
            // Check if token already exists
            let existingTokens: [DeviceToken] = try await Database.shared
                .from(Database.Table.deviceTokens)
                .select()
                .eq("professional_id", value: userId)
                .eq("device_token", value: token)
                .execute()
                .value

            if existingTokens.isEmpty {
                let request = InsertDeviceTokenRequest(
                    professionalId: userId.uuidString,
                    deviceToken: token,
                    platform: "ios"
                )
                try await Database.shared
                    .from(Database.Table.deviceTokens)
                    .insert(request)
                    .execute()
            }
        } catch {
            print("Failed to register device token: \(error)")
        }
    }

    func unregisterDeviceToken(_ token: String) async {
        guard let userId = await Database.shared.currentUserId else { return }

        do {
            try await Database.shared
                .from(Database.Table.deviceTokens)
                .delete()
                .eq("professional_id", value: userId)
                .eq("device_token", value: token)
                .execute()
        } catch {
            print("Failed to unregister device token: \(error)")
        }
    }

    // MARK: - Local Notifications

    func scheduleLocalNotification(
        title: String,
        body: String,
        identifier: String,
        delay: TimeInterval = 0
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(delay, 1),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// MARK: - Device Token Model

struct DeviceToken: Codable {
    let id: UUID
    let professionalId: UUID
    let deviceToken: String
    let platform: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case professionalId = "professional_id"
        case deviceToken = "device_token"
        case platform
        case createdAt = "created_at"
    }
}
