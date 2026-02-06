import Foundation

struct SLAMetric: Codable, Identifiable {
    let id: Int?
    let name: String
    let completedCycles: [SLACycle]?
    let ongoingCycle: SLACycle?

    var totalCycles: Int {
        (completedCycles?.count ?? 0) + (ongoingCycle != nil ? 1 : 0)
    }

    var breachedCount: Int {
        (completedCycles?.filter { $0.breached == true }.count ?? 0)
            + (ongoingCycle?.breached == true ? 1 : 0)
    }

    var compliancePercent: Double {
        guard totalCycles > 0 else { return 100.0 }
        return Double(totalCycles - breachedCount) / Double(totalCycles) * 100.0
    }
}

struct SLACycle: Codable {
    let breached: Bool?
    let goalDuration: SLADuration?
    let elapsedTime: SLADuration?
    let remainingTime: SLADuration?
}

struct SLADuration: Codable {
    let millis: Int?
    let friendly: String?
}

struct SLAListResponse: Codable {
    let values: [SLAMetric]
}
