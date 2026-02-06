import SwiftUI
import Charts

struct ByCategoryDashboard: View {
    let viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            if viewModel.lastRefreshed != nil && viewModel.snapshot.byCategory.isEmpty {
                EmptyStateView(
                    icon: "tag",
                    title: "No Category Data",
                    message: "No categorized tickets found for the selected time period.",
                    suggestion: "Try selecting a different time period or service desk."
                )
                .frame(maxWidth: .infinity, minHeight: 400)
            } else {
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    DashboardCard("Issue Type Distribution") {
                        if viewModel.snapshot.byCategory.isEmpty {
                            ContentUnavailableView("No data", systemImage: "tag")
                                .frame(height: 250)
                        } else {
                            DonutChartView(
                                items: viewModel.snapshot.byCategory.map { metric in
                                    DonutChartItem(label: metric.name, value: Double(metric.count), color: nil)
                                }
                            )
                            .frame(height: 250)
                        }
                    }

                    DashboardCard("Tickets by Type") {
                        if viewModel.snapshot.byCategory.isEmpty {
                            ContentUnavailableView("No data", systemImage: "chart.bar")
                                .frame(height: 250)
                        } else {
                            BarChartView(
                                items: viewModel.snapshot.byCategory.map { metric in
                                    BarChartItem(label: metric.name, value: Double(metric.count), color: nil)
                                },
                                isHorizontal: true
                            )
                            .frame(height: 250)
                        }
                    }
                }
                .staggeredEntrance(index: 0)

                // Resolution Time by Category
                DashboardCard("Resolution Time by Category") {
                    let metricsWithRes = viewModel.snapshot.byCategory.filter { $0.medianResolutionHours > 0 }
                    if metricsWithRes.isEmpty {
                        ContentUnavailableView("No resolution data", systemImage: "clock")
                            .frame(height: 200)
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
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .chartYAxisLabel("Hours (median)", position: .leading)
                        .frame(height: 220)
                    }
                }
                .staggeredEntrance(index: 1)

                // Detail Table
                DashboardCard("Category Details") {
                    Table(viewModel.snapshot.byCategory) {
                        TableColumn("Category") { metric in
                            Text(metric.name)
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
        .navigationTitle("By Category")
    }
}
