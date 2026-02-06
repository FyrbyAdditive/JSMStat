import SwiftUI
import Charts

struct DonutChartItem: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color?
}

struct DonutChartView: View {
    let items: [DonutChartItem]
    let title: String?
    let innerRadiusFraction: Double

    @State private var animationProgress: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(items: [DonutChartItem], title: String? = nil, innerRadiusFraction: Double = 0.6) {
        self.items = items
        self.title = title
        self.innerRadiusFraction = innerRadiusFraction
    }

    private var total: Double {
        items.reduce(0) { $0 + $1.value }
    }

    private func percentage(for value: Double) -> String {
        guard total > 0 else { return "0%" }
        return String(format: "%.0f%%", value / total * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title)
                    .font(.headline)
            }

            HStack(spacing: 20) {
                Chart(items) { item in
                    SectorMark(
                        angle: .value("Count", item.value * animationProgress),
                        innerRadius: .ratio(innerRadiusFraction),
                        angularInset: 1.5
                    )
                    .foregroundStyle(item.color ?? ChartTheme.foregroundStyle(at: items.firstIndex(where: { $0.id == item.id }) ?? 0))
                    .cornerRadius(DesignTokens.chartRadius)
                    .annotation(position: .overlay) {
                        if animationProgress >= 1.0 && total > 0 && (item.value / total) >= 0.08 {
                            Text(percentage(for: item.value))
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .shadow(radius: 1)
                        }
                    }
                }
                .frame(minHeight: 200)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(items.prefix(8).enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(item.color ?? ChartTheme.foregroundStyle(at: index))
                                .frame(width: 8, height: 8)
                            Text(item.label)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text("\(Int(item.value))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(percentage(for: item.value))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .frame(width: 32, alignment: .trailing)
                        }
                    }
                }
                .frame(minWidth: 140)
            }
        }
        .animation(ChartTheme.defaultAnimation, value: items.count)
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
