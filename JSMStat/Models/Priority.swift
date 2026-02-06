import Foundation

struct Priority: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let iconUrl: String?
    let statusColor: String?
}
