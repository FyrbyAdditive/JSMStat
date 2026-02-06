import SwiftUI

enum DashboardSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case trends = "Ticket Trends"
    case byPerson = "By Person"
    case byCategory = "By Category"
    case endUsers = "End Users"
    case priority = "Priority"
    case sla = "SLA"
    case issues = "Issues"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .trends: return "chart.xyaxis.line"
        case .byPerson: return "person.2"
        case .byCategory: return "tag"
        case .endUsers: return "person.crop.circle"
        case .priority: return "exclamationmark.triangle"
        case .sla: return "clock.badge.checkmark"
        case .issues: return "list.bullet.rectangle"
        }
    }

    /// Whether this section can be disabled by the user. Overview is always on.
    var isToggleable: Bool {
        self != .overview
    }
}

struct Sidebar: View {
    @Binding var selection: DashboardSection?
    @AppStorage("enabledSections") private var enabledSectionsData: Data = Data()

    private var enabledSections: Set<String> {
        (try? JSONDecoder().decode(Set<String>.self, from: enabledSectionsData))
            ?? Set(DashboardSection.allCases.map(\.rawValue))
    }

    private var visibleSections: [DashboardSection] {
        DashboardSection.allCases.filter { section in
            !section.isToggleable || enabledSections.contains(section.rawValue)
        }
    }

    var body: some View {
        List(visibleSections, selection: $selection) { section in
            Label(section.rawValue, systemImage: section.icon)
                .tag(section)
        }
        .listStyle(.sidebar)
        .navigationTitle("JSMStat")
        .onChange(of: enabledSectionsData) { _, _ in
            if let selected = selection, !visibleSections.contains(selected) {
                selection = .overview
            }
        }
    }
}
