import SwiftUI

@main
struct RunimalPhoneApp: App {
    var body: some Scene {
        WindowGroup {
            if let runtimeCheck = PhoneRuntimeCheck.current {
                PhoneRuntimeCheckRoot(check: runtimeCheck)
            } else if let scenario = PhoneUICaptureScenario.current {
                PhoneUICaptureHarnessRoot(scenario: scenario)
            } else {
                PhoneDashboardView()
            }
        }
    }
}
