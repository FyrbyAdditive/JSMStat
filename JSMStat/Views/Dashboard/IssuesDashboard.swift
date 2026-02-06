import SwiftUI
import Charts

struct IssuesDashboard: View {
    let viewModel: DashboardViewModel

    private var snap: IssuesSnapshot { viewModel.snapshot.issues }

    var body: some View {
        ScrollView {
            if viewModel.lastRefreshed != nil && snap.oldestOpen.isEmpty && snap.newestOpen.isEmpty {
                EmptyStateView(
                    icon: "list.bullet.rectangle",
                    title: "No Open Issues",
                    message: "No open issues found for the selected service desk.",
                    suggestion: "Try selecting a different service desk or time period."
                )
                .frame(maxWidth: .infinity, minHeight: 400)
            } else {
                VStack(spacing: DesignTokens.sectionSpacing) {
                    // KPI Row
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                        KPICard(
                            title: "Average Age",
                            value: DateFormatting.hoursString(from: snap.averageAgeHours),
                            color: .orange
                        )
                        .staggeredEntrance(index: 0)

                        KPICard(
                            title: "Median Age",
                            value: DateFormatting.hoursString(from: snap.medianAgeHours),
                            color: .purple
                        )
                        .staggeredEntrance(index: 1)

                        KPICard(
                            title: "Oldest Unassigned",
                            value: "\(snap.oldestUnassignedCount)/\(snap.oldestOpen.count)",
                            color: snap.oldestUnassignedCount > 0 ? .red : .green
                        )
                        .staggeredEntrance(index: 2)

                        KPICard(
                            title: "Newest Unassigned",
                            value: "\(snap.newestUnassignedCount)/\(snap.newestOpen.count)",
                            color: snap.newestUnassignedCount > 0 ? .orange : .green
                        )
                        .staggeredEntrance(index: 3)
                    }

                    // Newest Open Issues
                    DashboardCard("Top 10 Newest Open Issues") {
                        if snap.newestOpen.isEmpty {
                            ContentUnavailableView("No data", systemImage: "list.bullet")
                                .frame(height: 250)
                        } else {
                            issueTable(snap.newestOpen)
                        }
                    }
                    .staggeredEntrance(index: 4)

                    // Oldest Open Issues
                    DashboardCard("Top 10 Oldest Open Issues") {
                        if snap.oldestOpen.isEmpty {
                            ContentUnavailableView("No data", systemImage: "list.bullet")
                                .frame(height: 250)
                        } else {
                            issueTable(snap.oldestOpen)
                        }
                    }
                    .staggeredEntrance(index: 5)


                }
                .padding()
            }
        }
        .navigationTitle("Issues")
    }

    @ViewBuilder
    private func issueTable(_ issues: [IssueSummary]) -> some View {
        Table(issues) {
            TableColumn("Key") { issue in
                Text(issue.key)
                    .fontWeight(.medium)
                    .monospacedDigit()
            }
            .width(ideal: 90)

            TableColumn("Summary") { issue in
                Text(issue.summary)
                    .lineLimit(1)
            }

            TableColumn("Priority") { issue in
                HStack(spacing: 6) {
                    Circle()
                        .fill(ColorPalette.priorityColor(issue.priorityName))
                        .frame(width: 8, height: 8)
                    Text(issue.priorityName)
                }
            }
            .width(ideal: 90)

            TableColumn("Status") { issue in
                Text(issue.statusName)
            }
            .width(ideal: 100)

            TableColumn("Assignee") { issue in
                Text(issue.assigneeName ?? "Unassigned")
                    .foregroundStyle(issue.assigneeName == nil ? .red : .primary)
            }
            .width(ideal: 120)

            TableColumn("Age") { issue in
                Text(DateFormatting.hoursString(from: issue.ageHours))
                    .monospacedDigit()
            }
            .width(ideal: 70)
        }
        .frame(minHeight: 280)
    }
}
