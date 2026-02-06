import SwiftUI
import Charts

/// Simple counter for dynamic stagger indices when cards are conditionally included.
private class StaggerIndex {
    private var current = -1
    func next() -> Int {
        current += 1
        return current
    }
}

struct OpsCenterCombinedView: View {
    let dashboardVM: DashboardViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private func sectionEnabled(_ section: DashboardSection) -> Bool {
        UserSettings.isSectionEnabled(section)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                let idx = StaggerIndex()

                // MARK: - Trends

                if sectionEnabled(.trends) {
                    DashboardCard("Ticket Trends") {
                        if dashboardVM.snapshot.trends.isEmpty {
                            noDataView()
                        } else {
                            TrendLineChart(data: dashboardVM.snapshot.trends, showArea: true)
                                .frame(minHeight: 180)
                        }
                    }
                    .staggeredEntrance(index: idx.next())

                    DashboardCard("Created Volume") {
                        if dashboardVM.snapshot.trends.isEmpty {
                            noDataView()
                        } else {
                            Chart(dashboardVM.snapshot.trends) { point in
                                BarMark(
                                    x: .value("Date", point.date),
                                    y: .value("Created", point.createdCount)
                                )
                                .foregroundStyle(ColorPalette.statusNew.gradient)
                                .cornerRadius(3)
                                .annotation(position: .top) {
                                    if point.createdCount > 0 {
                                        Text("\(point.createdCount)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .chartYAxis { AxisMarks(position: .leading) }
                            .chartYAxisLabel("Tickets", position: .leading)
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                                    AxisGridLine()
                                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                }
                            }
                            .frame(minHeight: 180)
                        }
                    }
                    .staggeredEntrance(index: idx.next())

                    DashboardCard("Resolved Volume") {
                        if dashboardVM.snapshot.trends.isEmpty {
                            noDataView()
                        } else {
                            Chart(dashboardVM.snapshot.trends) { point in
                                BarMark(
                                    x: .value("Date", point.date),
                                    y: .value("Resolved", point.resolvedCount)
                                )
                                .foregroundStyle(ColorPalette.statusDone.gradient)
                                .cornerRadius(3)
                                .annotation(position: .top) {
                                    if point.resolvedCount > 0 {
                                        Text("\(point.resolvedCount)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .chartYAxis { AxisMarks(position: .leading) }
                            .chartYAxisLabel("Tickets", position: .leading)
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                                    AxisGridLine()
                                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                }
                            }
                            .frame(minHeight: 180)
                        }
                    }
                    .staggeredEntrance(index: idx.next())

                    DashboardCard("Net Flow") {
                        if dashboardVM.snapshot.trends.isEmpty {
                            noDataView()
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 12) {
                                    HStack(spacing: 4) {
                                        Circle().fill(ColorPalette.negative).frame(width: 8, height: 8)
                                        Text("Growing").font(.caption2).foregroundStyle(.secondary)
                                    }
                                    HStack(spacing: 4) {
                                        Circle().fill(ColorPalette.positive).frame(width: 8, height: 8)
                                        Text("Shrinking").font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                                Chart(dashboardVM.snapshot.trends) { point in
                                    let net = point.createdCount - point.resolvedCount
                                    BarMark(
                                        x: .value("Date", point.date),
                                        y: .value("Net", net)
                                    )
                                    .foregroundStyle(net > 0 ? ColorPalette.negative : ColorPalette.positive)
                                    .cornerRadius(3)
                                }
                                .chartYAxis { AxisMarks(position: .leading) }
                                .chartYAxisLabel("Net Tickets", position: .leading)
                                .chartXAxis {
                                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                                        AxisGridLine()
                                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                    }
                                }
                            }
                            .frame(minHeight: 165)
                        }
                    }
                    .staggeredEntrance(index: idx.next())

                    DashboardCard("Backlog Aging") {
                        if dashboardVM.snapshot.backlogAging.isEmpty {
                            noDataView()
                        } else {
                            Chart(dashboardVM.snapshot.backlogAging) { bucket in
                                BarMark(
                                    x: .value("Age", bucket.label),
                                    y: .value("Count", bucket.count)
                                )
                                .foregroundStyle(ColorPalette.agingColor(bucket.color))
                                .cornerRadius(4)
                                .annotation(position: .top) {
                                    if bucket.count > 0 {
                                        Text("\(bucket.count)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .chartYAxis { AxisMarks(position: .leading) }
                            .chartYAxisLabel("Tickets", position: .leading)
                            .frame(minHeight: 180)
                        }
                    }
                    .staggeredEntrance(index: idx.next())
                }

                // MARK: - By Person

                if sectionEnabled(.byPerson) {
                    DashboardCard("Top Assignees") {
                        if dashboardVM.snapshot.byPerson.isEmpty {
                            noDataView()
                        } else {
                            BarChartView(
                                items: dashboardVM.snapshot.byPerson.prefix(12).map { m in
                                    BarChartItem(label: m.user.name, value: Double(m.assignedCount), color: nil)
                                },
                                isHorizontal: true,
                                showValues: true
                            )
                            .frame(minHeight: 180)
                        }
                    }
                    .staggeredEntrance(index: idx.next())

                    DashboardCard("Assigned vs Resolved") {
                        if dashboardVM.snapshot.byPerson.isEmpty {
                            noDataView()
                        } else {
                            Chart(dashboardVM.snapshot.byPerson.prefix(10), id: \.id) { metric in
                                BarMark(
                                    x: .value("Person", metric.user.name),
                                    y: .value("Assigned", metric.assignedCount),
                                    stacking: .standard
                                )
                                .foregroundStyle(by: .value("Type", "Assigned"))

                                BarMark(
                                    x: .value("Person", metric.user.name),
                                    y: .value("Resolved", metric.resolvedCount),
                                    stacking: .standard
                                )
                                .foregroundStyle(by: .value("Type", "Resolved"))
                            }
                            .chartForegroundStyleScale([
                                "Assigned": ColorPalette.statusInProgress,
                                "Resolved": ColorPalette.statusDone
                            ])
                            .chartLegend(position: .top)
                            .chartYAxis { AxisMarks(position: .leading) }
                            .chartYAxisLabel("Tickets", position: .leading)
                            .frame(minHeight: 180)
                        }
                    }
                    .staggeredEntrance(index: idx.next())
                }

                // MARK: - Priority

                if sectionEnabled(.priority) {
                    DashboardCard("Priority Distribution") {
                        if dashboardVM.snapshot.byPriority.isEmpty {
                            noDataView()
                        } else {
                            DonutChartView(
                                items: dashboardVM.snapshot.byPriority.map { m in
                                    DonutChartItem(
                                        label: m.priorityName,
                                        value: Double(m.count),
                                        color: ColorPalette.priorityColor(m.priorityName)
                                    )
                                }
                            )
                            .frame(minHeight: 180)
                        }
                    }
                    .staggeredEntrance(index: idx.next())

                    DashboardCard("Open by Priority") {
                        if dashboardVM.snapshot.byPriority.isEmpty {
                            noDataView()
                        } else {
                            BarChartView(
                                items: dashboardVM.snapshot.byPriority.map { m in
                                    BarChartItem(
                                        label: m.priorityName,
                                        value: Double(m.count),
                                        color: ColorPalette.priorityColor(m.priorityName)
                                    )
                                },
                                showValues: true
                            )
                            .frame(minHeight: 180)
                        }
                    }
                    .staggeredEntrance(index: idx.next())

                    DashboardCard("Resolution by Priority") {
                        let metricsWithRes = dashboardVM.snapshot.byPriority.filter { $0.medianResolutionHours > 0 }
                        if metricsWithRes.isEmpty {
                            noDataView()
                        } else {
                            Chart(metricsWithRes) { metric in
                                BarMark(
                                    x: .value("Priority", metric.priorityName),
                                    y: .value("Median Hours", metric.medianResolutionHours)
                                )
                                .foregroundStyle(ColorPalette.priorityColor(metric.priorityName))
                                .cornerRadius(4)
                                .annotation(position: .top) {
                                    Text(DateFormatting.hoursString(from: metric.medianResolutionHours))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .chartYAxis { AxisMarks(position: .leading) }
                            .chartYAxisLabel("Hours (median)", position: .leading)
                            .frame(minHeight: 180)
                        }
                    }
                    .staggeredEntrance(index: idx.next())
                }

                // MARK: - By Category

                if sectionEnabled(.byCategory) {
                    DashboardCard("Categories") {
                        if dashboardVM.snapshot.byCategory.isEmpty {
                            noDataView()
                        } else {
                            DonutChartView(
                                items: dashboardVM.snapshot.byCategory.map { m in
                                    DonutChartItem(label: m.name, value: Double(m.count), color: nil)
                                }
                            )
                            .frame(minHeight: 180)
                        }
                    }
                    .staggeredEntrance(index: idx.next())

                    DashboardCard("Tickets by Category") {
                        if dashboardVM.snapshot.byCategory.isEmpty {
                            noDataView()
                        } else {
                            BarChartView(
                                items: dashboardVM.snapshot.byCategory.map { m in
                                    BarChartItem(label: m.name, value: Double(m.count), color: nil)
                                },
                                isHorizontal: true,
                                showValues: true
                            )
                            .frame(minHeight: 180)
                        }
                    }
                    .staggeredEntrance(index: idx.next())

                    DashboardCard("Resolution by Category") {
                        let metricsWithRes = dashboardVM.snapshot.byCategory.filter { $0.medianResolutionHours > 0 }
                        if metricsWithRes.isEmpty {
                            noDataView()
                        } else {
                            Chart(metricsWithRes) { metric in
                                BarMark(
                                    x: .value("Category", metric.name),
                                    y: .value("Median Hours", metric.medianResolutionHours)
                                )
                                .foregroundStyle(.purple.gradient)
                                .cornerRadius(4)
                                .annotation(position: .top) {
                                    Text(DateFormatting.hoursString(from: metric.medianResolutionHours))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .chartYAxis { AxisMarks(position: .leading) }
                            .chartYAxisLabel("Hours (median)", position: .leading)
                            .frame(minHeight: 180)
                        }
                    }
                    .staggeredEntrance(index: idx.next())
                }

                // MARK: - End Users

                if sectionEnabled(.endUsers) {
                    DashboardCard("Top Reporters") {
                        if dashboardVM.snapshot.byEndUser.isEmpty {
                            noDataView()
                        } else {
                            BarChartView(
                                items: dashboardVM.snapshot.byEndUser.prefix(12).map { m in
                                    BarChartItem(label: m.reporter.name, value: Double(m.ticketCount), color: nil)
                                },
                                isHorizontal: true,
                                showValues: true
                            )
                            .frame(minHeight: 180)
                        }
                    }
                    .staggeredEntrance(index: idx.next())
                }

                // MARK: - SLA

                if sectionEnabled(.sla) {
                    DashboardCard("SLA Compliance") {
                        if dashboardVM.snapshot.sla.isEmpty {
                            noDataView()
                        } else {
                            Chart(dashboardVM.snapshot.sla) { sla in
                                BarMark(
                                    x: .value("SLA", sla.metricName),
                                    y: .value("Compliance", sla.compliancePercent)
                                )
                                .foregroundStyle(
                                    sla.compliancePercent >= 95 ? Color.green :
                                    sla.compliancePercent >= 80 ? Color.orange : Color.red
                                )
                                .cornerRadius(4)
                                .annotation(position: .top) {
                                    Text(String(format: "%.0f%%", sla.compliancePercent))
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)
                                }

                                RuleMark(y: .value("Target", 95))
                                    .foregroundStyle(.red.opacity(0.5))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                                    .annotation(position: .trailing, alignment: .leading) {
                                        Text("95% target")
                                            .font(.caption2)
                                            .foregroundStyle(.red.opacity(0.7))
                                    }
                            }
                            .chartYScale(domain: 0...100)
                            .chartYAxisLabel("Compliance %", position: .leading)
                            .frame(minHeight: 180)
                        }
                    }
                    .staggeredEntrance(index: idx.next())

                    DashboardCard("SLA Breach Summary") {
                        if dashboardVM.snapshot.sla.isEmpty {
                            noDataView()
                        } else {
                            Table(dashboardVM.snapshot.sla) {
                                TableColumn("SLA Metric") { sla in
                                    Text(sla.metricName)
                                }

                                TableColumn("Total") { sla in
                                    Text("\(sla.totalCycles)")
                                        .monospacedDigit()
                                }
                                .width(ideal: 60)

                                TableColumn("Breached") { sla in
                                    Text("\(sla.breachedCount)")
                                        .monospacedDigit()
                                        .foregroundStyle(sla.breachedCount > 0 ? .red : .primary)
                                }
                                .width(ideal: 60)

                                TableColumn("Compliance") { sla in
                                    Text(String(format: "%.1f%%", sla.compliancePercent))
                                        .monospacedDigit()
                                }
                                .width(ideal: 80)
                            }
                            .frame(minHeight: 120)
                        }
                    }
                    .staggeredEntrance(index: idx.next())
                }

                // MARK: - Issues

                if sectionEnabled(.issues) {
                    let snap = dashboardVM.snapshot.issues

                    DashboardCard("Oldest Open Issues") {
                        if snap.oldestOpen.isEmpty {
                            noDataView()
                        } else {
                            issueCompactTable(snap.oldestOpen)
                                .frame(minHeight: 180)
                        }
                    }
                    .staggeredEntrance(index: idx.next())

                    DashboardCard("Newest Open Issues") {
                        if snap.newestOpen.isEmpty {
                            noDataView()
                        } else {
                            issueCompactTable(snap.newestOpen)
                                .frame(minHeight: 180)
                        }
                    }
                    .staggeredEntrance(index: idx.next())

                    DashboardCard("Issues Overview") {
                        if snap.oldestOpen.isEmpty && snap.newestOpen.isEmpty {
                            noDataView()
                        } else {
                            VStack(spacing: 12) {
                                HStack(spacing: 16) {
                                    miniKPI("Avg Age", DateFormatting.hoursString(from: snap.averageAgeHours), .orange)
                                    miniKPI("Median Age", DateFormatting.hoursString(from: snap.medianAgeHours), .purple)
                                    miniKPI("Unassigned (Old)", "\(snap.oldestUnassignedCount)", snap.oldestUnassignedCount > 0 ? .red : .green)
                                }
                                if !snap.priorityBreakdownOldest.isEmpty {
                                    BarChartView(
                                        items: snap.priorityBreakdownOldest.map { name, count in
                                            BarChartItem(
                                                label: name,
                                                value: Double(count),
                                                color: ColorPalette.priorityColor(name)
                                            )
                                        }.sorted(by: { $0.value > $1.value }),
                                        showValues: true
                                    )
                                }
                            }
                            .frame(minHeight: 180)
                        }
                    }
                    .staggeredEntrance(index: idx.next())
                }
            }
            .padding()
        }
    }

    // MARK: - Helpers

    private func noDataView() -> some View {
        Text("No data")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 180)
    }

    @ViewBuilder
    private func issueCompactTable(_ issues: [IssueSummary]) -> some View {
        Table(issues) {
            TableColumn("Key") { issue in
                Text(issue.key)
                    .fontWeight(.medium)
                    .monospacedDigit()
            }
            .width(ideal: 80)

            TableColumn("Summary") { issue in
                Text(issue.summary)
                    .lineLimit(1)
            }

            TableColumn("Priority") { issue in
                HStack(spacing: 4) {
                    Circle()
                        .fill(ColorPalette.priorityColor(issue.priorityName))
                        .frame(width: 6, height: 6)
                    Text(issue.priorityName)
                        .font(.caption)
                }
            }
            .width(ideal: 70)

            TableColumn("Age") { issue in
                Text(DateFormatting.hoursString(from: issue.ageHours))
                    .font(.caption)
                    .monospacedDigit()
            }
            .width(ideal: 60)
        }
    }

    private func miniKPI(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
