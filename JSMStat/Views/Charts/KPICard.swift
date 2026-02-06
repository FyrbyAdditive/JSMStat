import SwiftUI

struct KPICard: View {
    let title: String
    let value: String
    let subtitle: String?
    let trend: KPITrend?
    let invertTrend: Bool
    let color: Color

    @State private var isHovered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(title: String, value: String, subtitle: String? = nil, trend: KPITrend? = nil, invertTrend: Bool = false, color: Color = .accentColor) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.trend = trend
        self.invertTrend = invertTrend
        self.color = color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Color accent bar at top
            Rectangle()
                .fill(color.gradient)
                .frame(height: 3)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: DesignTokens.cardRadius, topTrailingRadius: DesignTokens.cardRadius))

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                        .contentTransition(.numericText(countsDown: true))

                    if let trend = trend {
                        TrendBadge(trend: trend, inverted: invertTrend)
                    }
                }

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.cardRadius)
                .strokeBorder(ColorPalette.cardBorder, lineWidth: 0.5)
        )
        .shadow(
            color: .black.opacity(DesignTokens.cardShadowOpacity),
            radius: isHovered ? DesignTokens.hoverShadowRadius : DesignTokens.cardShadowRadius,
            y: DesignTokens.cardShadowY
        )
        .scaleEffect(isHovered && !reduceMotion ? DesignTokens.hoverScale : 1.0)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

enum KPITrend {
    case up(String)
    case down(String)
    case neutral(String)

    var isPositive: Bool {
        switch self {
        case .up: return true
        case .down: return false
        case .neutral: return true
        }
    }
}

struct TrendBadge: View {
    let trend: KPITrend
    var inverted: Bool = false

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption2)
        }
        .foregroundStyle(color)
    }

    private var icon: String {
        switch trend {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .neutral: return "minus"
        }
    }

    private var label: String {
        switch trend {
        case .up(let s), .down(let s), .neutral(let s): return s
        }
    }

    private var color: Color {
        switch trend {
        case .up: return inverted ? ColorPalette.negative : ColorPalette.positive
        case .down: return inverted ? ColorPalette.positive : ColorPalette.negative
        case .neutral: return ColorPalette.neutral
        }
    }
}
