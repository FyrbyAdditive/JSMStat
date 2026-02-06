import Foundation

enum TimePeriod: Hashable, Identifiable {
    case today
    case last7Days
    case last30Days
    case last90Days
    case custom(Date, Date)

    var id: String {
        switch self {
        case .today: return "today"
        case .last7Days: return "7d"
        case .last30Days: return "30d"
        case .last90Days: return "90d"
        case .custom(let start, let end): return "custom-\(start.timeIntervalSince1970)-\(end.timeIntervalSince1970)"
        }
    }

    var label: String {
        switch self {
        case .today: return "Today"
        case .last7Days: return "Last 7 Days"
        case .last30Days: return "Last 30 Days"
        case .last90Days: return "Last 90 Days"
        case .custom: return "Custom"
        }
    }

    var startDate: Date {
        let calendar = Calendar.current
        switch self {
        case .today:
            return calendar.startOfDay(for: Date())
        case .last7Days:
            return calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        case .last30Days:
            return calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        case .last90Days:
            return calendar.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        case .custom(let start, _):
            return start
        }
    }

    var endDate: Date {
        switch self {
        case .custom(_, let end):
            return end
        default:
            return Date()
        }
    }

    var jqlDateString: String {
        DateFormatting.jqlDate(startDate)
    }

    var granularity: Calendar.Component {
        switch self {
        case .today: return .hour
        case .last7Days, .last30Days: return .day
        case .last90Days: return .weekOfYear
        case .custom(let start, let end):
            let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
            if days <= 1 { return .hour }
            if days <= 60 { return .day }
            return .weekOfYear
        }
    }

    /// Returns the equivalent prior period for period-over-period comparison.
    /// e.g. last7Days → the 7 days before that (days -14 to -7).
    var previousPeriod: TimePeriod {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .today:
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
            return .custom(calendar.startOfDay(for: yesterday), calendar.startOfDay(for: now))
        case .last7Days:
            let end = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            let start = calendar.date(byAdding: .day, value: -14, to: now) ?? now
            return .custom(start, end)
        case .last30Days:
            let end = calendar.date(byAdding: .day, value: -30, to: now) ?? now
            let start = calendar.date(byAdding: .day, value: -60, to: now) ?? now
            return .custom(start, end)
        case .last90Days:
            let end = calendar.date(byAdding: .day, value: -90, to: now) ?? now
            let start = calendar.date(byAdding: .day, value: -180, to: now) ?? now
            return .custom(start, end)
        case .custom(let start, let end):
            let duration = end.timeIntervalSince(start)
            let prevEnd = start
            let prevStart = prevEnd.addingTimeInterval(-duration)
            return .custom(prevStart, prevEnd)
        }
    }

    static var presets: [TimePeriod] {
        [.today, .last7Days, .last30Days, .last90Days]
    }
}
