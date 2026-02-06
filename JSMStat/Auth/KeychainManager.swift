import Foundation
import Security

enum KeychainManager {
    private static let service = "com.jsmstat.app"

    enum Key: String {
        case siteURL = "jsmstat-site-url"
        case email = "jsmstat-email"
        case apiToken = "jsmstat-api-token"
    }

    static func save(_ value: String, for key: Key) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }

        // Delete any existing item first
        delete(key)

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    static func load(_ key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    static func delete(_ key: Key) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func saveConfig(_ config: ConnectionConfig) throws {
        try save(config.siteURL, for: .siteURL)
        try save(config.email, for: .email)
        try save(config.apiToken, for: .apiToken)
    }

    static func loadConfig() -> ConnectionConfig? {
        guard let siteURL = load(.siteURL),
              let email = load(.email),
              let apiToken = load(.apiToken) else {
            return nil
        }
        return ConnectionConfig(siteURL: siteURL, email: email, apiToken: apiToken)
    }

    static func deleteConfig() {
        delete(.siteURL)
        delete(.email)
        delete(.apiToken)
    }
}

enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to Keychain (status: \(status))"
        case .encodingFailed:
            return "Failed to encode value as UTF-8"
        }
    }
}
