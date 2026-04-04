import AppKit
import SwiftUI

enum MacUICaptureScenario: String {
    case dashboard

    static var current: MacUICaptureScenario? {
        ProcessInfo.processInfo.environment["RUNIMAL_MAC_UI_CAPTURE_SCENARIO"].flatMap(Self.init(rawValue:))
    }
}

@MainActor
enum MacUICaptureRenderer {
    static func captureIfNeeded(for scenario: MacUICaptureScenario) {
        guard let path = ProcessInfo.processInfo.environment["RUNIMAL_MAC_UI_CAPTURE_PATH"] else { return }

        let url = URL(fileURLWithPath: path)
        let content = MacDashboardView(store: MacBalanceLabStore(captureScenario: scenario))
        let hostingView = NSHostingView(rootView: content)
        hostingView.frame = NSRect(x: 0, y: 0, width: 1180, height: 860)
        hostingView.layoutSubtreeIfNeeded()

        guard let bitmap = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            return
        }

        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)

        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return
        }

        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        try? pngData.write(to: url)
    }
}

@main
struct RunimalMacApp: App {
    init() {
        if let scenario = MacUICaptureScenario.current {
            DispatchQueue.main.async {
                MacUICaptureRenderer.captureIfNeeded(for: scenario)
                NSApplication.shared.terminate(nil)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            if MacUICaptureScenario.current != nil {
                Color.clear
                    .frame(width: 1, height: 1)
            } else {
                MacDashboardView()
            }
        }
        .windowResizability(.contentSize)
    }
}
