import SwiftUI
import Charts

struct BarChartItem: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color?
}

struct BarChartView: View {
    let items: [BarChartItem]
    let title: String?
    let isHorizontal: Bool
    let showValues: Bool

    @State private var animationProgress: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(items: [BarChartItem], title: String? = nil, isHorizontal: Bool = false, showValues: Bool = true) {
        self.items = items
        self.title = title
        self.isHorizontal = isHorizontal
        self.showValues = showValues
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title)
                    .font(.headline)
            }

            Chart(items) { item in
                let animatedValue = item.value * animationProgress
                if isHorizontal {
                    BarMark(
                        x: .value("Count", animatedValue),
                        y: .value("Category", item.label)
                    )
                    .foregroundStyle(item.color ?? ChartTheme.foregroundStyle(at: items.firstIndex(where: { $0.id == item.id }) ?? 0))
                    .cornerRadius(DesignTokens.chartRadius)
                    .annotation(position: .trailing) {
                        if showValues && animationProgress >= 1.0 {
                            Text("\(Int(item.value))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    BarMark(
                        x: .value("Category", item.label),
                        y: .value("Count", animatedValue)
                    )
                    .foregroundStyle(item.color ?? ChartTheme.foregroundStyle(at: items.firstIndex(where: { $0.id == item.id }) ?? 0))
                    .cornerRadius(DesignTokens.chartRadius)
                    .annotation(position: .top) {
                        if showValues && animationProgress >= 1.0 {
                            Text("\(Int(item.value))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                if !isHorizontal {
                    AxisMarks(position: .leading)
                }
            }
            .animation(ChartTheme.defaultAnimation, value: items.count)
        }
        .onAppear {
            if reduceMotion {
                animationProgress = 1.0
            } else {
                withAnimation(ChartTheme.chartEntranceAnimation) {
                    animationProgress = 1.0
                }
            }
        }
    }
}
