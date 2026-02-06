import SwiftUI

struct ToolbarControls: View {
    @Environment(AppState.self) private var appState
    let lastRefreshed: Date?
    var isLoading: Bool = false
    let onRefresh: () -> Void

    @State private var rotationAngle: Double = 0

    var body: some View {
        @Bindable var state = appState

        HStack(spacing: 12) {
            if !appState.discoveryCache.serviceDesks.isEmpty {
                Picker("Service Desk", selection: $state.selectedServiceDesk) {
                    ForEach(appState.discoveryCache.serviceDesks) { desk in
                        Text(desk.projectName).tag(Optional(desk))
                    }
                }
                .frame(minWidth: 150)
            }

            Picker("Period", selection: $state.selectedTimePeriod) {
                ForEach(TimePeriod.presets, id: \.id) { period in
                    Text(period.label).tag(period)
                }
            }
            .frame(minWidth: 120)

            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
                    .rotationEffect(.degrees(rotationAngle))
            }
            .keyboardShortcut("r", modifiers: .command)
            .help("Refresh (Cmd+R)")
            .disabled(isLoading)
            .onChange(of: isLoading) { _, loading in
                if loading {
                    withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                        rotationAngle = 360
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.3)) {
                        rotationAngle = 0
                    }
                }
            }

            if let date = lastRefreshed {
                Text("Updated \(DateFormatting.relativeString(from: date))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .help("Last refreshed: \(DateFormatting.mediumDateTimeFormatter.string(from: date))")
            }
        }
    }
}
