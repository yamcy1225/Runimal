import SwiftUI

@main
struct RunimalWatchApp: App {
    init() {
        Task { @MainActor in
            WatchConnectivityManager.shared.activate()
        }
    }

    var body: some Scene {
        WindowGroup {
            WatchDashboardView()
        }
    }
}
