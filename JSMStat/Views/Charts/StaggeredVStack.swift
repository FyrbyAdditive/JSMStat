import SwiftUI

/// A view modifier that applies a staggered fade-in + slide-up entrance animation.
/// Attach to individual items with an index to create a cascade effect.
struct StaggeredEntrance: ViewModifier {
    let index: Int
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(appeared || reduceMotion ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 12)
            .animation(
                reduceMotion ? nil : DesignTokens.cardEntrance.delay(Double(index) * DesignTokens.staggerDelay),
                value: appeared
            )
            .onAppear {
                if !reduceMotion {
                    appeared = true
                }
            }
    }
}

extension View {
    /// Applies a staggered entrance animation based on the item's index.
    /// Items appear with a slight delay between each, creating a cascade effect.
    func staggeredEntrance(index: Int) -> some View {
        modifier(StaggeredEntrance(index: index))
    }
}
