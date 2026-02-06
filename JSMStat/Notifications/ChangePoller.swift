import Foundation

struct ChangeEvent {
    enum Kind {
        case newTicket
        case statusChanged
        case assigned
    }

    let kind: Kind
    let issueKey: String
    let summary: String
    let detail: String
}

actor ChangePoller {
    private let client: JIRAClient
    private let projectKey: String
    private var knownIssueStates: [String: String] = [:] // issueKey -> status name
    private var pollingTask: Task<Void, Never>?
    private var onChange: ((ChangeEvent) -> Void)?
    var pollInterval: TimeInterval = 60

    init(client: JIRAClient, projectKey: String) {
        self.client = client
        // Validate project key to prevent JQL injection
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        let isSafe = projectKey.unicodeScalars.allSatisfy { allowed.contains($0) }
            && !projectKey.isEmpty && projectKey.count <= 20
        self.projectKey = isSafe ? projectKey : "INVALID"
    }

    func start(onChange: @escaping (ChangeEvent) -> Void) {
        self.onChange = onChange
        pollingTask?.cancel()
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(pollInterval))
                guard !Task.isCancelled else { break }
                await poll()
            }
        }
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    private func poll() async {
        let intervalMinutes = Int(pollInterval / 60) + 1
        let jql = "project = \(projectKey) AND updated >= -\(intervalMinutes)m ORDER BY updated DESC"

        do {
            let result = try await client.searchIssues(jql: jql, maxResults: 50)

            for issue in result.issues {
                let key = issue.key
                let currentStatus = issue.fields.status?.name ?? "Unknown"
                let summary = issue.fields.summary ?? key

                if let previousStatus = knownIssueStates[key] {
                    if previousStatus != currentStatus {
                        let event = ChangeEvent(
                            kind: .statusChanged,
                            issueKey: key,
                            summary: summary,
                            detail: "\(previousStatus) → \(currentStatus)"
                        )
                        onChange?(event)
                    }
                } else if !knownIssueStates.isEmpty {
                    // New ticket (wasn't in previous poll, and we've polled before)
                    let event = ChangeEvent(
                        kind: .newTicket,
                        issueKey: key,
                        summary: summary,
                        detail: "New ticket created"
                    )
                    onChange?(event)
                }

                knownIssueStates[key] = currentStatus
            }
        } catch {
            // Polling failure is non-fatal
        }
    }
}
