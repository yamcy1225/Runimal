import Foundation
import Observation
import RunimalCore
import WatchConnectivity

@MainActor
@Observable
final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    let offlineMapStorage = WatchOfflineMapPackStorage()
    var activationStateLabel = "inactive"
    var lastSyncedWorkoutTitle = "No plan yet"
    var claimedRewardIDs: Set<String> = []
    var activeEffects: [WeeklyRewardEffect] = []
    var autoPauseEnabled = true
    var offlineMapPacks: [OfflineMapPackSummary] = []
    var selectedOfflineMapPackID: String?
    var queuedTransferCount = 0
    var recentEvents: [SyncDiagnosticEvent] = []

    var syncStatusLabel: String {
        if queuedTransferCount > 0 {
            return "자동 동기화 대기 \(queuedTransferCount)"
        }

        switch activationStateLabel {
        case "activated":
            return "자동 동기화 준비"
        case "inactive":
            return "페어링 준비"
        default:
            return "연결 확인 중"
        }
    }

    func activate() {
        guard WCSession.isSupported() else {
            activationStateLabel = "unsupported"
            logEvent("activation", "WCSession unsupported")
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
        queuedTransferCount = session.outstandingUserInfoTransfers.count
        logEvent("activation", "WCSession activate requested")
    }

    func send(snapshot: LiveRunSnapshot) {
        guard WCSession.isSupported() else { return }

        do {
            let data = try JSONEncoder().encode(snapshot)
            let session = WCSession.default
            if session.isReachable {
                try session.updateApplicationContext(["liveRunSnapshot": data])
                logEvent("push snapshot", "\(Int(snapshot.distanceMeters))m")
            } else {
                session.transferUserInfo(["liveRunSnapshot": data])
                queuedTransferCount = session.outstandingUserInfoTransfers.count
                logEvent("queue snapshot", "\(Int(snapshot.distanceMeters))m")
            }
        } catch {
            lastSyncedWorkoutTitle = "Snapshot sync failed"
            logEvent("push snapshot failed", error.localizedDescription)
        }
    }

    func send(reward: RunRewardSummary) {
        guard WCSession.isSupported() else { return }

        do {
            let data = try JSONEncoder().encode(reward)
            let session = WCSession.default
            if session.isReachable {
                try session.updateApplicationContext(["runRewardSummary": data])
            }
            session.transferUserInfo(["runRewardSummary": data])
            queuedTransferCount = session.outstandingUserInfoTransfers.count
            logEvent("queue reward", reward.coreLabel)
        } catch {
            lastSyncedWorkoutTitle = "Reward sync failed"
            logEvent("push reward failed", error.localizedDescription)
        }
    }

    func send(completedRun: CompletedRunRecord) {
        guard WCSession.isSupported() else { return }

        do {
            let data = try JSONEncoder().encode(completedRun)
            let session = WCSession.default
            if session.isReachable {
                try session.updateApplicationContext(["completedRunRecord": data])
            }
            session.transferUserInfo(["completedRunRecord": data])
            queuedTransferCount = session.outstandingUserInfoTransfers.count
            logEvent("queue completed run", completedRun.id)
        } catch {
            lastSyncedWorkoutTitle = "Run sync failed"
            logEvent("push completed run failed", error.localizedDescription)
        }
    }

    func send(workoutArchive: WorkoutSessionArchive) {
        guard WCSession.isSupported() else { return }

        do {
            let data = try JSONEncoder().encode(workoutArchive)
            let session = WCSession.default
            if session.isReachable {
                try session.updateApplicationContext(["workoutSessionArchive": data])
            }
            session.transferUserInfo(["workoutSessionArchive": data])
            queuedTransferCount = session.outstandingUserInfoTransfers.count
            logEvent("queue archive", workoutArchive.runID)
        } catch {
            lastSyncedWorkoutTitle = "Archive sync failed"
            logEvent("push archive failed", error.localizedDescription)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.activationStateLabel = activationState.description
            self.queuedTransferCount = session.outstandingUserInfoTransfers.count
            if let error {
                self.lastSyncedWorkoutTitle = error.localizedDescription
                self.logEvent("activation failed", error.localizedDescription)
            } else {
                self.logEvent("activation ready", activationState.description)
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.queuedTransferCount = session.outstandingUserInfoTransfers.count
            self.logEvent("reachability", session.isReachable ? "reachable" : "paired")
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        processPayload(applicationContext)
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        processPayload(userInfo)
    }

    nonisolated func session(_ session: WCSession, didReceive file: WCSessionFile) {
        guard let packID = file.metadata?["offlineMapPackID"] as? String,
              let kind = file.metadata?["offlineMapFileKind"] as? String else { return }

        Task { @MainActor in
            self.offlineMapStorage.storeTransferredFile(
                tempURL: file.fileURL,
                packID: packID,
                kind: kind
            )
            self.logEvent("map file", "\(packID):\(kind)")
        }
    }

    private nonisolated func processPayload(_ payload: [String: Any]) {
        Task { @MainActor in
            if let data = payload["workoutSuggestion"] as? Data,
               let suggestion = try? JSONDecoder().decode(WorkoutPlanSuggestion.self, from: data) {
                self.lastSyncedWorkoutTitle = suggestion.title
                self.logEvent("plan received", suggestion.title)
            }

            if let data = payload["companionEffectContext"] as? Data,
               let context = try? JSONDecoder().decode(CompanionEffectContext.self, from: data) {
                self.claimedRewardIDs = Set(context.claimedRewardIDs)
                self.activeEffects = context.activeEffects
                self.logEvent("effects received", "\(context.activeEffects.count) active")
            }

            if let enabled = payload["autoPauseEnabled"] as? Bool {
                self.autoPauseEnabled = enabled
                self.logEvent("auto pause", enabled ? "on" : "off")
            }

            if let data = payload["offlineMapPackCatalog"] as? Data,
               let packs = try? JSONDecoder().decode([OfflineMapPackSummary].self, from: data) {
                self.offlineMapPacks = packs
                self.logEvent("map packs", "\(packs.count)")
            }

            if payload.keys.contains("selectedOfflineMapPackID") {
                self.selectedOfflineMapPackID = payload["selectedOfflineMapPackID"] as? String
                self.logEvent("selected map", self.selectedOfflineMapPackID ?? "none")
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
