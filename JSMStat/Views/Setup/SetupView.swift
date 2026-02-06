import SwiftUI

struct SetupView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: SetupViewModel?

    let client: JIRAClient
    let discoveryManager: DiscoveryManager

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "ticket")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentColor)

                Text("Connect to JIRA Service Management")
                    .font(.title2.bold())

                Text("Enter your Atlassian Cloud site details to get started.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let vm = viewModel {
                    VStack(spacing: 16) {
                        TextField("Site URL (e.g. yoursite.atlassian.net)", text: Bindable(vm).siteURL)
                            .textFieldStyle(.roundedBorder)

                        TextField("Email address", text: Bindable(vm).email)
                            .textFieldStyle(.roundedBorder)

                        SecureField("API Token", text: Bindable(vm).apiToken)
                            .textFieldStyle(.roundedBorder)
                    }
                    .frame(maxWidth: 400)

                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 400)
                    }

                    Button(action: {
                        Task { await vm.connect() }
                    }) {
                        HStack {
                            if vm.isConnecting {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text(vm.isConnecting ? "Connecting..." : "Connect")
                        }
                        .frame(maxWidth: 200)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!vm.isValid || vm.isConnecting)
                    .keyboardShortcut(.defaultAction)
                }

                Link("How to create an API token",
                     destination: URL(string: "https://id.atlassian.com/manage-profile/security/api-tokens")!)
                    .font(.caption)
            }
            .padding(40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if viewModel == nil {
                viewModel = SetupViewModel(
                    client: client,
                    discoveryManager: discoveryManager,
                    appState: appState
                )
            }
        }
    }
}
