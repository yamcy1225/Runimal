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
    var lastWorkoutArchive: WorkoutSessionArchive?
    var watchOfflineMapPacks: [OfflineMapPackSummary] = []
    var selectedOfflineMapPackID: String?
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

    func pushAutoPauseEnabled(_ enabled: Bool) {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        do {
            if session.isReachable {
                try session.updateApplicationContext(["autoPauseEnabled": enabled])
                lastMessage = enabled ? "Auto Pause ON synced" : "Auto Pause OFF synced"
                logEvent("push auto pause", enabled ? "on" : "off")
            } else {
                session.transferUserInfo(["autoPauseEnabled": enabled])
                queuedTransferCount = session.outstandingUserInfoTransfers.count
                lastMessage = enabled ? "Queued Auto Pause ON" : "Queued Auto Pause OFF"
                logEvent("queue auto pause", enabled ? "on" : "off")
            }
        } catch {
            lastMessage = "Auto Pause sync failed: \(error.localizedDescription)"
            logEvent("push auto pause failed", error.localizedDescription)
        }
    }

    func pushOfflineMapPackCatalog(_ packs: [OfflineMapPackSummary]) {
        guard WCSession.isSupported() else { return }

        do {
            let data = try JSONEncoder().encode(packs)
            let session = WCSession.default
            if session.isReachable {
                try session.updateApplicationContext(["offlineMapPackCatalog": data])
                lastMessage = "Offline map catalog synced"
                logEvent("push map packs", "\(packs.count)")
            } else {
                session.transferUserInfo(["offlineMapPackCatalog": data])
                queuedTransferCount = session.outstandingUserInfoTransfers.count
                lastMessage = "Queued offline map catalog"
                logEvent("queue map packs", "\(packs.count)")
            }
        } catch {
            lastMessage = "Map pack sync failed: \(error.localizedDescription)"
            logEvent("push map packs failed", error.localizedDescription)
        }
    }

    func pushSelectedOfflineMapPackID(_ packID: String?) {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        let payload: [String: Any] = ["selectedOfflineMapPackID": packID as Any]

        do {
            if session.isReachable {
                try session.updateApplicationContext(payload)
                lastMessage = packID == nil ? "Offline map cleared" : "Selected map synced"
                logEvent("push selected map", packID ?? "none")
            } else {
                session.transferUserInfo(payload)
                queuedTransferCount = session.outstandingUserInfoTransfers.count
                lastMessage = packID == nil ? "Queued map clear" : "Queued selected map"
                logEvent("queue selected map", packID ?? "none")
            }
        } catch {
            lastMessage = "Selected map sync failed: \(error.localizedDescription)"
            logEvent("push selected map failed", error.localizedDescription)
        }
    }

    func queueOfflineMapPackFiles(packID: String, urls: [URL]) {
        guard WCSession.isSupported(), urls.isEmpty == false else { return }

        let session = WCSession.default
        for url in urls {
            let kind = url.lastPathComponent == "manifest.json" ? "manifest" : "tiles"
            session.transferFile(url, metadata: [
                "offlineMapPackID": packID,
                "offlineMapFileKind": kind
            ])
        }
        queuedTransferCount = session.outstandingUserInfoTransfers.count
        lastMessage = "Queued offline map files"
        logEvent("queue map files", "\(packID):\(urls.count)")
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

            if let data = payload["workoutSessionArchive"] as? Data,
               let archive = try? JSONDecoder().decode(WorkoutSessionArchive.self, from: data) {
                self.lastWorkoutArchive = archive
                self.lastMessage = "Workout archive synced"
                self.logEvent("archive", archive.runID)
            }

            if let data = payload["offlineMapPackCatalog"] as? Data,
               let packs = try? JSONDecoder().decode([OfflineMapPackSummary].self, from: data) {
                self.watchOfflineMapPacks = packs
                self.lastMessage = "Watch map catalog synced"
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
