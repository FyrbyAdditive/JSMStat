import Foundation

struct ServiceDesk: Codable, Identifiable, Hashable {
    let id: String
    let projectId: String
    let projectName: String
    let projectKey: String

    /// Validated project key safe for JQL interpolation.
    /// JIRA project keys: uppercase letters optionally followed by digits/hyphens.
    var sanitizedProjectKey: String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        let isSafe = projectKey.unicodeScalars.allSatisfy { allowed.contains($0) }
        guard isSafe, !projectKey.isEmpty, projectKey.count <= 20 else {
            return "INVALID"
        }
        return projectKey
    }
}

struct ServiceDeskListResponse: Codable {
    let size: Int?
    let start: Int?
    let limit: Int?
    let isLastPage: Bool?
    let values: [ServiceDesk]
}
