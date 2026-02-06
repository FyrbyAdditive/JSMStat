import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if appState.isConnected {
                if let desk = appState.selectedServiceDesk {
                    Text(desk.projectName)
                        .font(.headline)
                }

                Divider()

                let stats = appState.menuBarStats

                HStack {
                    Label("\(stats.openCount) Open", systemImage: "ticket")
                    Spacer()
                }
                .foregroundStyle(.orange)

                HStack {
                    Label("\(stats.newCount) New", systemImage: "plus.circle")
                    Spacer()
                }
                .foregroundStyle(.blue)

                if stats.slaBreachCount > 0 {
                    HStack {
                        Label("\(stats.slaBreachCount) SLA Breaches", systemImage: "exclamationmark.triangle.fill")
                        Spacer()
                    }
                    .foregroundStyle(.red)
                } else {
                    HStack {
                        Label("SLA On Track", systemImage: "checkmark.circle.fill")
                        Spacer()
                    }
                    .foregroundStyle(.green)
                }

                if let lastRefreshed = stats.lastRefreshed {
                    Text("Updated \(DateFormatting.relativeString(from: lastRefreshed))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                Button("Open Dashboard") {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }

                Button("Operations Center") {
                    openWindow(id: "ops-center")
                }
            } else {
                Label("Not Connected", systemImage: "xmark.circle")
                    .foregroundStyle(.secondary)

                Button("Open JSMStat") {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
            }

            Divider()

            Button("Quit JSMStat") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(8)
        .frame(width: 220)
    }
}
