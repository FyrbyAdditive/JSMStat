import SwiftUI
import Charts

struct EndUserDashboard: View {
    let viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            if viewModel.lastRefreshed != nil && viewModel.snapshot.byEndUser.isEmpty {
                EmptyStateView(
                    icon: "person.crop.circle",
                    title: "No End User Data",
                    message: "No tickets with reporter information found for the selected time period.",
                    suggestion: "Try selecting a longer time period."
                )
                .frame(maxWidth: .infinity, minHeight: 400)
            } else {
            VStack(spacing: 20) {
                DashboardCard("Tickets Logged by End User") {
                    if viewModel.snapshot.byEndUser.isEmpty {
                        ContentUnavailableView(
                            "No reporter data",
                            systemImage: "person.crop.circle",
                            description: Text("End user ticket data will appear here.")
                        )
                        .frame(height: 300)
                    } else {
                        BarChartView(
                            items: viewModel.snapshot.byEndUser.prefix(20).map { metric in
                                BarChartItem(label: metric.reporter.name, value: Double(metric.ticketCount), color: nil)
                            },
                            isHorizontal: true
                        )
                        .frame(height: max(200, CGFloat(min(viewModel.snapshot.byEndUser.count, 20)) * 28))
                    }
                }
                .staggeredEntrance(index: 0)

                DashboardCard("End User Detail") {
                    Table(viewModel.snapshot.byEndUser) {
                        TableColumn("Reporter") { metric in
                            Text(metric.reporter.name)
                        }
                        .width(min: 120)

                        TableColumn("Tickets") { metric in
                            Text("\(metric.ticketCount)")
                                .monospacedDigit()
                        }
                        .width(ideal: 80)

                        TableColumn("Top Categories") { metric in
                            Text(metric.topCategories.joined(separator: ", "))
                                .lineLimit(1)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(minHeight: 250)
                }
                .staggeredEntrance(index: 1)
            }
            .padding()
            }
        }
        .navigationTitle("End Users")
    }
}
