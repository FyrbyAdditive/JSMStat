import Foundation

enum UserSettings {
    nonisolated(unsafe) private static let defaults = UserDefaults.standard

    // MARK: - Keys

    private enum Key: String {
        case refreshIntervalMinutes = "refreshIntervalMinutes"
        case opsCenterRotationSeconds = "opsCenterRotationSeconds"
        case notificationsEnabled = "notificationsEnabled"
        case notifyNewTickets = "notifyNewTickets"
        case notifyStatusChanges = "notifyStatusChanges"
        case notifyAssignments = "notifyAssignments"
        case pollIntervalMinutes = "pollIntervalMinutes"
        case enabledSections = "enabledSections"
        case maxRetries = "maxRetries"
    }

    // MARK: - Sections

    static var enabledSections: Set<String> {
        get {
            guard let data = defaults.data(forKey: Key.enabledSections.rawValue),
                  let set = try? JSONDecoder().decode(Set<String>.self, from: data) else {
                return Set(DashboardSection.allCases.map(\.rawValue))
            }
            return set
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            defaults.set(data, forKey: Key.enabledSections.rawValue)
        }
    }

    static func isSectionEnabled(_ section: DashboardSection) -> Bool {
        !section.isToggleable || enabledSections.contains(section.rawValue)
    }

    // MARK: - Display

    static var refreshIntervalMinutes: Double {
        get { defaults.object(forKey: Key.refreshIntervalMinutes.rawValue) as? Double ?? 5 }
        set { defaults.set(newValue, forKey: Key.refreshIntervalMinutes.rawValue) }
    }

    static var opsCenterRotationSeconds: Double {
        get { defaults.object(forKey: Key.opsCenterRotationSeconds.rawValue) as? Double ?? 30 }
        set { defaults.set(newValue, forKey: Key.opsCenterRotationSeconds.rawValue) }
    }

    // MARK: - Notifications

    static var notificationsEnabled: Bool {
        get { defaults.bool(forKey: Key.notificationsEnabled.rawValue) }
        set { defaults.set(newValue, forKey: Key.notificationsEnabled.rawValue) }
    }

    static var notifyNewTickets: Bool {
        get { defaults.object(forKey: Key.notifyNewTickets.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.notifyNewTickets.rawValue) }
    }

    static var notifyStatusChanges: Bool {
        get { defaults.object(forKey: Key.notifyStatusChanges.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.notifyStatusChanges.rawValue) }
    }

    static var notifyAssignments: Bool {
        get { defaults.object(forKey: Key.notifyAssignments.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.notifyAssignments.rawValue) }
    }

    static var pollIntervalMinutes: Double {
        get { defaults.object(forKey: Key.pollIntervalMinutes.rawValue) as? Double ?? 1 }
        set { defaults.set(newValue, forKey: Key.pollIntervalMinutes.rawValue) }
    }

    // MARK: - Reliability

    static var maxRetries: Int {
        get { defaults.object(forKey: Key.maxRetries.rawValue) as? Int ?? 3 }
        set { defaults.set(newValue, forKey: Key.maxRetries.rawValue) }
    }
}
