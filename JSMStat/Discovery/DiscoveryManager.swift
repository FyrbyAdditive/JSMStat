import Foundation

@MainActor
final class DiscoveryManager {
    private let client: JIRAClient
    private let cache: DiscoveryCache

    init(client: JIRAClient, cache: DiscoveryCache) {
        self.client = client
        self.cache = cache
    }

    func discoverAll() async throws {
        cache.clear()

        // Service desks are required — this must succeed
        let serviceDesks = try await client.getServiceDesks()
        cache.serviceDesks = serviceDesks

        // Other metadata is best-effort
        if let issueTypes = try? await client.getIssueTypes() {
            cache.issueTypes = issueTypes
        }
        if let statuses = try? await client.getStatuses() {
            cache.statuses = statuses
        }
        if let statusCategories = try? await client.getStatusCategories() {
            cache.statusCategories = statusCategories
        }
        if let priorities = try? await client.getPriorities() {
            cache.priorities = priorities
        }
        if let fields = try? await client.getFields() {
            cache.fields = fields
        }

        for desk in serviceDesks {
            let deskId = desk.id
            let projectKey = desk.projectKey
            Task { @MainActor in
                if let requestTypes = try? await self.client.getRequestTypes(serviceDeskId: deskId) {
                    self.cache.requestTypesByDesk[deskId] = requestTypes
                }
            }
            Task { @MainActor in
                if let users = try? await self.client.getAssignableUsers(projectKey: projectKey) {
                    self.cache.usersByProject[projectKey] = users
                }
            }
        }
    }
}
