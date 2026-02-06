import Foundation
import os

private let logger = Logger(subsystem: "JSMStat", category: "JIRAClient")

actor JIRAClient {
    private let session: URLSession
    private let rateLimiter = RateLimiter()
    private var config: ConnectionConfig?

    init() {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpAdditionalHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        sessionConfig.timeoutIntervalForRequest = 30
        sessionConfig.timeoutIntervalForResource = 120
        sessionConfig.httpShouldSetCookies = false
        sessionConfig.urlCache = nil
        sessionConfig.tlsMinimumSupportedProtocolVersion = .TLSv12
        self.session = URLSession(configuration: sessionConfig)
    }

    func configure(with config: ConnectionConfig) {
        self.config = config
    }

    var isConfigured: Bool {
        config != nil
    }

    private var baseURL: URL {
        get throws {
            guard let config = config else {
                throw APIError.connectionNotConfigured
            }
            guard let url = config.baseURL else {
                throw APIError.invalidURL(config.siteURL)
            }
            return url
        }
    }

    private var authHeader: String {
        get throws {
            guard let config = config else {
                throw APIError.connectionNotConfigured
            }
            let credentials = "\(config.email):\(config.apiToken)"
            guard let data = credentials.data(using: .utf8) else {
                throw APIError.unauthorized
            }
            return "Basic \(data.base64EncodedString())"
        }
    }

    // MARK: - Generic Request

    func request<T: Decodable>(_ url: URL, type: T.Type) async throws -> T {
        try await rateLimiter.waitIfNeeded()

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(try authHeader, forHTTPHeaderField: "Authorization")

        logger.debug("GET \(url.absoluteString)")

        let (data, response) = try await performRequest(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        logger.debug("GET \(url.absoluteString) → \(httpResponse.statusCode)")

        switch httpResponse.statusCode {
        case 200...299:
            await rateLimiter.recordSuccess()
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error, data)
            }
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { TimeInterval($0) } ?? 10.0
            try await rateLimiter.handleRateLimited(retryAfter: retryAfter)
            return try await self.request(url, type: type)
        default:
            throw APIError.serverError(httpResponse.statusCode, url, data)
        }
    }

    private func postRequest<T: Decodable>(_ url: URL, body: some Encodable, type: T.Type) async throws -> T {
        try await rateLimiter.waitIfNeeded()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(try authHeader, forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        logger.debug("POST \(url.absoluteString)")

        let (data, response) = try await performRequest(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        logger.debug("POST \(url.absoluteString) → \(httpResponse.statusCode)")

        switch httpResponse.statusCode {
        case 200...299:
            await rateLimiter.recordSuccess()
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error, data)
            }
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { TimeInterval($0) } ?? 10.0
            try await rateLimiter.handleRateLimited(retryAfter: retryAfter)
            return try await self.postRequest(url, body: body, type: type)
        default:
            throw APIError.serverError(httpResponse.statusCode, url, data)
        }
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
    }

    /// Returns raw Data instead of decoding — used when multiple decode strategies are needed.
    private func requestRaw(_ url: URL) async throws -> Data {
        try await rateLimiter.waitIfNeeded()

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(try authHeader, forHTTPHeaderField: "Authorization")

        logger.debug("GET (raw) \(url.absoluteString)")

        let (data, response) = try await performRequest(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        logger.debug("GET (raw) \(url.absoluteString) → \(httpResponse.statusCode)")

        switch httpResponse.statusCode {
        case 200...299:
            await rateLimiter.recordSuccess()
            return data
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { TimeInterval($0) } ?? 10.0
            try await rateLimiter.handleRateLimited(retryAfter: retryAfter)
            return try await self.requestRaw(url)
        default:
            throw APIError.serverError(httpResponse.statusCode, url, data)
        }
    }

    private func requestRawWithRetry(_ url: URL) async throws -> Data {
        let maxRetries = UserSettings.maxRetries
        var lastError: APIError?

        for attempt in 0...maxRetries {
            do {
                return try await requestRaw(url)
            } catch let error as APIError {
                lastError = error
                guard isRetryableError(error) && attempt < maxRetries else {
                    throw error
                }
                let delay = retryDelay(attempt: attempt)
                logger.warning("Retryable error (raw) on attempt \(attempt + 1)/\(maxRetries + 1) for \(url.absoluteString): \(error.localizedDescription). Retrying in \(String(format: "%.1f", delay))s")
                do {
                    try await Task.sleep(for: .seconds(delay))
                } catch is CancellationError {
                    throw lastError ?? error
                } catch {}
            }
        }
        throw lastError ?? APIError.networkError(URLError(.unknown))
    }

    // MARK: - Retry Logic

    private func isRetryableError(_ error: APIError) -> Bool {
        switch error {
        case .networkError:
            return true
        case .serverError(let code, _, _):
            return code >= 500 && code <= 599
        case .rateLimited:
            return false // Handled inline by request() via 429 branch
        case .unauthorized, .notFound, .decodingError, .invalidURL, .noData, .connectionNotConfigured:
            return false
        }
    }

    private func retryDelay(attempt: Int) -> TimeInterval {
        let base: TimeInterval = 1.0
        let delay = base * pow(2.0, Double(attempt))
        // Add jitter: ±25%
        let jitter = delay * Double.random(in: -0.25...0.25)
        return min(delay + jitter, 30.0) // Cap at 30 seconds
    }

    private func requestWithRetry<T: Decodable>(_ url: URL, type: T.Type) async throws -> T {
        let maxRetries = UserSettings.maxRetries
        var lastError: APIError?

        for attempt in 0...maxRetries {
            do {
                return try await request(url, type: type)
            } catch let error as APIError {
                lastError = error
                guard isRetryableError(error) && attempt < maxRetries else {
                    throw error
                }
                let delay = retryDelay(attempt: attempt)
                logger.warning("Retryable error on attempt \(attempt + 1)/\(maxRetries + 1) for \(url.absoluteString): \(error.localizedDescription). Retrying in \(String(format: "%.1f", delay))s")
                do {
                    try await Task.sleep(for: .seconds(delay))
                } catch is CancellationError {
                    throw lastError ?? error
                } catch {}
            }
        }
        throw lastError ?? APIError.networkError(URLError(.unknown))
    }

    private func postRequestWithRetry<T: Decodable>(_ url: URL, body: some Encodable, type: T.Type) async throws -> T {
        let maxRetries = UserSettings.maxRetries
        var lastError: APIError?

        for attempt in 0...maxRetries {
            do {
                return try await postRequest(url, body: body, type: type)
            } catch let error as APIError {
                lastError = error
                guard isRetryableError(error) && attempt < maxRetries else {
                    throw error
                }
                let delay = retryDelay(attempt: attempt)
                logger.warning("Retryable error on attempt \(attempt + 1)/\(maxRetries + 1) for \(url.absoluteString): \(error.localizedDescription). Retrying in \(String(format: "%.1f", delay))s")
                do {
                    try await Task.sleep(for: .seconds(delay))
                } catch is CancellationError {
                    throw lastError ?? error
                } catch {}
            }
        }
        throw lastError ?? APIError.networkError(URLError(.unknown))
    }

    // MARK: - Service Desk APIs

    func getServiceDesks() async throws -> [ServiceDesk] {
        let url = try JIRAEndpoints.serviceDesks(baseURL: baseURL)
        let result: ServiceDeskListResponse = try await requestWithRetry(url, type: ServiceDeskListResponse.self)
        return result.values
    }

    func getRequestTypes(serviceDeskId: String) async throws -> [RequestType] {
        let url = try JIRAEndpoints.requestTypes(baseURL: baseURL, serviceDeskId: serviceDeskId)
        let result: RequestTypeListResponse = try await requestWithRetry(url, type: RequestTypeListResponse.self)
        return result.values
    }

    func getSLA(issueKey: String) async throws -> [SLAMetric] {
        let url = try JIRAEndpoints.sla(baseURL: baseURL, issueKey: issueKey)
        let result: SLAListResponse = try await requestWithRetry(url, type: SLAListResponse.self)
        return result.values
    }

    // MARK: - Platform APIs

    func searchIssues(jql: String, maxResults: Int = 100, fields: [String]? = nil, nextPageToken: String? = nil) async throws -> SearchResult {
        let defaultFields = fields ?? [
            "summary", "status", "priority", "assignee", "reporter",
            "issuetype", "created", "updated", "resolutiondate", "resolution"
        ]
        let url = try JIRAEndpoints.searchJQL(baseURL: baseURL)
        let body = SearchRequestBody(
            jql: jql,
            maxResults: maxResults,
            fields: defaultFields,
            nextPageToken: nextPageToken
        )
        return try await postRequestWithRetry(url, body: body, type: SearchResult.self)
    }

    func searchAllIssues(jql: String, fields: [String]? = nil) async throws -> [Issue] {
        var allIssues: [Issue] = []
        var nextPageToken: String? = nil
        let maxPages = 50 // Safety limit to prevent infinite pagination

        for _ in 0..<maxPages {
            let result = try await searchIssues(jql: jql, maxResults: 100, fields: fields, nextPageToken: nextPageToken)
            allIssues.append(contentsOf: result.issues)

            guard let token = result.nextPageToken, !result.issues.isEmpty else {
                break
            }
            nextPageToken = token

            // Check for cancellation between pages
            if Task.isCancelled {
                logger.info("searchAllIssues cancelled after \(allIssues.count) issues")
                break
            }
        }

        return allIssues
    }

    func getStatuses() async throws -> [Status] {
        let url = try JIRAEndpoints.statuses(baseURL: baseURL)
        let result: StatusSearchResponse = try await requestWithRetry(url, type: StatusSearchResponse.self)
        return result.values ?? []
    }

    func getStatusCategories() async throws -> [StatusCategory] {
        let url = try JIRAEndpoints.statusCategories(baseURL: baseURL)
        return try await requestWithRetry(url, type: [StatusCategory].self)
    }

    func getIssueTypes() async throws -> [IssueType] {
        let url = try JIRAEndpoints.issueTypes(baseURL: baseURL)
        return try await requestWithRetry(url, type: [IssueType].self)
    }

    func getPriorities() async throws -> [Priority] {
        let url = try JIRAEndpoints.priorities(baseURL: try baseURL)
        // Single network call, two decode attempts
        let data = try await requestRawWithRetry(url)
        let decoder = JSONDecoder()
        if let array = try? decoder.decode([Priority].self, from: data) {
            return array
        }
        if let paginated = try? decoder.decode(PaginatedResponse<Priority>.self, from: data) {
            return paginated.values ?? []
        }
        throw APIError.decodingError(
            DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Response is neither [Priority] nor PaginatedResponse<Priority>")),
            data
        )
    }

    func getFields() async throws -> [JIRAField] {
        let url = try JIRAEndpoints.fields(baseURL: baseURL)
        return try await requestWithRetry(url, type: [JIRAField].self)
    }

    func getAssignableUsers(projectKey: String) async throws -> [JIRAUser] {
        let url = try JIRAEndpoints.assignableUsers(baseURL: baseURL, projectKey: projectKey)
        return try await requestWithRetry(url, type: [JIRAUser].self)
    }
}
