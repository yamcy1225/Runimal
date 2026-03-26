import Foundation
import Observation
import RunimalCore
import WatchConnectivity

@MainActor
@Observable
final class PhoneConnectivityManager: NSObject, WCSessionDelegate {
    var activationStateLabel = "inactive"
    var reachabilityLabel = "offline"
    var lastSnapshot: LiveRunSnapshot?
    var lastMessage = "No watch sync yet"

    func activate() {
        guard WCSession.isSupported() else {
            activationStateLabel = "unsupported"
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
        reachabilityLabel = session.isReachable ? "reachable" : "waiting"
    }

    func pushSuggestedWorkout(_ suggestion: WorkoutPlanSuggestion) {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default

        do {
            let data = try JSONEncoder().encode(suggestion)
            try session.updateApplicationContext(["workoutSuggestion": data])
            lastMessage = "Sent plan: \(suggestion.title)"
        } catch {
            lastMessage = "Sync failed: \(error.localizedDescription)"
        }
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.activationStateLabel = activationState.description
            self.reachabilityLabel = session.isReachable ? "reachable" : "paired"
            if let error {
                self.lastMessage = "Activation error: \(error.localizedDescription)"
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            if let data = applicationContext["liveRunSnapshot"] as? Data,
               let snapshot = try? JSONDecoder().decode(LiveRunSnapshot.self, from: data) {
                self.lastSnapshot = snapshot
                self.lastMessage = "Watch snapshot received"
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
