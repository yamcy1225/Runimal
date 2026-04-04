import SwiftUI

@main
struct RunimalWatchApp: App {
    init() {
        if WatchUICaptureScenario.current == nil {
            Task { @MainActor in
                WatchConnectivityManager.shared.activate()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            WatchDashboardView(captureScenario: WatchUICaptureScenario.current)
        }
    }
}
