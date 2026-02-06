import SwiftUI
import os

private let logger = Logger(subsystem: "JSMStat", category: "DashboardVM")

@MainActor @Observable
final class DashboardViewModel {
    var snapshot: MetricSnapshot = .empty
    var isLoading = false
    var errorMessage: String?
    var lastRefreshed: Date?
    var retryCountdown: Int = 0

    private let metricsEngine: MetricsEngine
    private let appState: AppState
    private var refreshTask: Task<Void, Never>?
    private var autoRefreshTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?

    var refreshInterval: TimeInterval {
        UserSettings.refreshIntervalMinutes * 60
    }

    init(metricsEngine: MetricsEngine, appState: AppState) {
        self.metricsEngine = metricsEngine
        self.appState = appState
    }

    func startAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                let interval = self?.refreshInterval ?? 300
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                await self?.refresh()
            }
        }
    }

    func stopAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
    }

    func refresh() async {
        guard let serviceDesk = appState.selectedServiceDesk else { return }
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        retryCountdown = 0
        countdownTask?.cancel()

        // Use a child task with timeout so we never hang forever
        let engine = metricsEngine
        let period = appState.selectedTimePeriod

        do {
            let newSnapshot = try await withThrowingTaskGroup(of: MetricSnapshot.self) { group in
                group.addTask {
                    try await engine.fetchMetrics(serviceDesk: serviceDesk, period: period)
                }

                // Timeout task — 120 seconds max for the entire fetch
                group.addTask {
                    try await Task.sleep(for: .seconds(120))
                    throw APIError.networkError(URLError(.timedOut))
                }

                // Return whichever finishes first; cancel the other
                guard let result = try await group.next() else {
                    throw APIError.networkError(URLError(.timedOut))
                }
                group.cancelAll()
                return result
            }

            snapshot = newSnapshot
            lastRefreshed = Date()
            appState.menuBarStats = MenuBarStats(
                openCount: newSnapshot.overview.totalOpen,
                newCount: newSnapshot.overview.newInPeriod,
                slaBreachCount: newSnapshot.overview.slaBreachCount,
                lastRefreshed: lastRefreshed
            )
            logger.info("Refresh succeeded with \(newSnapshot.overview.totalOpen) open issues")
        } catch is CancellationError {
            logger.info("Refresh was cancelled")
        } catch {
            let friendlyMessage = Self.friendlyErrorMessage(for: error)
            errorMessage = friendlyMessage
            logger.error("Refresh failed: \(error.localizedDescription)")

            // Schedule an automatic retry after a delay (if we have stale data, keep showing it)
            scheduleAutoRetry()
        }

        isLoading = false
    }

    func refreshInBackground() {
        refreshTask?.cancel()
        countdownTask?.cancel()
        retryCountdown = 0
        refreshTask = Task {
            await refresh()
        }
    }

    func cancelRetry() {
        countdownTask?.cancel()
        retryCountdown = 0
    }

    // MARK: - Private

    private func scheduleAutoRetry() {
        countdownTask?.cancel()
        let delay = 30 // seconds before auto-retry
        retryCountdown = delay

        countdownTask = Task { [weak self] in
            for remaining in stride(from: delay, through: 1, by: -1) {
                guard !Task.isCancelled else { return }
                self?.retryCountdown = remaining
                try? await Task.sleep(for: .seconds(1))
            }
            guard !Task.isCancelled else { return }
            self?.retryCountdown = 0
            await self?.refresh()
        }
    }

    private static func friendlyErrorMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case .networkError(let underlying):
                if let urlError = underlying as? URLError {
                    switch urlError.code {
                    case .timedOut:
                        return "Request timed out. The server may be slow or unreachable."
                    case .notConnectedToInternet:
                        return "No internet connection. Check your network and try again."
                    case .cannotFindHost, .cannotConnectToHost:
                        return "Cannot reach the JIRA server. Check the site URL in settings."
                    default:
                        return "Network error: \(urlError.localizedDescription)"
                    }
                }
                return "Network error: \(underlying.localizedDescription)"
            case .unauthorized:
                return "Authentication failed. Check your email and API token in settings."
            case .rateLimited:
                return "Rate limited by JIRA. Will retry automatically."
            case .serverError(let code, _, _):
                return "JIRA server error (HTTP \(code)). The server may be experiencing issues."
            case .connectionNotConfigured:
                return "No connection configured. Set up your JIRA credentials in settings."
            default:
                return apiError.localizedDescription
            }
        }
        return error.localizedDescription
    }
}
