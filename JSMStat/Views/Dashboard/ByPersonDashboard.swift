import SwiftUI
import Charts

struct ByPersonDashboard: View {
    let viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            if viewModel.lastRefreshed != nil && viewModel.snapshot.byPerson.isEmpty {
                EmptyStateView(
                    icon: "person.2",
                    title: "No Assignee Data",
                    message: "No assigned tickets found for the selected service desk and time period.",
                    suggestion: "Tickets may be unassigned, or try a different time period."
                )
                .frame(maxWidth: .infinity, minHeight: 400)
            } else {
            VStack(spacing: 20) {
                DashboardCard("Tickets by Assignee") {
                    if viewModel.snapshot.byPerson.isEmpty {
                        ContentUnavailableView(
                            "No assignee data",
                            systemImage: "person.2",
                            description: Text("Assigned ticket data will appear here.")
                        )
                        .frame(height: 300)
                    } else {
                        BarChartView(
                            items: viewModel.snapshot.byPerson.prefix(15).map { metric in
                                BarChartItem(label: metric.user.name, value: Double(metric.assignedCount), color: nil)
                            },
                            isHorizontal: true
                        )
                        .frame(height: max(200, CGFloat(min(viewModel.snapshot.byPerson.count, 15)) * 30))
                    }
                }
                .staggeredEntrance(index: 0)

                DashboardCard("Resolved by Assignee") {
                    if viewModel.snapshot.byPerson.isEmpty {
                        ContentUnavailableView("No data", systemImage: "checkmark.circle")
                            .frame(height: 200)
                    } else {
                        Chart(viewModel.snapshot.byPerson.prefix(10), id: \.id) { metric in
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
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .chartYAxisLabel("Tickets", position: .leading)
                        .frame(height: 250)
                    }
                }
                .staggeredEntrance(index: 1)

                // Detail Table
                DashboardCard("Detail") {
                    Table(viewModel.snapshot.byPerson) {
                        TableColumn("Assignee") { metric in
                            Text(metric.user.name)
                        }
                        .width(min: 120)

                        TableColumn("Assigned") { metric in
                            Text("\(metric.assignedCount)")
                                .monospacedDigit()
                        }
                        .width(ideal: 80)

                        TableColumn("Resolved") { metric in
                            Text("\(metric.resolvedCount)")
                                .monospacedDigit()
                        }
                        .width(ideal: 80)

                        TableColumn("Avg Resolution") { metric in
                            Text(DateFormatting.hoursString(from: metric.avgResolutionHours))
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
        .navigationTitle("By Person")
    }
}
