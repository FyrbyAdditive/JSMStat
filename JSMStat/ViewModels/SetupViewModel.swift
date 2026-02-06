import SwiftUI

@MainActor @Observable
final class SetupViewModel {
    var siteURL: String = ""
    var email: String = ""
    var apiToken: String = ""
    var isConnecting = false
    var errorMessage: String?

    private let client: JIRAClient
    private let discoveryManager: DiscoveryManager
    private let appState: AppState

    init(client: JIRAClient, discoveryManager: DiscoveryManager, appState: AppState) {
        self.client = client
        self.discoveryManager = discoveryManager
        self.appState = appState

        if let config = KeychainManager.loadConfig() {
            siteURL = config.siteURL
            email = config.email
            apiToken = config.apiToken
        }
    }

    var isValid: Bool {
        !siteURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !apiToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func connect() async {
        guard isValid else { return }

        isConnecting = true
        errorMessage = nil
        appState.connectionStatus = .connecting

        let config = ConnectionConfig(
            siteURL: siteURL.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            apiToken: apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        await client.configure(with: config)

        do {
            try await discoveryManager.discoverAll()

            try KeychainManager.saveConfig(config)

            if appState.selectedServiceDesk == nil,
               let firstDesk = appState.discoveryCache.serviceDesks.first {
                appState.selectedServiceDesk = firstDesk
            }

            appState.connectionStatus = .connected
        } catch {
            appState.connectionStatus = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
        }

        isConnecting = false
    }

    func disconnect() {
        KeychainManager.deleteConfig()
        appState.connectionStatus = .disconnected
        appState.selectedServiceDesk = nil
        appState.discoveryCache.clear()
        siteURL = ""
        email = ""
        apiToken = ""
    }
}
