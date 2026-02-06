import SwiftUI
import os

private let logger = Logger(subsystem: "JSMStat", category: "OpsCenter")

enum OpsCenterMode: String, CaseIterable {
    case rotating = "Auto-Rotate"
    case combined = "Combined"
}

enum OpsCenterPanel: String, CaseIterable, Identifiable {
    case trends = "Ticket Trends"
    case byPerson = "By Person"
    case byCategory = "By Category"
    case priority = "Priority"
    case sla = "SLA Compliance"
    case endUsers = "End Users"
    case issues = "Issues"

    var id: String { rawValue }

    var correspondingSection: DashboardSection {
        switch self {
        case .trends:     return .trends
        case .byPerson:   return .byPerson
        case .byCategory: return .byCategory
        case .priority:   return .priority
        case .sla:        return .sla
        case .endUsers:   return .endUsers
        case .issues:     return .issues
        }
    }
}

@MainActor @Observable
final class OpsCenterViewModel {
    var mode: OpsCenterMode = .rotating {
        didSet {
            if mode == .rotating {
                startRotation()
            } else {
                stopRotation()
            }
        }
    }
    var currentPanel: OpsCenterPanel = .trends
    var isPaused = false
    var showControls = false

    var rotationInterval: TimeInterval {
        UserSettings.opsCenterRotationSeconds
    }

    private var rotationTask: Task<Void, Never>?

    var panels: [OpsCenterPanel] {
        OpsCenterPanel.allCases.filter { UserSettings.isSectionEnabled($0.correspondingSection) }
    }

    var currentPanelIndex: Int {
        panels.firstIndex(of: currentPanel) ?? 0
    }

    func startRotation() {
        rotationTask?.cancel()
        guard mode == .rotating else { return }
        logger.info("Starting rotation with interval \(self.rotationInterval)s")
        rotationTask = Task {
            while !Task.isCancelled {
                let interval = self.rotationInterval
                logger.info("Sleeping for \(interval)s before next panel")
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else {
                    logger.info("Rotation task cancelled")
                    break
                }
                guard !self.isPaused else {
                    logger.info("Rotation paused, skipping advance")
                    continue
                }
                self.advancePanel()
            }
            logger.info("Rotation loop exited")
        }
    }

    func stopRotation() {
        logger.info("Stopping rotation")
        rotationTask?.cancel()
        rotationTask = nil
    }

    func advancePanel() {
        let activePanels = panels
        guard !activePanels.isEmpty else { return }
        // If current panel was disabled, snap to first available
        guard let currentIdx = activePanels.firstIndex(of: currentPanel) else {
            withAnimation(.easeInOut(duration: 0.8)) {
                currentPanel = activePanels[0]
            }
            return
        }
        let nextIndex = (currentIdx + 1) % activePanels.count
        let nextPanel = activePanels[nextIndex]
        logger.info("Advancing from \(self.currentPanel.rawValue) to \(nextPanel.rawValue)")
        withAnimation(.easeInOut(duration: 0.8)) {
            currentPanel = nextPanel
        }
    }

    func togglePause() {
        isPaused.toggle()
        logger.info("Rotation \(self.isPaused ? "paused" : "resumed")")
    }
}
