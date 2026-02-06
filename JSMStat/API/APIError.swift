import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case rateLimited(retryAfter: TimeInterval)
    case networkError(Error)
    case decodingError(Error, Data)
    case notFound
    case serverError(Int, URL?, Data?)
    case invalidURL(String)
    case noData
    case connectionNotConfigured

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Authentication failed. Check your email and API token."
        case .rateLimited(let retryAfter):
            return "Rate limited. Retry after \(Int(retryAfter)) seconds."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error, _):
            return "Failed to parse response: \(error.localizedDescription)"
        case .notFound:
            return "Resource not found."
        case .serverError(let code, _, _):
            return "Server error (HTTP \(code))"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .noData:
            return "No data received."
        case .connectionNotConfigured:
            return "No connection configured. Please set up your JIRA credentials."
        }
    }
}
