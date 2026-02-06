import SwiftUI

struct DashboardCard<Content: View>: View {
    let title: String?
    @ViewBuilder let content: () -> Content

    @State private var isHovered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(title: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.innerSpacing) {
            if let title {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            content()
        }
        .padding(DesignTokens.cardPadding)
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
