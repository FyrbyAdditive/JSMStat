import Foundation

final class MetricsEngine: Sendable {
    private let client: JIRAClient

    init(client: JIRAClient) {
        self.client = client
    }

    func fetchMetrics(serviceDesk: ServiceDesk, period: TimePeriod) async throws -> MetricSnapshot {
        let projectKey = serviceDesk.sanitizedProjectKey
        let startDate = DateFormatting.jqlDate(period.startDate)

        // Previous period for trend comparison
        let prevPeriod = period.previousPeriod
        let prevStartDate = DateFormatting.jqlDate(prevPeriod.startDate)
        let prevEndDate = DateFormatting.jqlDate(prevPeriod.endDate)

        let openJQL = "project = \(projectKey) AND statusCategory != Done ORDER BY created DESC"
        let closedJQL = "project = \(projectKey) AND statusCategory = Done AND resolved >= \"\(startDate)\" ORDER BY resolved DESC"
        let createdJQL = "project = \(projectKey) AND created >= \"\(startDate)\" ORDER BY created DESC"
        let prevClosedJQL = "project = \(projectKey) AND statusCategory = Done AND resolved >= \"\(prevStartDate)\" AND resolved < \"\(prevEndDate)\" ORDER BY resolved DESC"
        let prevCreatedJQL = "project = \(projectKey) AND created >= \"\(prevStartDate)\" AND created < \"\(prevEndDate)\" ORDER BY created DESC"

        async let openTask = client.searchAllIssues(jql: openJQL)
        async let closedTask = client.searchAllIssues(jql: closedJQL)
        async let createdTask = client.searchAllIssues(jql: createdJQL)
        async let prevClosedTask = client.searchAllIssues(jql: prevClosedJQL)
        async let prevCreatedTask = client.searchAllIssues(jql: prevCreatedJQL)

        let open = try await openTask
        let closed = try await closedTask
        let created = try await createdTask
        let prevClosed = try await prevClosedTask
        let prevCreated = try await prevCreatedTask

        let createdIDs = Set(created.map(\.id))
        let allPeriodIssues = created + closed.filter { !createdIDs.contains($0.id) }

        // SLA sampling — check a subset of open issues for SLA data
        let slaBreaches = await fetchSLABreachCount(issues: Array(open.prefix(50)))

        let overview = MetricsAggregator.computeOverview(
            open: open,
            closedInPeriod: closed,
            createdInPeriod: created,
            slaBreaches: slaBreaches,
            previousClosed: prevClosed,
            previousCreated: prevCreated
        )

        let trends = MetricsAggregator.buildTrends(created: created, resolved: closed, period: period)
        let byPerson = MetricsAggregator.groupByAssignee(issues: allPeriodIssues, allIssues: open + closed)
        let byCategory = MetricsAggregator.groupByIssueType(issues: allPeriodIssues, closedIssues: closed)
        let byEndUser = MetricsAggregator.groupByReporter(issues: created)
        let byPriority = MetricsAggregator.groupByPriority(issues: open, closedIssues: closed)

        let slaSnapshots = buildSLASnapshots(breachCount: slaBreaches, totalOpen: open.count)
        let backlogAging = MetricsAggregator.computeBacklogAging(openIssues: open)
        let issuesSnapshot = MetricsAggregator.computeIssuesSnapshot(openIssues: open)

        return MetricSnapshot(
            overview: overview,
            trends: trends,
            byPerson: byPerson,
            byCategory: byCategory,
            byEndUser: byEndUser,
            byPriority: byPriority,
            sla: slaSnapshots,
            backlogAging: backlogAging,
            issues: issuesSnapshot
        )
    }

    private func fetchSLABreachCount(issues: [Issue]) async -> Int {
        var breaches = 0
        await withTaskGroup(of: Int.self) { group in
            for issue in issues {
                group.addTask {
                    do {
                        let metrics = try await self.client.getSLA(issueKey: issue.key)
                        return metrics.reduce(0) { $0 + $1.breachedCount }
                    } catch {
                        return 0
                    }
                }
            }
            for await count in group {
                breaches += count
            }
        }
        return breaches
    }

    private func buildSLASnapshots(breachCount: Int, totalOpen: Int) -> [SLASnapshot] {
        guard totalOpen > 0 else { return [] }
        return [
            SLASnapshot(
                metricName: "Overall SLA",
                totalCycles: totalOpen,
                breachedCount: breachCount,
                compliancePercent: totalOpen > 0 ? Double(totalOpen - breachCount) / Double(totalOpen) * 100 : 100
            )
        ]
    }
}
