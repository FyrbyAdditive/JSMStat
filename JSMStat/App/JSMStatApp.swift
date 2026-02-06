import SwiftUI

@main
struct JSMStatApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(appState)
        }
        .defaultSize(width: 1200, height: 800)

        WindowGroup("Operations Center", id: "ops-center") {
            OpsCenterView()
                .environment(appState)
        }
        .windowStyle(.hiddenTitleBar)

        Settings {
            SettingsView()
                .environment(appState)
        }

        MenuBarExtra {
            MenuBarView()
                .environment(appState)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "ticket")
                if appState.isConnected && appState.menuBarStats.openCount > 0 {
                    Text("\(appState.menuBarStats.openCount)")
                        .monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
