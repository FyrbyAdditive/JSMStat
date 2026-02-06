import SwiftUI

/// Reusable empty state view for dashboards that distinguishes
/// between "never loaded" and "loaded but no data for this period".
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var suggestion: String?

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(message)
        } actions: {
            if let suggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .opacity(appeared || reduceMotion ? 1 : 0)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: appeared)
        .onAppear {
            appeared = true
        }
    }
}
