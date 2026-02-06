import SwiftUI
import Charts

struct OpsCenterRotatingView: View {
    let viewModel: OpsCenterViewModel
    let dashboardVM: DashboardViewModel

    var body: some View {
        VStack {
            // Panel indicator
            HStack(spacing: 8) {
                ForEach(viewModel.panels) { panel in
                    Capsule()
                        .fill(panel == viewModel.currentPanel ? Color.white : Color.white.opacity(0.3))
                        .frame(width: panel == viewModel.currentPanel ? 24 : 8, height: 4)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentPanel)
                }
            }
            .padding(.top, 12)

            // Panel content with crossfade
            ZStack {
                ForEach(viewModel.panels) { panel in
                    panelContent(for: panel)
                        .opacity(panel == viewModel.currentPanel ? 1 : 0)
                        .animation(.easeInOut(duration: 0.8), value: viewModel.currentPanel)
                }
            }
        }
        .padding()
    }

    // MARK: - Panel Content

    @ViewBuilder
    private func panelContent(for panel: OpsCenterPanel) -> some View {
        switch panel {
        case .trends:
            trendsPanel()
        case .byPerson:
            byPersonPanel()
        case .byCategory:
            byCategoryPanel()
        case .priority:
            priorityPanel()
        case .sla:
            slaPanel()
        case .endUsers:
            endUsersPanel()
        case .issues:
            issuesPanel()
        }
    }

    // MARK: - Panel 1: Trends

    private func trendsPanel() -> some View {
        opsPanel("Ticket Trends") {
            VStack(spacing: 12) {
                // Main trend line (top ~60%)
                DashboardCard("Created vs Resolved") {
                    if dashboardVM.snapshot.trends.isEmpty {
                        noDataView()
                    } else {
                        TrendLineChart(data: dashboardVM.snapshot.trends, showArea: true)
                            .frame(maxHeight: .infinity)
                    }
                }

                // Bottom row: Net Flow + Backlog Aging
                HStack(spacing: 12) {
                    DashboardCard("Net Flow") {
                        if dashboardVM.snapshot.trends.isEmpty {
                            noDataView()
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 12) {
                                    HStack(spacing: 4) {
                                        Circle().fill(ColorPalette.negative).frame(width: 8, height: 8)
                                        Text("Growing").font(.caption).foregroundStyle(.secondary)
                                    }
                                    HStack(spacing: 4) {
                                        Circle().fill(ColorPalette.positive).frame(width: 8, height: 8)
                                        Text("Shrinking").font(.caption).foregroundStyle(.secondary)
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
                                .chartXAxis {
                                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                                        AxisGridLine()
                                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                    }
                                }
                            }
                        }
                    }

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
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .chartYAxis { AxisMarks(position: .leading) }
                            .chartYAxisLabel("Tickets", position: .leading)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Panel 2: By Person

    private func byPersonPanel() -> some View {
        opsPanel("By Person") {
            HStack(spacing: 12) {
                DashboardCard("Tickets by Assignee") {
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
                    }
                }

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
                    }
                }
            }
        }
    }

    // MARK: - Panel 3: By Category

    private func byCategoryPanel() -> some View {
        opsPanel("By Category") {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    DashboardCard("Issue Type Distribution") {
                        if dashboardVM.snapshot.byCategory.isEmpty {
                            noDataView()
                        } else {
                            DonutChartView(
                                items: dashboardVM.snapshot.byCategory.map { m in
                                    DonutChartItem(label: m.name, value: Double(m.count), color: nil)
                                }
                            )
                        }
                    }

                    DashboardCard("Tickets by Type") {
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
                        }
                    }
                }

                DashboardCard("Resolution Time by Category") {
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
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .chartYAxis { AxisMarks(position: .leading) }
                        .chartYAxisLabel("Hours (median)", position: .leading)
                    }
                }
            }
        }
    }

    // MARK: - Panel 4: Priority

    private func priorityPanel() -> some View {
        opsPanel("Priority Distribution") {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    DashboardCard("By Priority") {
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
                        }
                    }

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
                        }
                    }
                }

                DashboardCard("Resolution Time by Priority") {
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
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .chartYAxis { AxisMarks(position: .leading) }
                        .chartYAxisLabel("Hours (median)", position: .leading)
                    }
                }
            }
        }
    }

    // MARK: - Panel 5: SLA

    private func slaPanel() -> some View {
        opsPanel("SLA Compliance") {
            VStack(spacing: 12) {
                // Compact SLA KPI row
                if !dashboardVM.snapshot.sla.isEmpty {
                    HStack(spacing: 12) {
                        ForEach(dashboardVM.snapshot.sla) { sla in
                            VStack(spacing: 4) {
                                Text(String(format: "%.0f%%", sla.compliancePercent))
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        sla.compliancePercent >= 95 ? Color.green :
                                        sla.compliancePercent >= 80 ? Color.orange : Color.red
                                    )
                                Text(sla.metricName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                Text("\(sla.breachedCount) breached")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }

                // SLA bar chart with 95% target line
                DashboardCard("Compliance Overview") {
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
                                    .font(.caption)
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
                    }
                }
            }
        }
    }

    // MARK: - Panel 6: End Users

    private func endUsersPanel() -> some View {
        opsPanel("End Users") {
            HStack(spacing: 12) {
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
                    }
                }

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
                            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Panel 7: Issues

    private func issuesPanel() -> some View {
        opsPanel("Open Issues") {
            let snap = dashboardVM.snapshot.issues
            if snap.oldestOpen.isEmpty && snap.newestOpen.isEmpty {
                noDataView()
            } else {
                HStack(spacing: 12) {
                    DashboardCard("Top 10 Oldest Open") {
                        if snap.oldestOpen.isEmpty {
                            noDataView()
                        } else {
                            issueCompactTable(snap.oldestOpen)
                        }
                    }

                    VStack(spacing: 12) {
                        DashboardCard("Top 10 Newest Open") {
                            if snap.newestOpen.isEmpty {
                                noDataView()
                            } else {
                                issueCompactTable(snap.newestOpen)
                            }
                        }

                        DashboardCard("Priority Breakdown (Oldest 10)") {
                            if snap.priorityBreakdownOldest.isEmpty {
                                noDataView()
                            } else {
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
                    }
                }
            }
        }
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

            TableColumn("Assignee") { issue in
                Text(issue.assigneeName ?? "Unassigned")
                    .font(.caption)
                    .foregroundStyle(issue.assigneeName == nil ? .red : .primary)
            }
            .width(ideal: 90)

            TableColumn("Age") { issue in
                Text(DateFormatting.hoursString(from: issue.ageHours))
                    .font(.caption)
                    .monospacedDigit()
            }
            .width(ideal: 60)
        }
        .frame(minHeight: 200)
    }

    // MARK: - Helpers

    private func opsPanel<Content: View>(_ title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 28, weight: .semibold, design: .default))
                .foregroundStyle(.white.opacity(0.9))

            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func noDataView() -> some View {
        Text("No data")
            .foregroundStyle(.white.opacity(0.4))
            .frame(maxWidth: .infinity, minHeight: 120)
    }
}
