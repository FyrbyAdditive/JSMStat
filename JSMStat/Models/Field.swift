import Foundation

struct JIRAField: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let custom: Bool
    let navigable: Bool?
    let searchable: Bool?
    let orderable: Bool?
    let schema: FieldSchema?
    let clauseNames: [String]?
}

struct FieldSchema: Codable, Hashable {
    let type: String
    let custom: String?
    let customId: Int?
    let system: String?
}

// Generic paginated response for endpoints that wrap results in {values:[...]}
struct PaginatedResponse<T: Decodable>: Decodable {
    let values: [T]?
    let total: Int?
    let maxResults: Int?
    let startAt: Int?
}
