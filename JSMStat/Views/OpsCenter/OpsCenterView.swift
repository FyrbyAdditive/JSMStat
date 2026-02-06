import SwiftUI
import os

private let logger = Logger(subsystem: "JSMStat", category: "OpsCenterView")

struct OpsCenterView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = OpsCenterViewModel()
    @State private var isFullScreen = false
    @State private var opsCenterWindow: NSWindow?
    @State private var hideTimer: Timer?
    @State private var cursorHidden = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let vm = appState.dashboardVM {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("JSMStat Operations Center")
                            .font(.title3.bold())
                            .foregroundStyle(.white)

                        Spacer()

                        if let desk = appState.selectedServiceDesk {
                            Text(desk.projectName)
                                .foregroundStyle(.white.opacity(0.7))
                        }

                        Text(Date(), style: .time)
                            .font(.title3.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding()

                    // KPI Strip
                    HStack(spacing: 16) {
                        opsKPICard("Open", "\(vm.snapshot.overview.totalOpen)", .orange)
                        opsKPICard("Closed", "\(vm.snapshot.overview.totalClosedInPeriod)", .green)
                        opsKPICard("New", "\(vm.snapshot.overview.newInPeriod)", .blue)
                        opsKPICard("Med. Res.", DateFormatting.hoursString(from: vm.snapshot.overview.medianResolutionHours), .purple)
                        opsKPICard("SLA Breach", "\(vm.snapshot.overview.slaBreachCount)",
                                   vm.snapshot.overview.slaBreachCount > 0 ? .red : .green)
                    }
                    .padding(.horizontal)

                    // Main content
                    switch viewModel.mode {
                    case .rotating:
                        OpsCenterRotatingView(viewModel: viewModel, dashboardVM: vm)
                    case .combined:
                        OpsCenterCombinedView(dashboardVM: vm)
                    }

                    Spacer(minLength: 0)
                }
            } else {
                ProgressView()
                    .tint(.white)
            }

            // Controls overlay
            if viewModel.showControls {
                VStack {
                    Spacer()
                    HStack(spacing: 20) {
                        Picker("Mode", selection: $viewModel.mode) {
                            ForEach(OpsCenterMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)

                        if viewModel.mode == .rotating {
                            Button(viewModel.isPaused ? "Resume" : "Pause") {
                                viewModel.togglePause()
                            }
                            .buttonStyle(.bordered)
                            .tint(.white)
                        }

                        Button("Refresh") {
                            appState.dashboardVM?.refreshInBackground()
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)

                        Divider()
                            .frame(height: 20)

                        Button {
                            toggleFullScreen()
                        } label: {
                            Image(systemName: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                        .help(isFullScreen ? "Exit Full Screen" : "Enter Full Screen")
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 30)
                    .onHover { hovering in
                        if hovering { onMouseActivity() }
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(WindowAccessor { window in
            if self.opsCenterWindow == nil {
                configureWindow(window)
            }
            self.opsCenterWindow = window
        })
        .overlay {
            MouseMovementView {
                onMouseActivity()
            }
            .allowsHitTesting(false)
        }
        .onAppear {
            // Safety net: ensure pipeline is initialized even if ops center opens before main window
            appState.initializePipeline()
            viewModel.startRotation()
            resetHideTimer()
        }
        .onDisappear {
            viewModel.stopRotation()
            // Do NOT stop auto-refresh — the shared VM must keep running for other windows
            hideTimer?.invalidate()
            hideTimer = nil
            showCursor()
        }
        .onChange(of: appState.selectedServiceDesk) { _, _ in
            appState.dashboardVM?.refreshInBackground()
        }
        .onChange(of: appState.selectedTimePeriod) { _, _ in
            appState.dashboardVM?.refreshInBackground()
        }
        .preferredColorScheme(.dark)
    }

    private func configureWindow(_ window: NSWindow) {
        // Ensure the window supports full screen
        window.collectionBehavior.insert(.fullScreenPrimary)
        window.styleMask.insert(.resizable)

        logger.info("Window configured: styleMask=\(window.styleMask.rawValue), collectionBehavior=\(window.collectionBehavior.rawValue)")

        // Auto-enter full screen after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            logger.info("Attempting full screen. isFullScreen=\(window.styleMask.contains(.fullScreen))")
            if !window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
                isFullScreen = true
            }
        }
    }

    private func toggleFullScreen() {
        guard let window = opsCenterWindow else {
            logger.warning("toggleFullScreen: no window reference")
            return
        }
        logger.info("toggleFullScreen called. Current styleMask=\(window.styleMask.rawValue), isFullScreen=\(window.styleMask.contains(.fullScreen))")
        window.toggleFullScreen(nil)
        // Update state after a brief delay to let the animation complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isFullScreen = window.styleMask.contains(.fullScreen)
        }
    }

    private func opsKPICard(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Auto-hide controls & cursor

    private func onMouseActivity() {
        showCursor()
        withAnimation(.easeOut(duration: 0.2)) {
            viewModel.showControls = true
        }
        resetHideTimer()
    }

    private func resetHideTimer() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            Task { @MainActor in
                withAnimation(.easeOut(duration: 0.4)) {
                    viewModel.showControls = false
                }
                hideCursor()
            }
        }
    }

    private func hideCursor() {
        guard !cursorHidden else { return }
        NSCursor.hide()
        cursorHidden = true
    }

    private func showCursor() {
        guard cursorHidden else { return }
        NSCursor.unhide()
        cursorHidden = false
    }
}

// MARK: - Window Accessor

/// Helper to capture the NSWindow hosting this SwiftUI view
/// and enable full-screen support.
struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                self.callback(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                self.callback(window)
            }
        }
    }
}

// MARK: - Mouse Movement Tracker

/// Transparent overlay that detects mouse movement and clicks
/// using an NSTrackingArea, then calls a callback.
struct MouseMovementView: NSViewRepresentable {
    let onMouseMoved: () -> Void

    func makeNSView(context: Context) -> MouseTrackingNSView {
        let view = MouseTrackingNSView()
        view.onMouseMoved = onMouseMoved
        return view
    }

    func updateNSView(_ nsView: MouseTrackingNSView, context: Context) {
        nsView.onMouseMoved = onMouseMoved
    }
}

final class MouseTrackingNSView: NSView {
    var onMouseMoved: (() -> Void)?
    private var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseMoved(with event: NSEvent) {
        onMouseMoved?()
    }

    override func mouseDown(with event: NSEvent) {
        onMouseMoved?()
        super.mouseDown(with: event)
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override var acceptsFirstResponder: Bool { false }
}
