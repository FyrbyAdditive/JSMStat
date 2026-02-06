import Foundation

struct IssueType: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String?
    let subtask: Bool?
    let iconUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, subtask, iconUrl
    }
}
