import Foundation

struct Issue: Codable, Identifiable, Hashable {
    let id: String
    let key: String
    let fields: IssueFields

    static func == (lhs: Issue, rhs: Issue) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct IssueFields: Codable {
    let summary: String?
    let status: Status?
    let priority: Priority?
    let assignee: JIRAUser?
    let reporter: JIRAUser?
    let issuetype: IssueType?
    let created: String?
    let updated: String?
    let resolutiondate: String?
    let resolution: Resolution?

    var createdDate: Date? {
        created.flatMap { DateFormatting.parseISO8601($0) }
    }

    var updatedDate: Date? {
        updated.flatMap { DateFormatting.parseISO8601($0) }
    }

    var resolvedDate: Date? {
        resolutiondate.flatMap { DateFormatting.parseISO8601($0) }
    }

    var resolutionTimeHours: Double? {
        guard let created = createdDate, let resolved = resolvedDate else { return nil }
        return resolved.timeIntervalSince(created) / 3600.0
    }
}

struct Resolution: Codable, Hashable {
    let id: String?
    let name: String?
    let description: String?
}

struct SearchResult: Codable {
    let issues: [Issue]
    let nextPageToken: String?

    // Legacy fields (old /search endpoint) — kept for test compatibility
    let startAt: Int?
    let maxResults: Int?
    let total: Int?
}

struct SearchRequestBody: Encodable {
    let jql: String
    let maxResults: Int
    let fields: [String]
    let nextPageToken: String?

    init(jql: String, maxResults: Int, fields: [String], nextPageToken: String? = nil) {
        self.jql = jql
        self.maxResults = maxResults
        self.fields = fields
        self.nextPageToken = nextPageToken
    }
}
