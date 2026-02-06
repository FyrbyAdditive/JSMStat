import SwiftUI
import Charts

struct TrendLineChart: View {
    let data: [TrendDataPoint]
    let showArea: Bool

    @State private var animationProgress: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(data: [TrendDataPoint], showArea: Bool = true) {
        self.data = data
        self.showArea = showArea
    }

    /// Returns the subset of data visible based on animation progress.
    private var visibleData: [TrendDataPoint] {
        guard !data.isEmpty else { return [] }
        let count = max(1, Int(ceil(Double(data.count) * animationProgress)))
        return Array(data.prefix(count))
    }

    var body: some View {
        Chart {
            ForEach(visibleData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Created", point.createdCount),
                    series: .value("Series", "Created")
                )
                .foregroundStyle(ColorPalette.statusNew)
                .interpolationMethod(.catmullRom)

                if showArea {
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Created", point.createdCount),
                        series: .value("Series", "Created")
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ColorPalette.statusNew.opacity(0.3), ColorPalette.statusNew.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Resolved", point.resolvedCount),
                    series: .value("Series", "Resolved")
                )
                .foregroundStyle(ColorPalette.statusDone)
                .interpolationMethod(.catmullRom)

                if showArea {
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Resolved", point.resolvedCount),
                        series: .value("Series", "Resolved")
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ColorPalette.statusDone.opacity(0.3), ColorPalette.statusDone.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
        }
        .chartLegend(position: .top, alignment: .leading)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartYAxisLabel("Tickets", position: .leading)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .animation(ChartTheme.defaultAnimation, value: data.count)
        .onAppear {
            if reduceMotion {
                animationProgress = 1.0
            } else {
                withAnimation(.easeOut(duration: 0.8)) {
                    animationProgress = 1.0
                }
            }
        }
    }
}
