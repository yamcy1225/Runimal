import Foundation
import Observation
import RunimalCore
import WatchConnectivity

@MainActor
@Observable
final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    var activationStateLabel = "inactive"
    var lastSyncedWorkoutTitle = "No plan yet"
    var claimedRewardIDs: Set<String> = []
    var activeEffects: [WeeklyRewardEffect] = []

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

    func send(completedRun: CompletedRunRecord) {
        guard WCSession.isSupported() else { return }

        do {
            let data = try JSONEncoder().encode(completedRun)
            try WCSession.default.updateApplicationContext(["completedRunRecord": data])
        } catch {
            lastSyncedWorkoutTitle = "Run sync failed"
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

            if let data = applicationContext["companionEffectContext"] as? Data,
               let context = try? JSONDecoder().decode(CompanionEffectContext.self, from: data) {
                self.claimedRewardIDs = Set(context.claimedRewardIDs)
                self.activeEffects = context.activeEffects
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
