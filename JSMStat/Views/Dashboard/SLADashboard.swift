import SwiftUI
import Charts

struct SLADashboard: View {
    let viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            if viewModel.lastRefreshed != nil && viewModel.snapshot.sla.isEmpty {
                EmptyStateView(
                    icon: "clock.badge.checkmark",
                    title: "No SLA Data",
                    message: "No SLA metrics available for the selected service desk.",
                    suggestion: "SLA data requires active SLA configurations in your JIRA Service Management project."
                )
                .frame(maxWidth: .infinity, minHeight: 400)
            } else {
            VStack(spacing: 20) {
                // SLA KPI Cards
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: min(viewModel.snapshot.sla.count, 4).clamped(to: 1...4)), spacing: 16) {
                    ForEach(Array(viewModel.snapshot.sla.enumerated()), id: \.element.id) { index, sla in
                        KPICard(
                            title: sla.metricName,
                            value: String(format: "%.1f%%", sla.compliancePercent),
                            subtitle: "\(sla.breachedCount) of \(sla.totalCycles) breached",
                            color: sla.compliancePercent >= 95 ? ColorPalette.slaOnTrack :
                                   sla.compliancePercent >= 80 ? ColorPalette.slaNearing :
                                   ColorPalette.slaBreached
                        )
                        .staggeredEntrance(index: index)
                    }
                }

                    DashboardCard("SLA Compliance") {
                        Chart(viewModel.snapshot.sla) { sla in
                            BarMark(
                                x: .value("SLA", sla.metricName),
                                y: .value("Compliance", sla.compliancePercent)
                            )
                            .foregroundStyle(
                                sla.compliancePercent >= 95 ? ColorPalette.slaOnTrack :
                                sla.compliancePercent >= 80 ? ColorPalette.slaNearing :
                                ColorPalette.slaBreached
                            )
                            .cornerRadius(4)
                            .annotation(position: .top) {
                                Text(String(format: "%.1f%%", sla.compliancePercent))
                                    .font(.caption)
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
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .chartYAxisLabel("Compliance %", position: .leading)
                        .frame(height: 250)
                    }
                    .staggeredEntrance(index: 1)

                    DashboardCard("Breach Details") {
                        Table(viewModel.snapshot.sla) {
                            TableColumn("SLA Metric") { sla in
                                Text(sla.metricName)
                            }

                            TableColumn("Total") { sla in
                                Text("\(sla.totalCycles)")
                                    .monospacedDigit()
                            }
                            .width(ideal: 80)

                            TableColumn("Breached") { sla in
                                Text("\(sla.breachedCount)")
                                    .monospacedDigit()
                                    .foregroundStyle(sla.breachedCount > 0 ? .red : .primary)
                            }
                            .width(ideal: 80)

                            TableColumn("Compliance") { sla in
                                Text(String(format: "%.1f%%", sla.compliancePercent))
                                    .monospacedDigit()
                            }
                            .width(ideal: 100)
                        }
                        .frame(minHeight: 150)
                    }
                    .staggeredEntrance(index: 2)
            }
            .padding()
            }
        }
        .navigationTitle("SLA")
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
