import Foundation
import Observation
import RunimalCore
import WatchConnectivity

@MainActor
@Observable
final class PhoneConnectivityManager: NSObject, WCSessionDelegate {
    var activationStateLabel = "inactive"
    var reachabilityLabel = "offline"
    var queuedTransferCount = 0
    var lastSnapshot: LiveRunSnapshot?
    var lastReward: RunRewardSummary?
    var lastCompletedRun: CompletedRunRecord?
    var lastMessage = "No watch sync yet"
    var recentEvents: [SyncDiagnosticEvent] = []

    func activate() {
        guard WCSession.isSupported() else {
            activationStateLabel = "unsupported"
            logEvent("activation", "WCSession unsupported on this device")
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
        reachabilityLabel = session.isReachable ? "reachable" : "waiting"
        queuedTransferCount = session.outstandingUserInfoTransfers.count
        logEvent("activation", "WCSession activate requested")
    }

    func pushSuggestedWorkout(_ suggestion: WorkoutPlanSuggestion) {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default

        do {
            let data = try JSONEncoder().encode(suggestion)
            if session.isReachable {
                try session.updateApplicationContext(["workoutSuggestion": data])
                lastMessage = "Sent plan: \(suggestion.title)"
                logEvent("push workout", suggestion.title)
            } else {
                session.transferUserInfo(["workoutSuggestion": data])
                queuedTransferCount = session.outstandingUserInfoTransfers.count
                lastMessage = "Queued plan for watch"
                logEvent("queue workout", suggestion.title)
            }
        } catch {
            lastMessage = "Sync failed: \(error.localizedDescription)"
            logEvent("push workout failed", error.localizedDescription)
        }
    }

    func pushCompanionEffects(_ context: CompanionEffectContext) {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default

        do {
            let data = try JSONEncoder().encode(context)
            if session.isReachable {
                try session.updateApplicationContext(["companionEffectContext": data])
                lastMessage = "Synced weekly effects"
                logEvent("push effects", "weekly effects synced")
            } else {
                session.transferUserInfo(["companionEffectContext": data])
                queuedTransferCount = session.outstandingUserInfoTransfers.count
                lastMessage = "Queued weekly effects"
                logEvent("queue effects", "weekly effects queued")
            }
        } catch {
            lastMessage = "Effect sync failed: \(error.localizedDescription)"
            logEvent("push effects failed", error.localizedDescription)
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
            self.queuedTransferCount = session.outstandingUserInfoTransfers.count
            if let error {
                self.lastMessage = "Activation error: \(error.localizedDescription)"
                self.logEvent("activation failed", error.localizedDescription)
            } else {
                self.logEvent("activation ready", self.reachabilityLabel)
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.reachabilityLabel = session.isReachable ? "reachable" : "paired"
            self.queuedTransferCount = session.outstandingUserInfoTransfers.count
            self.logEvent("reachability", self.reachabilityLabel)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        processPayload(applicationContext)
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        processPayload(userInfo)
    }

    private nonisolated func processPayload(_ payload: [String: Any]) {
        Task { @MainActor in
            if let data = payload["liveRunSnapshot"] as? Data,
               let snapshot = try? JSONDecoder().decode(LiveRunSnapshot.self, from: data) {
                self.lastSnapshot = snapshot
                self.lastMessage = "Watch snapshot received"
                self.logEvent("snapshot", "\(Int(snapshot.distanceMeters))m received")
            }

            if let data = payload["runRewardSummary"] as? Data,
               let reward = try? JSONDecoder().decode(RunRewardSummary.self, from: data) {
                self.lastReward = reward
                self.lastMessage = "Run reward synced"
                self.logEvent("reward", reward.coreLabel)
            }

            if let data = payload["completedRunRecord"] as? Data,
               let record = try? JSONDecoder().decode(CompletedRunRecord.self, from: data) {
                self.lastCompletedRun = record
                self.lastMessage = "Completed run synced"
                self.logEvent("completed run", record.id)
            }

            self.queuedTransferCount = WCSession.default.outstandingUserInfoTransfers.count
        }
    }

    private func logEvent(_ title: String, _ detail: String) {
        recentEvents.insert(SyncDiagnosticEvent(title: title, detail: detail), at: 0)
        recentEvents = Array(recentEvents.prefix(6))
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
