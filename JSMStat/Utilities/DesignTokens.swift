import SwiftUI

enum DesignTokens {
    // MARK: - Spacing

    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 20
    static let innerSpacing: CGFloat = 12

    // MARK: - Corners & Shapes

    static let cardRadius: CGFloat = 14
    static let chartRadius: CGFloat = 4

    // MARK: - Shadows

    static let cardShadowRadius: CGFloat = 8
    static let cardShadowY: CGFloat = 2
    static let cardShadowOpacity: Double = 0.08
    static let hoverShadowRadius: CGFloat = 12

    // MARK: - Animation

    static let cardEntrance: Animation = .easeOut(duration: 0.35)
    static let staggerDelay: Double = 0.05
    static let dataTransition: Animation = .easeInOut(duration: 0.4)
    static let numberCounting: Animation = .easeInOut(duration: 0.6)
    static let chartEntranceDuration: Double = 0.5
    static let chartEntranceAnimation: Animation = .easeOut(duration: 0.5)

    // MARK: - Hover

    static let hoverScale: CGFloat = 1.015
}
