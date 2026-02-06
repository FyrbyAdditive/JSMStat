import Foundation

struct Status: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let statusCategory: StatusCategory?

    var categoryKey: String {
        statusCategory?.key ?? "undefined"
    }
}

struct StatusCategory: Codable, Identifiable, Hashable {
    let id: Int
    let key: String
    let name: String
    let colorName: String?
}

struct StatusSearchResponse: Codable {
    let values: [Status]?
    let total: Int?

    // Some endpoints return the array directly, others wrap in {values:[]}
    init(from decoder: Decoder) throws {
        // Try wrapped format first
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            values = try? container.decode([Status].self, forKey: .values)
            total = try? container.decode(Int.self, forKey: .total)
        } else {
            // Try as bare array
            let singleContainer = try decoder.singleValueContainer()
            values = try? singleContainer.decode([Status].self)
            total = nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case values, total
    }
}
