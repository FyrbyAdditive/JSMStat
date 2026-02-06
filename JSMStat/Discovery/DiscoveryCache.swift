import Foundation

@MainActor @Observable
final class DiscoveryCache {
    var serviceDesks: [ServiceDesk] = []
    var issueTypes: [IssueType] = []
    var statuses: [Status] = []
    var statusCategories: [StatusCategory] = []
    var priorities: [Priority] = []
    var fields: [JIRAField] = []
    var requestTypesByDesk: [String: [RequestType]] = [:]
    var usersByProject: [String: [JIRAUser]] = [:]

    var isPopulated: Bool {
        !serviceDesks.isEmpty
    }

    func requestTypes(for serviceDeskId: String) -> [RequestType] {
        requestTypesByDesk[serviceDeskId] ?? []
    }

    func users(for projectKey: String) -> [JIRAUser] {
        usersByProject[projectKey] ?? []
    }

    func clear() {
        serviceDesks = []
        issueTypes = []
        statuses = []
        statusCategories = []
        priorities = []
        fields = []
        requestTypesByDesk = [:]
        usersByProject = [:]
    }
}
