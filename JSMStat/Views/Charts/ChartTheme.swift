import SwiftUI
import Charts

enum ChartTheme {
    static let colors: [Color] = ColorPalette.chartColors

    static func foregroundStyle(at index: Int) -> Color {
        colors[index % colors.count]
    }

    static let gridLineStyle = StrokeStyle(lineWidth: 0.5, dash: [4, 4])

    static let animationDuration: Double = 0.4
    static let defaultAnimation: Animation = .easeInOut(duration: animationDuration)

    // Chart entrance animations
    static let chartEntranceDuration: Double = DesignTokens.chartEntranceDuration
    static let chartEntranceAnimation: Animation = DesignTokens.chartEntranceAnimation
}
