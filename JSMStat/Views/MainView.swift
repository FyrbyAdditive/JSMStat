import SwiftUI

struct MainView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedSection: DashboardSection? = .overview

    var body: some View {
        Group {
            if appState.isConnected {
                NavigationSplitView {
                    Sidebar(selection: $selectedSection)
                } detail: {
                    if let vm = appState.dashboardVM {
                        dashboardContent(vm: vm)
                            .toolbar {
                                ToolbarItem(placement: .principal) {
                                    ToolbarControls(lastRefreshed: vm.lastRefreshed, isLoading: vm.isLoading, onRefresh: { vm.refreshInBackground() })
                                        .environment(appState)
                                }
                            }
                    } else {
                        ProgressView("Loading...")
                    }
                }
                .onChange(of: appState.selectedServiceDesk) { _, _ in
                    appState.dashboardVM?.refreshInBackground()
                }
                .onChange(of: appState.selectedTimePeriod) { _, _ in
                    appState.dashboardVM?.refreshInBackground()
                }
            } else {
                if let dm = appState.discoveryManager {
                    SetupView(client: appState.client, discoveryManager: dm)
                } else {
                    ProgressView()
                }
            }
        }
        .onAppear(perform: initialize)
    }

    private func initialize() {
        appState.initializePipeline()

        // Auto-connect if credentials exist
        if !appState.isConnected, let config = KeychainManager.loadConfig() {
            Task {
                await appState.client.configure(with: config)
                appState.connectionStatus = .connecting
                do {
                    try await appState.discoveryManager?.discoverAll()
                    if appState.selectedServiceDesk == nil,
                       let first = appState.discoveryCache.serviceDesks.first {
                        appState.selectedServiceDesk = first
                    }
                    appState.connectionStatus = .connected
                    await appState.dashboardVM?.refresh()
                } catch {
                    appState.connectionStatus = .error(error.localizedDescription)
                }
            }
        }
    }

    @ViewBuilder
    private func dashboardContent(vm: DashboardViewModel) -> some View {
        Group {
            switch selectedSection {
            case .overview:
                OverviewDashboard(viewModel: vm)
            case .trends:
                TicketTrendsDashboard(viewModel: vm)
            case .byPerson:
                ByPersonDashboard(viewModel: vm)
            case .byCategory:
                ByCategoryDashboard(viewModel: vm)
            case .endUsers:
                EndUserDashboard(viewModel: vm)
            case .priority:
                PriorityDashboard(viewModel: vm)
            case .sla:
                SLADashboard(viewModel: vm)
            case .issues:
                IssuesDashboard(viewModel: vm)
            case .none:
                OverviewDashboard(viewModel: vm)
            }
        }
        .id(selectedSection)
        .transition(.opacity.combined(with: .offset(y: 8)))
        .animation(DesignTokens.cardEntrance, value: selectedSection)
        .overlay {
            if vm.isLoading {
                ZStack {
                    Color.clear
                    ProgressView()
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
                .allowsHitTesting(false)
            }
        }
        .opacity(vm.isLoading ? 0.6 : 1.0)
        .animation(DesignTokens.dataTransition, value: vm.isLoading)
        .overlay(alignment: .bottom) {
            if let error = vm.errorMessage {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .lineLimit(2)
                        .font(.callout)
                    Spacer()
                    if vm.retryCountdown > 0 {
                        Text("Retrying in \(vm.retryCountdown)s")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(.default, value: vm.retryCountdown)
                    }
                    Button("Retry Now") { vm.refreshInBackground() }
                        .buttonStyle(.bordered)
                    Button {
                        vm.cancelRetry()
                        vm.errorMessage = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.orange.opacity(0.3), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeOut(duration: 0.3), value: vm.errorMessage)
            }
        }
    }
}
