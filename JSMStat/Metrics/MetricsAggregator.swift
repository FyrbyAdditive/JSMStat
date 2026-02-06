import Foundation

enum MetricsAggregator {
    static func groupByDate(issues: [Issue], period: TimePeriod, dateKeyPath: KeyPath<IssueFields, Date?>) -> [Date: Int] {
        let calendar = Calendar.current
        var grouped: [Date: Int] = [:]

        for issue in issues {
            guard let date = issue.fields[keyPath: dateKeyPath] else { continue }
            let truncated: Date
            switch period.granularity {
            case .hour:
                guard let d = calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour], from: date)) else { continue }
                truncated = d
            case .weekOfYear:
                guard let d = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) else { continue }
                truncated = d
            default:
                truncated = calendar.startOfDay(for: date)
            }
            grouped[truncated, default: 0] += 1
        }

        return grouped
    }

    static func buildTrends(created: [Issue], resolved: [Issue], period: TimePeriod) -> [TrendDataPoint] {
        let createdByDate = groupByDate(issues: created, period: period, dateKeyPath: \.createdDate)
        let resolvedByDate = groupByDate(issues: resolved, period: period, dateKeyPath: \.resolvedDate)

        let allDates = Set(createdByDate.keys).union(resolvedByDate.keys).sorted()

        return allDates.map { date in
            TrendDataPoint(
                date: date,
                createdCount: createdByDate[date] ?? 0,
                resolvedCount: resolvedByDate[date] ?? 0
            )
        }
    }

    static func groupByAssignee(issues: [Issue], allIssues: [Issue]) -> [PersonMetric] {
        var assignedCounts: [String: (user: JIRAUser, assigned: Int, resolved: Int, totalResHours: Double, resCount: Int)] = [:]

        for issue in allIssues {
            guard let assignee = issue.fields.assignee else { continue }
            let key = assignee.accountId
            var entry = assignedCounts[key] ?? (user: assignee, assigned: 0, resolved: 0, totalResHours: 0, resCount: 0)
            entry.assigned += 1

            if issue.fields.status?.categoryKey == "done" {
                entry.resolved += 1
                if let hours = issue.fields.resolutionTimeHours {
                    entry.totalResHours += hours
                    entry.resCount += 1
                }
            }

            assignedCounts[key] = entry
        }

        return assignedCounts.values.map { entry in
            PersonMetric(
                user: entry.user,
                assignedCount: entry.assigned,
                resolvedCount: entry.resolved,
                avgResolutionHours: entry.resCount > 0 ? entry.totalResHours / Double(entry.resCount) : 0
            )
        }.sorted { $0.assignedCount > $1.assignedCount }
    }

    static func groupByIssueType(issues: [Issue], closedIssues: [Issue] = []) -> [CategoryMetric] {
        var counts: [String: Int] = [:]
        var resTimes: [String: [Double]] = [:]

        for issue in issues {
            let name = issue.fields.issuetype?.name ?? "Unknown"
            counts[name, default: 0] += 1
        }

        for issue in closedIssues {
            let name = issue.fields.issuetype?.name ?? "Unknown"
            if let hours = issue.fields.resolutionTimeHours {
                resTimes[name, default: []].append(hours)
            }
        }

        let total = max(issues.count, 1)
        return counts.map { name, count in
            let times = resTimes[name] ?? []
            let avg = times.isEmpty ? 0 : times.reduce(0, +) / Double(times.count)
            return CategoryMetric(
                name: name,
                count: count,
                percentOfTotal: Double(count) / Double(total) * 100,
                avgResolutionHours: avg,
                medianResolutionHours: median(times)
            )
        }.sorted { $0.count > $1.count }
    }

    static func groupByReporter(issues: [Issue]) -> [EndUserMetric] {
        var grouped: [String: (user: JIRAUser, count: Int, categories: [String: Int])] = [:]

        for issue in issues {
            guard let reporter = issue.fields.reporter else { continue }
            let key = reporter.accountId
            var entry = grouped[key] ?? (user: reporter, count: 0, categories: [:])
            entry.count += 1
            let category = issue.fields.issuetype?.name ?? "Unknown"
            entry.categories[category, default: 0] += 1
            grouped[key] = entry
        }

        return grouped.values.map { entry in
            let topCats = entry.categories.sorted { $0.value > $1.value }.prefix(3).map(\.key)
            return EndUserMetric(
                reporter: entry.user,
                ticketCount: entry.count,
                topCategories: topCats
            )
        }.sorted { $0.ticketCount > $1.ticketCount }
    }

    static func groupByPriority(issues: [Issue], closedIssues: [Issue] = []) -> [PriorityMetric] {
        var counts: [String: Int] = [:]
        var resTimes: [String: [Double]] = [:]

        for issue in issues {
            let name = issue.fields.priority?.name ?? "None"
            counts[name, default: 0] += 1
        }

        for issue in closedIssues {
            let name = issue.fields.priority?.name ?? "None"
            if let hours = issue.fields.resolutionTimeHours {
                resTimes[name, default: []].append(hours)
            }
        }

        let total = max(issues.count, 1)
        return counts.map { name, count in
            let times = resTimes[name] ?? []
            let avg = times.isEmpty ? 0 : times.reduce(0, +) / Double(times.count)
            return PriorityMetric(
                priorityName: name,
                count: count,
                percentOfTotal: Double(count) / Double(total) * 100,
                avgResolutionHours: avg,
                medianResolutionHours: median(times)
            )
        }.sorted { $0.count > $1.count }
    }

    static func median(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let count = sorted.count
        if count.isMultiple(of: 2) {
            return (sorted[count / 2 - 1] + sorted[count / 2]) / 2.0
        } else {
            return sorted[count / 2]
        }
    }

    static func computeBacklogAging(openIssues: [Issue]) -> [AgingBucket] {
        let now = Date()
        var buckets: [(label: String, color: String, maxDays: Double)] = [
            ("< 1 day", "green", 1),
            ("1–3 days", "mint", 3),
            ("3–7 days", "yellow", 7),
            ("1–2 weeks", "orange", 14),
            ("2–4 weeks", "red", 28),
            ("> 4 weeks", "purple", .infinity)
        ]

        var counts = Array(repeating: 0, count: buckets.count)

        for issue in openIssues {
            guard let created = issue.fields.createdDate else { continue }
            let ageDays = now.timeIntervalSince(created) / 86400.0

            for (index, bucket) in buckets.enumerated() {
                let minDays: Double = index == 0 ? 0 : buckets[index - 1].maxDays
                if ageDays >= minDays && ageDays < bucket.maxDays {
                    counts[index] += 1
                    break
                }
            }
        }

        return zip(buckets, counts).map { bucket, count in
            AgingBucket(label: bucket.label, count: count, color: bucket.color)
        }
    }

    static func percentChange(current: Int, previous: Int) -> Double? {
        guard previous > 0 else { return current > 0 ? 100 : nil }
        return Double(current - previous) / Double(previous) * 100
    }

    static func percentChange(current: Double, previous: Double) -> Double? {
        guard previous > 0 else { return current > 0 ? 100 : nil }
        return (current - previous) / previous * 100
    }

    static func computeIssuesSnapshot(openIssues: [Issue]) -> IssuesSnapshot {
        let now = Date()

        let summaries: [IssueSummary] = openIssues.compactMap { issue in
            guard let created = issue.fields.createdDate else { return nil }
            let ageHours = now.timeIntervalSince(created) / 3600.0
            return IssueSummary(
                id: issue.key,
                key: issue.key,
                summary: issue.fields.summary ?? "(No summary)",
                priorityName: issue.fields.priority?.name ?? "None",
                statusName: issue.fields.status?.name ?? "Unknown",
                assigneeName: issue.fields.assignee?.name,
                ageHours: ageHours,
                createdDate: created
            )
        }

        let sortedAscending = summaries.sorted { $0.createdDate < $1.createdDate }
        let oldest10 = Array(sortedAscending.prefix(10))
        let newest10 = Array(sortedAscending.suffix(10).reversed())

        let allAges = summaries.map(\.ageHours)
        let avgAge = allAges.isEmpty ? 0 : allAges.reduce(0, +) / Double(allAges.count)
        let medAge = median(allAges)

        let oldestUnassigned = oldest10.filter { $0.assigneeName == nil }.count
        let newestUnassigned = newest10.filter { $0.assigneeName == nil }.count

        var priorityBreakdown: [String: Int] = [:]
        for issue in oldest10 {
            priorityBreakdown[issue.priorityName, default: 0] += 1
        }

        return IssuesSnapshot(
            newestOpen: newest10,
            oldestOpen: oldest10,
            averageAgeHours: avgAge,
            medianAgeHours: medAge,
            oldestUnassignedCount: oldestUnassigned,
            newestUnassignedCount: newestUnassigned,
            priorityBreakdownOldest: priorityBreakdown
        )
    }

    static func computeOverview(
        open: [Issue],
        closedInPeriod: [Issue],
        createdInPeriod: [Issue],
        slaBreaches: Int,
        previousClosed: [Issue]? = nil,
        previousCreated: [Issue]? = nil
    ) -> OverviewSnapshot {
        let resolutionTimes = closedInPeriod.compactMap { $0.fields.resolutionTimeHours }
        let avgResolution = resolutionTimes.isEmpty ? 0 : resolutionTimes.reduce(0, +) / Double(resolutionTimes.count)
        let medianResolution = median(resolutionTimes)

        var trends = OverviewTrends.empty
        if let prevClosed = previousClosed, let prevCreated = previousCreated {
            trends.closedTrend = percentChange(current: closedInPeriod.count, previous: prevClosed.count)
            trends.newTrend = percentChange(current: createdInPeriod.count, previous: prevCreated.count)
            let prevResTimes = prevClosed.compactMap { $0.fields.resolutionTimeHours }
            let prevAvg = prevResTimes.isEmpty ? 0 : prevResTimes.reduce(0, +) / Double(prevResTimes.count)
            trends.avgResolutionTrend = percentChange(current: avgResolution, previous: prevAvg)
        }

        return OverviewSnapshot(
            totalOpen: open.count,
            totalClosedInPeriod: closedInPeriod.count,
            newInPeriod: createdInPeriod.count,
            avgResolutionHours: avgResolution,
            medianResolutionHours: medianResolution,
            slaBreachCount: slaBreaches,
            trends: trends
        )
    }
}
