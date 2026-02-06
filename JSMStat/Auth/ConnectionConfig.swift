import Foundation

struct ConnectionConfig: Equatable {
    var siteURL: String
    var email: String
    var apiToken: String

    var baseURL: URL? {
        var urlString = siteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if urlString.hasPrefix("http://") {
            urlString = "https://" + urlString.dropFirst("http://".count)
        } else if !urlString.hasPrefix("https://") {
            urlString = "https://\(urlString)"
        }
        if urlString.hasSuffix("/") {
            urlString = String(urlString.dropLast())
        }
        return URL(string: urlString)
    }

    var isValid: Bool {
        let trimmed = siteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !apiToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        return baseURL != nil
    }
}
