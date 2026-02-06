import SwiftUI
import Charts

struct OverviewDashboard: View {
    let viewModel: DashboardViewModel

    private var overview: OverviewSnapshot { viewModel.snapshot.overview }

    private var hasData: Bool {
        overview.totalOpen > 0 || overview.totalClosedInPeriod > 0 || overview.newInPeriod > 0
    }

    private func trendBadge(from percentChange: Double?) -> KPITrend? {
        guard let pct = percentChange else { return nil }
        let label = String(format: "%.0f%%", abs(pct))
        if pct > 1 { return .up(label) }
        if pct < -1 { return .down(label) }
        return .neutral(label)
    }

    var body: some View {
        ScrollView {
            if viewModel.lastRefreshed != nil && !hasData {
                EmptyStateView(
                    icon: "chart.bar.doc.horizontal",
                    title: "No Tickets Found",
                    message: "There are no tickets for the selected service desk and time period.",
                    suggestion: "Try selecting a different time period or service desk."
                )
                .frame(maxWidth: .infinity, minHeight: 400)
            } else {
                VStack(spacing: 20) {
                    // KPI Cards Row
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 5), spacing: 16) {
                        KPICard(
                            title: "Open Tickets",
                            value: "\(overview.totalOpen)",
                            invertTrend: true,
                            color: ColorPalette.statusInProgress
                        )
                        .staggeredEntrance(index: 0)

                        KPICard(
                            title: "Closed This Period",
                            value: "\(overview.totalClosedInPeriod)",
                            trend: trendBadge(from: overview.trends.closedTrend),
                            color: ColorPalette.statusDone
                        )
                        .staggeredEntrance(index: 1)

                        KPICard(
                            title: "New This Period",
                            value: "\(overview.newInPeriod)",
                            trend: trendBadge(from: overview.trends.newTrend),
                            invertTrend: true,
                            color: ColorPalette.statusNew
                        )
                        .staggeredEntrance(index: 2)

                        KPICard(
                            title: "Median Resolution",
                            value: DateFormatting.hoursString(from: overview.medianResolutionHours),
                            subtitle: "avg \(DateFormatting.hoursString(from: overview.avgResolutionHours))",
                            trend: trendBadge(from: overview.trends.avgResolutionTrend),
                            invertTrend: true,
                            color: .purple
                        )
                        .staggeredEntrance(index: 3)

                        KPICard(
                            title: "SLA Breaches",
                            value: "\(overview.slaBreachCount)",
                            invertTrend: true,
                            color: overview.slaBreachCount > 0 ? ColorPalette.slaBreached : ColorPalette.slaOnTrack
                        )
                        .staggeredEntrance(index: 4)
                    }

                    // Trend Sparkline
                    DashboardCard("Ticket Trends") {
                        if viewModel.snapshot.trends.isEmpty {
                            ContentUnavailableView("No trend data", systemImage: "chart.xyaxis.line")
                                .frame(height: 200)
                        } else {
                            TrendLineChart(data: viewModel.snapshot.trends)
                                .frame(height: 250)
                        }
                    }
                    .staggeredEntrance(index: 5)

                    // Backlog Aging
                    if !viewModel.snapshot.backlogAging.isEmpty {
                        DashboardCard("Backlog Aging") {
                            Chart(viewModel.snapshot.backlogAging) { bucket in
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
                            .chartXAxis {
                                AxisMarks { _ in
                                    AxisValueLabel()
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .chartYAxisLabel("Tickets", position: .leading)
                            .frame(height: 180)
                        }
                        .staggeredEntrance(index: 6)
                    }

                    // Summary Row
                    HStack(spacing: 16) {
                        DashboardCard("Priority Distribution") {
                            if viewModel.snapshot.byPriority.isEmpty {
                                ContentUnavailableView("No data", systemImage: "chart.pie")
                                    .frame(height: 200)
                            } else {
                                DonutChartView(
                                    items: viewModel.snapshot.byPriority.map { metric in
                                        DonutChartItem(label: metric.priorityName, value: Double(metric.count), color: nil)
                                    }
                                )
                                .frame(height: 200)
                            }
                        }

                        DashboardCard("Top 5 Assignees") {
                            if viewModel.snapshot.byPerson.isEmpty {
                                ContentUnavailableView("No data", systemImage: "person.2")
                                    .frame(height: 200)
                            } else {
                                BarChartView(
                                    items: viewModel.snapshot.byPerson.prefix(5).map { metric in
                                        BarChartItem(label: metric.user.name, value: Double(metric.assignedCount), color: nil)
                                    },
                                    isHorizontal: true
                                )
                                .frame(height: 200)
                            }
                        }
                    }
                    .staggeredEntrance(index: 7)
                }
                .padding()
            }
        }
        .navigationTitle("Overview")
    }

}
