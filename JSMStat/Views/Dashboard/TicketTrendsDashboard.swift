import SwiftUI
import Charts

struct TicketTrendsDashboard: View {
    let viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            if viewModel.lastRefreshed != nil && viewModel.snapshot.trends.isEmpty {
                EmptyStateView(
                    icon: "chart.xyaxis.line",
                    title: "No Trend Data",
                    message: "No ticket activity found for the selected time period.",
                    suggestion: "Try selecting a longer time period to see trends."
                )
                .frame(maxWidth: .infinity, minHeight: 400)
            } else {
            VStack(spacing: 20) {
                DashboardCard("Created vs Resolved Over Time") {
                    if viewModel.snapshot.trends.isEmpty {
                        ContentUnavailableView(
                            "No trend data available",
                            systemImage: "chart.xyaxis.line",
                            description: Text("Ticket data will appear here once data is loaded.")
                        )
                        .frame(height: 300)
                    } else {
                        TrendLineChart(data: viewModel.snapshot.trends, showArea: true)
                            .frame(height: 350)
                    }
                }
                .staggeredEntrance(index: 0)

                HStack(spacing: 16) {
                    DashboardCard("Created Volume") {
                        Chart(viewModel.snapshot.trends) { point in
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
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .chartYAxisLabel("Tickets", position: .leading)
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            }
                        }
                        .frame(height: 200)
                    }

                    DashboardCard("Resolved Volume") {
                        Chart(viewModel.snapshot.trends) { point in
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
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .chartYAxisLabel("Tickets", position: .leading)
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            }
                        }
                        .frame(height: 200)
                    }
                }
                .staggeredEntrance(index: 1)

                // Net flow
                DashboardCard("Net Flow (Created - Resolved)") {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Circle().fill(ColorPalette.negative).frame(width: 8, height: 8)
                                Text("Growing backlog")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            HStack(spacing: 4) {
                                Circle().fill(ColorPalette.positive).frame(width: 8, height: 8)
                                Text("Shrinking backlog")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Chart(viewModel.snapshot.trends) { point in
                            let net = point.createdCount - point.resolvedCount
                            BarMark(
                                x: .value("Date", point.date),
                                y: .value("Net", net)
                            )
                            .foregroundStyle(net > 0 ? ColorPalette.negative : ColorPalette.positive)
                            .cornerRadius(3)
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .chartYAxisLabel("Net Tickets", position: .leading)
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            }
                        }
                        .frame(height: 185)
                    }
                }
                .staggeredEntrance(index: 2)
            }
            .padding()
            }
        }
        .navigationTitle("Ticket Trends")
    }
}
