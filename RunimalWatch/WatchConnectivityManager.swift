import Foundation
import Observation
import RunimalCore
import WatchConnectivity

@MainActor
@Observable
final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    var activationStateLabel = "inactive"
    var lastSyncedWorkoutTitle = "No plan yet"

    func activate() {
        guard WCSession.isSupported() else {
            activationStateLabel = "unsupported"
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func send(snapshot: LiveRunSnapshot) {
        guard WCSession.isSupported() else { return }

        do {
            let data = try JSONEncoder().encode(snapshot)
            try WCSession.default.updateApplicationContext(["liveRunSnapshot": data])
        } catch {
            lastSyncedWorkoutTitle = "Snapshot sync failed"
        }
    }

    func send(reward: RunRewardSummary) {
        guard WCSession.isSupported() else { return }

        do {
            let data = try JSONEncoder().encode(reward)
            try WCSession.default.updateApplicationContext(["runRewardSummary": data])
        } catch {
            lastSyncedWorkoutTitle = "Reward sync failed"
        }
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.activationStateLabel = activationState.description
            if let error {
                self.lastSyncedWorkoutTitle = error.localizedDescription
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            if let data = applicationContext["workoutSuggestion"] as? Data,
               let suggestion = try? JSONDecoder().decode(WorkoutPlanSuggestion.self, from: data) {
                self.lastSyncedWorkoutTitle = suggestion.title
            }
        }
    }
}

private extension WCSessionActivationState {
    var description: String {
        switch self {
        case .notActivated: return "not activated"
        case .inactive: return "inactive"
        case .activated: return "activated"
        @unknown default: return "unknown"
        }
    }
}
