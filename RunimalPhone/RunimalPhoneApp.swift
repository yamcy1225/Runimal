import SwiftUI

@main
struct RunimalPhoneApp: App {
    var body: some Scene {
        WindowGroup {
            if let scenario = PhoneUICaptureScenario.current {
                PhoneUICaptureHarnessRoot(scenario: scenario)
            } else {
                PhoneDashboardView()
            }
        }
    }
}
