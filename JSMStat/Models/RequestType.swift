import Foundation

struct RequestType: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String?
    let serviceDeskId: String?
    let issueTypeId: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, serviceDeskId, issueTypeId
    }
}

struct RequestTypeListResponse: Codable {
    let size: Int?
    let start: Int?
    let limit: Int?
    let isLastPage: Bool?
    let values: [RequestType]
}
