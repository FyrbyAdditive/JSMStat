import Foundation

enum JIRAEndpoints {
    // MARK: - URL Helper

    private static func url(_ baseURL: URL, path: String) throws -> URL {
        guard let url = URL(string: baseURL.absoluteString + path) else {
            throw APIError.invalidURL(baseURL.absoluteString + path)
        }
        return url
    }

    // MARK: - Service Desk API

    static func serviceDesks(baseURL: URL) throws -> URL {
        try url(baseURL, path: "/rest/servicedeskapi/servicedesk")
    }

    static func serviceDesk(baseURL: URL, id: String) throws -> URL {
        try url(baseURL, path: "/rest/servicedeskapi/servicedesk/\(id)")
    }

    static func requestTypes(baseURL: URL, serviceDeskId: String) throws -> URL {
        try url(baseURL, path: "/rest/servicedeskapi/servicedesk/\(serviceDeskId)/requesttype")
    }

    static func sla(baseURL: URL, issueKey: String) throws -> URL {
        try url(baseURL, path: "/rest/servicedeskapi/request/\(issueKey)/sla")
    }

    // MARK: - Jira Platform API v3

    static func searchJQL(baseURL: URL) throws -> URL {
        try url(baseURL, path: "/rest/api/3/search/jql")
    }

    static func statuses(baseURL: URL) throws -> URL {
        try url(baseURL, path: "/rest/api/3/statuses/search")
    }

    static func statusCategories(baseURL: URL) throws -> URL {
        try url(baseURL, path: "/rest/api/3/statuscategory")
    }

    static func issueTypes(baseURL: URL) throws -> URL {
        try url(baseURL, path: "/rest/api/3/issuetype")
    }

    static func priorities(baseURL: URL) throws -> URL {
        try url(baseURL, path: "/rest/api/3/priority")
    }

    static func fields(baseURL: URL) throws -> URL {
        try url(baseURL, path: "/rest/api/3/field")
    }

    static func assignableUsers(baseURL: URL, projectKey: String) throws -> URL {
        guard var components = URLComponents(string: baseURL.absoluteString + "/rest/api/3/user/assignable/search") else {
            throw APIError.invalidURL(baseURL.absoluteString + "/rest/api/3/user/assignable/search")
        }
        components.queryItems = [
            URLQueryItem(name: "project", value: projectKey),
            URLQueryItem(name: "maxResults", value: "1000")
        ]
        guard let url = components.url else {
            throw APIError.invalidURL("Failed to construct assignableUsers URL")
        }
        return url
    }

    // MARK: - JQL Search Helpers

    static func searchURL(baseURL: URL, jql: String, startAt: Int = 0, maxResults: Int = 100, fields: [String]? = nil) throws -> URL {
        guard var components = URLComponents(string: baseURL.absoluteString + "/rest/api/3/search") else {
            throw APIError.invalidURL(baseURL.absoluteString + "/rest/api/3/search")
        }
        var queryItems = [
            URLQueryItem(name: "jql", value: jql),
            URLQueryItem(name: "startAt", value: String(startAt)),
            URLQueryItem(name: "maxResults", value: String(maxResults))
        ]
        if let fields = fields {
            queryItems.append(URLQueryItem(name: "fields", value: fields.joined(separator: ",")))
        }
        components.queryItems = queryItems
        guard let url = components.url else {
            throw APIError.invalidURL("Failed to construct search URL")
        }
        return url
    }
}
