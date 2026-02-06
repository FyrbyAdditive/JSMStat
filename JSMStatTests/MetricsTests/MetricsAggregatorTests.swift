import XCTest
@testable import JSMStat

final class MetricsAggregatorTests: XCTestCase {

    private func makeIssue(
        key: String,
        status: String = "Open",
        statusCategoryKey: String = "new",
        priority: String = "Medium",
        assigneeId: String? = nil,
        assigneeName: String? = nil,
        reporterId: String? = nil,
        reporterName: String? = nil,
        issueType: String = "Service Request",
        created: String? = nil,
        resolved: String? = nil
    ) -> Issue {
        Issue(
            id: key,
            key: key,
            fields: IssueFields(
                summary: "Test \(key)",
                status: Status(
                    id: "1",
                    name: status,
                    statusCategory: StatusCategory(id: 1, key: statusCategoryKey, name: status, colorName: nil)
                ),
                priority: Priority(id: "3", name: priority, iconUrl: nil, statusColor: nil),
                assignee: assigneeId.map { JIRAUser(accountId: $0, displayName: assigneeName, emailAddress: nil, active: true, avatarUrls: nil) },
                reporter: reporterId.map { JIRAUser(accountId: $0, displayName: reporterName, emailAddress: nil, active: true, avatarUrls: nil) },
                issuetype: IssueType(id: "10", name: issueType, description: nil, subtask: false, iconUrl: nil),
                created: created,
                updated: nil,
                resolutiondate: resolved,
                resolution: resolved != nil ? Resolution(id: "1", name: "Done", description: nil) : nil
            )
        )
    }

    func testGroupByPriority() {
        let issues = [
            makeIssue(key: "T-1", priority: "High"),
            makeIssue(key: "T-2", priority: "Medium"),
            makeIssue(key: "T-3", priority: "High"),
            makeIssue(key: "T-4", priority: "Low"),
            makeIssue(key: "T-5", priority: "Medium"),
        ]

        let grouped = MetricsAggregator.groupByPriority(issues: issues)

        let highMetric = grouped.first(where: { $0.priorityName == "High" })
        XCTAssertNotNil(highMetric)
        XCTAssertEqual(highMetric?.count, 2)
        XCTAssertEqual(highMetric?.percentOfTotal ?? 0, 40.0, accuracy: 0.1)

        let mediumMetric = grouped.first(where: { $0.priorityName == "Medium" })
        XCTAssertEqual(mediumMetric?.count, 2)
    }

    func testGroupByIssueType() {
        let issues = [
            makeIssue(key: "T-1", issueType: "Bug"),
            makeIssue(key: "T-2", issueType: "Service Request"),
            makeIssue(key: "T-3", issueType: "Bug"),
            makeIssue(key: "T-4", issueType: "Incident"),
        ]

        let grouped = MetricsAggregator.groupByIssueType(issues: issues)
        XCTAssertEqual(grouped.count, 3)

        let bugMetric = grouped.first(where: { $0.name == "Bug" })
        XCTAssertEqual(bugMetric?.count, 2)
        XCTAssertEqual(bugMetric?.percentOfTotal ?? 0, 50.0, accuracy: 0.1)
    }

    func testGroupByReporter() {
        let issues = [
            makeIssue(key: "T-1", reporterId: "user-1", reporterName: "Alice"),
            makeIssue(key: "T-2", reporterId: "user-1", reporterName: "Alice"),
            makeIssue(key: "T-3", reporterId: "user-2", reporterName: "Bob"),
            makeIssue(key: "T-4", reporterId: "user-1", reporterName: "Alice"),
        ]

        let grouped = MetricsAggregator.groupByReporter(issues: issues)
        XCTAssertEqual(grouped.count, 2)

        let alice = grouped.first(where: { $0.reporter.accountId == "user-1" })
        XCTAssertEqual(alice?.ticketCount, 3)

        let bob = grouped.first(where: { $0.reporter.accountId == "user-2" })
        XCTAssertEqual(bob?.ticketCount, 1)
    }

    func testComputeOverview() {
        let open = [
            makeIssue(key: "T-1"),
            makeIssue(key: "T-2"),
            makeIssue(key: "T-3"),
        ]

        let closed = [
            makeIssue(key: "T-4", created: "2025-01-01T00:00:00.000+0000", resolved: "2025-01-02T12:00:00.000+0000"),
            makeIssue(key: "T-5", created: "2025-01-01T00:00:00.000+0000", resolved: "2025-01-03T00:00:00.000+0000"),
        ]

        let created = [
            makeIssue(key: "T-6"),
            makeIssue(key: "T-7"),
        ]

        let overview = MetricsAggregator.computeOverview(open: open, closedInPeriod: closed, createdInPeriod: created, slaBreaches: 1)

        XCTAssertEqual(overview.totalOpen, 3)
        XCTAssertEqual(overview.totalClosedInPeriod, 2)
        XCTAssertEqual(overview.newInPeriod, 2)
        XCTAssertEqual(overview.slaBreachCount, 1)
        XCTAssertEqual(overview.avgResolutionHours, 42.0, accuracy: 0.1) // avg of 36h and 48h
    }
}
