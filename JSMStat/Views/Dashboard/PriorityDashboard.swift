import SwiftUI
import Charts

struct PriorityDashboard: View {
    let viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            if viewModel.lastRefreshed != nil && viewModel.snapshot.byPriority.isEmpty {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "No Priority Data",
                    message: "No tickets with priority information found for the selected time period.",
                    suggestion: "Try selecting a different time period or service desk."
                )
                .frame(maxWidth: .infinity, minHeight: 400)
            } else {
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    DashboardCard("Priority Distribution") {
                        if viewModel.snapshot.byPriority.isEmpty {
                            ContentUnavailableView("No data", systemImage: "exclamationmark.triangle")
                                .frame(height: 250)
                        } else {
                            DonutChartView(
                                items: viewModel.snapshot.byPriority.map { metric in
                                    DonutChartItem(
                                        label: metric.priorityName,
                                        value: Double(metric.count),
                                        color: ColorPalette.priorityColor(metric.priorityName)
                                    )
                                }
                            )
                            .frame(height: 250)
                        }
                    }

                    DashboardCard("Open Tickets by Priority") {
                        if viewModel.snapshot.byPriority.isEmpty {
                            ContentUnavailableView("No data", systemImage: "chart.bar")
                                .frame(height: 250)
                        } else {
                            BarChartView(
                                items: viewModel.snapshot.byPriority.map { metric in
                                    BarChartItem(
                                        label: metric.priorityName,
                                        value: Double(metric.count),
                                        color: ColorPalette.priorityColor(metric.priorityName)
                                    )
                                }
                            )
                            .frame(height: 250)
                        }
                    }
                }
                .staggeredEntrance(index: 0)

                // Resolution Time by Priority
                DashboardCard("Resolution Time by Priority") {
                    let metricsWithRes = viewModel.snapshot.byPriority.filter { $0.medianResolutionHours > 0 }
                    if metricsWithRes.isEmpty {
                        ContentUnavailableView("No resolution data", systemImage: "clock")
                            .frame(height: 200)
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
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .chartYAxisLabel("Hours (median)", position: .leading)
                        .frame(height: 220)
                    }
                }
                .staggeredEntrance(index: 1)

                DashboardCard("Priority Breakdown") {
                    Table(viewModel.snapshot.byPriority) {
                        TableColumn("Priority") { metric in
                            HStack {
                                Circle()
                                    .fill(ColorPalette.priorityColor(metric.priorityName))
                                    .frame(width: 10, height: 10)
                                Text(metric.priorityName)
                            }
                        }

                        TableColumn("Count") { metric in
                            Text("\(metric.count)")
                                .monospacedDigit()
                        }
                        .width(ideal: 80)

                        TableColumn("% of Total") { metric in
                            HStack {
                                Text(String(format: "%.1f%%", metric.percentOfTotal))
                                    .monospacedDigit()
                                Spacer()
                                ProgressView(value: metric.percentOfTotal, total: 100)
                                    .frame(width: 60)
                            }
                        }
                        .width(ideal: 150)

                        TableColumn("Med. Resolution") { metric in
                            Text(metric.medianResolutionHours > 0 ? DateFormatting.hoursString(from: metric.medianResolutionHours) : "–")
                                .monospacedDigit()
                        }
                        .width(ideal: 100)

                        TableColumn("Avg Resolution") { metric in
                            Text(metric.avgResolutionHours > 0 ? DateFormatting.hoursString(from: metric.avgResolutionHours) : "–")
                                .monospacedDigit()
                        }
                        .width(ideal: 100)
                    }
                    .frame(minHeight: 200)
                }
                .staggeredEntrance(index: 2)
            }
            .padding()
            }
        }
        .navigationTitle("Priority")
    }

}
