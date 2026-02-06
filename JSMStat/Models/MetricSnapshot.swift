import Foundation

struct AgingBucket: Identifiable {
    let id = UUID()
    var label: String
    var count: Int
    var color: String  // color name for chart rendering
}

struct MetricSnapshot {
    var overview: OverviewSnapshot
    var trends: [TrendDataPoint]
    var byPerson: [PersonMetric]
    var byCategory: [CategoryMetric]
    var byEndUser: [EndUserMetric]
    var byPriority: [PriorityMetric]
    var sla: [SLASnapshot]
    var backlogAging: [AgingBucket]
    var issues: IssuesSnapshot

    static let empty = MetricSnapshot(
        overview: .empty,
        trends: [],
        byPerson: [],
        byCategory: [],
        byEndUser: [],
        byPriority: [],
        sla: [],
        backlogAging: [],
        issues: .empty
    )
}

// MARK: - Issues Snapshot

struct IssueSummary: Identifiable {
    let id: String
    let key: String
    let summary: String
    let priorityName: String
    let statusName: String
    let assigneeName: String?
    let ageHours: Double
    let createdDate: Date
}

struct IssuesSnapshot {
    var newestOpen: [IssueSummary]
    var oldestOpen: [IssueSummary]
    var averageAgeHours: Double
    var medianAgeHours: Double
    var oldestUnassignedCount: Int
    var newestUnassignedCount: Int
    var priorityBreakdownOldest: [String: Int]

    static let empty = IssuesSnapshot(
        newestOpen: [],
        oldestOpen: [],
        averageAgeHours: 0,
        medianAgeHours: 0,
        oldestUnassignedCount: 0,
        newestUnassignedCount: 0,
        priorityBreakdownOldest: [:]
    )
}

struct OverviewTrends {
    var closedTrend: Double?   // percent change vs previous period
    var newTrend: Double?
    var avgResolutionTrend: Double?

    static let empty = OverviewTrends()
}

struct OverviewSnapshot {
    var totalOpen: Int
    var totalClosedInPeriod: Int
    var newInPeriod: Int
    var avgResolutionHours: Double
    var medianResolutionHours: Double
    var slaBreachCount: Int
    var trends: OverviewTrends

    static let empty = OverviewSnapshot(
        totalOpen: 0,
        totalClosedInPeriod: 0,
        newInPeriod: 0,
        avgResolutionHours: 0,
        medianResolutionHours: 0,
        slaBreachCount: 0,
        trends: .empty
    )
}

struct TrendDataPoint: Identifiable {
    let id = UUID()
    var date: Date
    var createdCount: Int
    var resolvedCount: Int
}

struct PersonMetric: Identifiable {
    let id = UUID()
    var user: JIRAUser
    var assignedCount: Int
    var resolvedCount: Int
    var avgResolutionHours: Double
}

struct CategoryMetric: Identifiable {
    let id = UUID()
    var name: String
    var count: Int
    var percentOfTotal: Double
    var avgResolutionHours: Double
    var medianResolutionHours: Double
}

struct EndUserMetric: Identifiable {
    let id = UUID()
    var reporter: JIRAUser
    var ticketCount: Int
    var topCategories: [String]
}

struct PriorityMetric: Identifiable {
    let id = UUID()
    var priorityName: String
    var count: Int
    var percentOfTotal: Double
    var avgResolutionHours: Double
    var medianResolutionHours: Double
}

struct SLASnapshot: Identifiable {
    let id = UUID()
    var metricName: String
    var totalCycles: Int
    var breachedCount: Int
    var compliancePercent: Double
}
