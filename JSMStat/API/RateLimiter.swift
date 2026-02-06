import Foundation

actor RateLimiter {
    private var retryAfterDate: Date?
    private var consecutiveThrottles = 0
    private let maxRetries = 5

    func waitIfNeeded() async throws {
        if let retryDate = retryAfterDate, retryDate > Date() {
            let waitTime = retryDate.timeIntervalSinceNow
            if waitTime > 0 {
                try await Task.sleep(for: .seconds(waitTime))
            }
            retryAfterDate = nil
        }
    }

    func handleRateLimited(retryAfter: TimeInterval) async throws {
        consecutiveThrottles += 1
        guard consecutiveThrottles <= maxRetries else {
            throw APIError.rateLimited(retryAfter: retryAfter)
        }

        let backoffMultiplier = pow(2.0, Double(consecutiveThrottles - 1))
        let effectiveDelay = max(retryAfter, 1.0) * backoffMultiplier
        let cappedDelay = min(effectiveDelay, 60.0)

        retryAfterDate = Date().addingTimeInterval(cappedDelay)
        try await Task.sleep(for: .seconds(cappedDelay))
    }

    func recordSuccess() {
        consecutiveThrottles = 0
        retryAfterDate = nil
    }
}
