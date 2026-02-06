import SwiftUI

enum ConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
}

struct MenuBarStats {
    var openCount: Int = 0
    var newCount: Int = 0
    var slaBreachCount: Int = 0
    var lastRefreshed: Date?

    static let empty = MenuBarStats()
}

@MainActor @Observable
final class AppState {
    var connectionStatus: ConnectionStatus = .disconnected
    var selectedServiceDesk: ServiceDesk?
    var selectedTimePeriod: TimePeriod = .last7Days
    var discoveryCache = DiscoveryCache()
    var menuBarStats: MenuBarStats = .empty

    // MARK: - Shared Data Pipeline

    /// Single shared API client used by all windows
    let client = JIRAClient()

    /// Shared metrics engine — created once via `initializePipeline()`
    private(set) var metricsEngine: MetricsEngine?

    /// Shared discovery manager — created once via `initializePipeline()`
    private(set) var discoveryManager: DiscoveryManager?

    /// Single shared view model that drives all dashboard views (main window, ops center, menu bar)
    var dashboardVM: DashboardViewModel?

    var isConnected: Bool {
        if case .connected = connectionStatus { return true }
        return false
    }

    /// Initialize the shared data pipeline. Safe to call multiple times — guards against re-initialization.
    func initializePipeline() {
        if discoveryManager == nil {
            discoveryManager = DiscoveryManager(client: client, cache: discoveryCache)
        }
        if metricsEngine == nil {
            metricsEngine = MetricsEngine(client: client)
        }
        if dashboardVM == nil, let engine = metricsEngine {
            let vm = DashboardViewModel(metricsEngine: engine, appState: self)
            dashboardVM = vm
            vm.startAutoRefresh()
        }
    }
}
