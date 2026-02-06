import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    @State private var siteURL: String = ""
    @State private var email: String = ""
    @State private var apiToken: String = ""
    @State private var savedMessage: String?

    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("notifyNewTickets") private var notifyNewTickets = true
    @AppStorage("notifyStatusChanges") private var notifyStatusChanges = true
    @AppStorage("notifyAssignments") private var notifyAssignments = true
    @AppStorage("pollIntervalMinutes") private var pollIntervalMinutes: Double = 1
    @AppStorage("refreshIntervalMinutes") private var refreshIntervalMinutes: Double = 5
    @AppStorage("opsCenterRotationSeconds") private var opsCenterRotationSeconds: Double = 30
    @AppStorage("maxRetries") private var maxRetries: Int = 3

    @State private var enabledSections: Set<String> = Set(DashboardSection.allCases.map(\.rawValue))

    var body: some View {
        TabView {
            connectionTab
                .tabItem {
                    Label("Connection", systemImage: "network")
                }

            notificationTab
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }

            displayTab
                .tabItem {
                    Label("Display", systemImage: "display")
                }

            sectionsTab
                .tabItem {
                    Label("Sections", systemImage: "sidebar.squares.left")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 400)
        .onAppear {
            if let config = KeychainManager.loadConfig() {
                siteURL = config.siteURL
                email = config.email
                apiToken = config.apiToken
            }
            enabledSections = UserSettings.enabledSections
        }
    }

    private var connectionTab: some View {
        Form {
            Section("JIRA Cloud Connection") {
                TextField("Site URL", text: $siteURL)
                TextField("Email", text: $email)
                SecureField("API Token", text: $apiToken)
            }

            HStack {
                Button("Save") {
                    let config = ConnectionConfig(siteURL: siteURL, email: email, apiToken: apiToken)
                    do {
                        try KeychainManager.saveConfig(config)
                        savedMessage = "Saved successfully"
                    } catch {
                        savedMessage = "Error: \(error.localizedDescription)"
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Disconnect") {
                    KeychainManager.deleteConfig()
                    siteURL = ""
                    email = ""
                    apiToken = ""
                    appState.connectionStatus = .disconnected
                    appState.discoveryCache.clear()
                }
                .buttonStyle(.bordered)

                if let msg = savedMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(msg.hasPrefix("Error") ? .red : .green)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var notificationTab: some View {
        Form {
            Toggle("Enable Notifications", isOn: $notificationsEnabled)
                .onChange(of: notificationsEnabled) { _, enabled in
                    if enabled {
                        Task {
                            _ = await NotificationManager.shared.requestAuthorization()
                        }
                    }
                }

            Section("Notify On") {
                Toggle("New Tickets", isOn: $notifyNewTickets)
                Toggle("Status Changes", isOn: $notifyStatusChanges)
                Toggle("Assignments", isOn: $notifyAssignments)
            }
            .disabled(!notificationsEnabled)

            Section("Polling") {
                HStack {
                    Text("Check every")
                    Slider(value: $pollIntervalMinutes, in: 0.5...10, step: 0.5)
                    Text("\(pollIntervalMinutes, specifier: "%.1f") min")
                        .monospacedDigit()
                        .frame(width: 60)
                }
            }
            .disabled(!notificationsEnabled)
        }
        .formStyle(.grouped)
    }

    private var displayTab: some View {
        Form {
            Section("Dashboard") {
                HStack {
                    Text("Auto-refresh every")
                    Slider(value: $refreshIntervalMinutes, in: 1...30, step: 1)
                    Text("\(Int(refreshIntervalMinutes)) min")
                        .monospacedDigit()
                        .frame(width: 50)
                }
            }

            Section("Operations Center") {
                HStack {
                    Text("Rotation interval")
                    Slider(value: $opsCenterRotationSeconds, in: 10...120, step: 5)
                    Text("\(Int(opsCenterRotationSeconds))s")
                        .monospacedDigit()
                        .frame(width: 40)
                }
            }

            Section {
                HStack {
                    Text("Max retries on error")
                    Slider(value: Binding(
                        get: { Double(maxRetries) },
                        set: { maxRetries = Int($0) }
                    ), in: 0...10, step: 1)
                    Text("\(maxRetries)")
                        .monospacedDigit()
                        .frame(width: 30)
                }
            } header: {
                Text("Reliability")
            } footer: {
                Text("Number of automatic retries with exponential backoff when API requests fail due to network or server errors.")
            }
        }
        .formStyle(.grouped)
    }

    private var sectionsTab: some View {
        Form {
            Section {
                ForEach(DashboardSection.allCases) { section in
                    if section.isToggleable {
                        Toggle(section.rawValue, isOn: Binding(
                            get: { enabledSections.contains(section.rawValue) },
                            set: { enabled in
                                if enabled {
                                    enabledSections.insert(section.rawValue)
                                } else {
                                    enabledSections.remove(section.rawValue)
                                }
                                UserSettings.enabledSections = enabledSections
                            }
                        ))
                    } else {
                        HStack {
                            Text(section.rawValue)
                            Spacer()
                            Text("Always On")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Dashboard Sections")
            } footer: {
                Text("Disabled sections are hidden from the sidebar and the operations center.")
            }

            HStack {
                Button("Enable All") {
                    enabledSections = Set(DashboardSection.allCases.map(\.rawValue))
                    UserSettings.enabledSections = enabledSections
                }
                .buttonStyle(.bordered)

                Button("Disable All") {
                    enabledSections = Set(DashboardSection.allCases.filter { !$0.isToggleable }.map(\.rawValue))
                    UserSettings.enabledSections = enabledSections
                }
                .buttonStyle(.bordered)
            }
        }
        .formStyle(.grouped)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    private var aboutTab: some View {
        VStack(spacing: 12) {
            Image(systemName: "ticket")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)

            Text("JSMStat")
                .font(.title.bold())

            Text(appVersion)
                .foregroundStyle(.secondary)

            Text("JIRA Service Management Metrics Dashboard")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            VStack(spacing: 4) {
                Text("Copyright \u{00A9} 2026 Timothy Ellis")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Text("Fyrby Additive Manufacturing & Engineering")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
