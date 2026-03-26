import SwiftUI

@main
struct RunimalMacApp: App {
    var body: some Scene {
        WindowGroup {
            MacDashboardView()
        }
        .windowResizability(.contentSize)
    }
}
