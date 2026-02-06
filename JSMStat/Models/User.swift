import Foundation

struct JIRAUser: Codable, Identifiable, Hashable {
    let accountId: String
    let displayName: String?
    let emailAddress: String?
    let active: Bool?
    let avatarUrls: AvatarURLs?

    var id: String { accountId }

    var name: String {
        displayName ?? emailAddress ?? accountId
    }

    static func == (lhs: JIRAUser, rhs: JIRAUser) -> Bool {
        lhs.accountId == rhs.accountId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(accountId)
    }
}

struct AvatarURLs: Codable, Hashable {
    let _48x48: String?
    let _24x24: String?
    let _16x16: String?
    let _32x32: String?

    enum CodingKeys: String, CodingKey {
        case _48x48 = "48x48"
        case _24x24 = "24x24"
        case _16x16 = "16x16"
        case _32x32 = "32x32"
    }
}
