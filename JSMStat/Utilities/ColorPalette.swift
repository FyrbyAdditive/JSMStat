import SwiftUI

enum ColorPalette {
    static let chartColors: [Color] = [
        .blue, .green, .orange, .purple, .pink, .cyan, .mint, .indigo, .teal, .yellow
    ]

    static let statusNew = Color.blue
    static let statusInProgress = Color.orange
    static let statusDone = Color.green

    static let priorityCritical = Color.red
    static let priorityHigh = Color.orange
    static let priorityMedium = Color.yellow
    static let priorityLow = Color.green
    static let priorityTrivial = Color.gray

    static let slaBreached = Color.red
    static let slaOnTrack = Color.green
    static let slaNearing = Color.orange

    static let positive = Color.green
    static let negative = Color.red
    static let neutral = Color.secondary

    // Card styling
    static let cardBackground = Color(.windowBackgroundColor).opacity(0.5)
    static let cardBorder = Color.primary.opacity(0.06)

    static func color(at index: Int) -> Color {
        chartColors[index % chartColors.count]
    }

    static func statusCategoryColor(_ key: String) -> Color {
        switch key {
        case "new": return statusNew
        case "indeterminate": return statusInProgress
        case "done": return statusDone
        default: return .secondary
        }
    }

    static func priorityColor(_ name: String) -> Color {
        let lower = name.lowercased()
        if lower.contains("critical") || lower.contains("highest") || lower.contains("blocker") {
            return priorityCritical
        } else if lower.contains("high") || lower.contains("major") {
            return priorityHigh
        } else if lower.contains("medium") || lower.contains("normal") {
            return priorityMedium
        } else if lower.contains("low") || lower.contains("minor") {
            return priorityLow
        } else {
            return priorityTrivial
        }
    }

    static func agingColor(_ name: String) -> Color {
        switch name {
        case "green": return .green
        case "mint": return .mint
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        default: return .gray
        }
    }
}
