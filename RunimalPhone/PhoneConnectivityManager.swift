import Foundation
import Observation
import RunimalCore
import WatchConnectivity

struct OfflineMapPackTransferStatus: Equatable {
    enum Phase: String {
        case idle
        case sending
        case storedOnWatch
        case failed
    }

    var phase: Phase
    var expectedFileCount: Int
    var completedFileCount: Int
    var lastQueuedAt: Date?
    var lastCompletedAt: Date?
    var lastError: String?
}

@MainActor
@Observable
final class PhoneConnectivityManager: NSObject, WCSessionDelegate {
    private let archivePersistence = PhoneWorkoutArchivePersistence()
    var activationStateLabel = "inactive"
    var reachabilityLabel = "offline"
    var isPaired = false
    var isWatchAppInstalled = false
    var isComplicationEnabled = false
    var queuedTransferCount = 0
    var lastSnapshot: LiveRunSnapshot?
    var lastReward: RunRewardSummary?
    var lastCompletedRun: CompletedRunRecord?
    var lastWorkoutArchive: WorkoutSessionArchive?
    var watchOfflineMapPacks: [OfflineMapPackSummary] = []
    var watchStoredOfflineMapPackIDs: Set<String> = []
    var offlineMapTransferStatus: [String: OfflineMapPackTransferStatus] = [:]
    var selectedOfflineMapPackID: String?
    var lastMainCompanionContext: WatchMainCompanionContext?
    var currentMainCompanionContext: WatchMainCompanionContext?
    var lastMessage = "No watch sync yet"
    var recentEvents: [SyncDiagnosticEvent] = []
    var lastQueuedMainCompanionFileTargetID: String?
    var lastInboundRoute = "none"
    var receivedApplicationContextCount = 0
    var receivedMessageCount = 0
    var receivedUserInfoCount = 0
    var receivedPingCount = 0
    var lastInboundPayloadKeys: [String] = []
    private var outboundApplicationContext: [String: Any] = [:]
    private var mainCompanionRetryTask: Task<Void, Never>?
    private var pendingMainCompanionToken: String?
    var lastAcknowledgedMainCompanionToken: String?
    var lastAcknowledgedMainCompanionTargetID: String?
    var currentMainCompanionProvider: (() -> WatchMainCompanionContext?)?

    private func cancelOutstandingMainCompanionTransfers() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        for transfer in session.outstandingUserInfoTransfers where
            transfer.userInfo.keys.contains("mainCompanionContext") ||
            transfer.userInfo.keys.contains("mainCompanionSyncToken") ||
            transfer.userInfo.keys.contains(where: { $0.hasPrefix("mainCompanion_") })
        {
            transfer.cancel()
        }
        queuedTransferCount = session.outstandingUserInfoTransfers.count
    }

    private func cancelOutstandingMainCompanionFileTransfers() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        for transfer in session.outstandingFileTransfers where
            transfer.file.metadata?["watchSelectionSync"] as? Bool == true
        {
            transfer.cancel()
        }
    }

    private func resendMainCompanionIfPossible() {
        guard let context = currentMainCompanionContext ?? lastMainCompanionContext else { return }
        let token = pendingMainCompanionToken ?? UUID().uuidString
        pendingMainCompanionToken = token
        guard let payload = try? makeMainCompanionSyncPayload(context: context, token: token) else {
            logEvent("repush main companion failed", "payload build failed")
            return
        }

        sendMainCompanionPayload(payload, context: context, token: token, reason: "repush")
        scheduleMainCompanionRepush(token: token, selectionID: context.selection.id)
    }

    private func scheduleMainCompanionRepush(token: String, selectionID: String) {
        mainCompanionRetryTask?.cancel()

        mainCompanionRetryTask = Task { @MainActor in
            for delay in [0.6, 1.6, 3.2] {
                try? await Task.sleep(for: .seconds(delay))
                guard Task.isCancelled == false else { return }
                guard self.pendingMainCompanionToken == token else { return }
                guard self.lastAcknowledgedMainCompanionToken != token else { return }
                guard let context = self.lastMainCompanionContext, context.selection.id == selectionID else { return }
                guard let payload = try? self.makeMainCompanionSyncPayload(context: context, token: token) else {
                    self.logEvent("retry main companion failed", "payload build failed")
                    continue
                }
                self.sendMainCompanionPayload(payload, context: context, token: token, reason: "retry")
            }
        }
    }

    private func makeMainCompanionSyncPayload(
        context: WatchMainCompanionContext,
        token: String
    ) throws -> [String: Any] {
        var payload: [String: Any] = [
            "mainCompanionSyncToken": token,
            "mainCompanionSelectionID": context.selection.id,
        ]
        payload["mainCompanionContext"] = try JSONEncoder().encode(context)
        for (key, value) in context.flattenedWCPayload {
            payload[key] = value
        }
        for (key, value) in context.watchSelectionTransportPayload {
            payload[key] = value
        }
        return payload
    }

    private func queueMainCompanionFileTransfer(payload: [String: Any], token: String) throws {
        let jsonPayload = payload.filter { !($0.value is Data) }

        guard JSONSerialization.isValidJSONObject(jsonPayload) else {
            throw NSError(
                domain: "Runimal.PhoneConnectivityManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Main companion payload is not valid JSON"]
            )
        }

        let data = try JSONSerialization.data(withJSONObject: jsonPayload, options: [])
        let supportURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let transferDirectory = supportURL.appendingPathComponent("WatchSelectionSync", isDirectory: true)
        try FileManager.default.createDirectory(at: transferDirectory, withIntermediateDirectories: true)
        let fileURL = transferDirectory
            .appendingPathComponent("runimal-watch-selection-\(token).json")

        try data.write(to: fileURL, options: .atomic)
        cancelOutstandingMainCompanionFileTransfers()
        WCSession.default.transferFile(fileURL, metadata: [
            "watchSelectionSync": true,
            "mainCompanionSyncToken": token,
        ])
        lastQueuedMainCompanionFileTargetID =
            (jsonPayload["watchSelected_targetID"] as? String) ??
            (jsonPayload["mainCompanion_targetID"] as? String)
    }

    private func sendMainCompanionPayload(
        _ payload: [String: Any],
        context: WatchMainCompanionContext,
        token: String,
        reason: String
    ) {
        let session = WCSession.default
        cancelOutstandingMainCompanionTransfers()

        do {
            try updateWatchApplicationContext(adding: payload)
            logEvent("\(reason) app context", context.displayName)
        } catch {
            logEvent("\(reason) app context failed", error.localizedDescription)
        }

        if session.isReachable {
            session.sendMessage(payload, replyHandler: { reply in
                self.processPayload(reply, route: "messageReply")
            }, errorHandler: { error in
                Task { @MainActor in
                    self.logEvent("\(reason) send failed", error.localizedDescription)
                }
            })
            logEvent("\(reason) send", context.displayName)
        } else {
            logEvent("\(reason) send skipped", "watch unreachable")
        }

        session.transferUserInfo(payload)
        queuedTransferCount = session.outstandingUserInfoTransfers.count
        logEvent("\(reason) userInfo", context.displayName)

        do {
            try queueMainCompanionFileTransfer(payload: payload, token: token)
            logEvent("\(reason) file", context.displayName)
        } catch {
            logEvent("\(reason) file failed", error.localizedDescription)
        }
    }

    func activate() {
        guard WCSession.isSupported() else {
            activationStateLabel = "unsupported"
            logEvent("activation", "WCSession unsupported on this device")
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
        outboundApplicationContext = [:]
        refreshSessionState(session)
        logEvent("activation", "WCSession activate requested")
    }

    private func refreshSessionState(_ session: WCSession) {
        reachabilityLabel = session.isReachable ? "reachable" : "paired"
        queuedTransferCount = session.outstandingUserInfoTransfers.count
        isPaired = session.isPaired
        isWatchAppInstalled = session.isWatchAppInstalled
        isComplicationEnabled = session.isComplicationEnabled
    }

    private func updateWatchApplicationContext(adding values: [String: Any]) throws {
        for (key, value) in values {
            outboundApplicationContext[key] = value
        }
        try WCSession.default.updateApplicationContext(outboundApplicationContext)
    }

    private func removeWatchApplicationContextKeys(_ keys: [String]) throws {
        for key in keys {
            outboundApplicationContext.removeValue(forKey: key)
        }
        try WCSession.default.updateApplicationContext(outboundApplicationContext)
    }

    func pushSuggestedWorkout(_ suggestion: WorkoutPlanSuggestion) {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default

        do {
            let data = try JSONEncoder().encode(suggestion)
            if session.isReachable {
                try updateWatchApplicationContext(adding: ["workoutSuggestion": data])
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
                try updateWatchApplicationContext(adding: ["companionEffectContext": data])
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
                try updateWatchApplicationContext(adding: ["autoPauseEnabled": enabled])
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
                try updateWatchApplicationContext(adding: ["offlineMapPackCatalog": data])
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

        do {
            if session.isReachable {
                if let packID {
                    try updateWatchApplicationContext(adding: ["selectedOfflineMapPackID": packID])
                } else {
                    try removeWatchApplicationContextKeys(["selectedOfflineMapPackID"])
                }
                lastMessage = packID == nil ? "Offline map cleared" : "Selected map synced"
                logEvent("push selected map", packID ?? "none")
            } else {
                let payload: [String: Any] = ["selectedOfflineMapPackID": packID as Any]
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

    func pushMainCompanionContext(_ context: WatchMainCompanionContext) {
        guard WCSession.isSupported() else { return }

        currentMainCompanionContext = context
        lastMainCompanionContext = context
        let token = UUID().uuidString
        pendingMainCompanionToken = token
        guard let payload = try? makeMainCompanionSyncPayload(context: context, token: token) else {
            lastMessage = "Main companion sync failed: payload build failed"
            logEvent("push main companion failed", "payload build failed")
            return
        }

        sendMainCompanionPayload(payload, context: context, token: token, reason: "push")
        lastMessage = "Main companion synced"
        logEvent("push main companion", context.displayName)
        scheduleMainCompanionRepush(token: token, selectionID: context.selection.id)
    }

    func queueOfflineMapPackFiles(packID: String, urls: [URL]) {
        guard WCSession.isSupported(), urls.isEmpty == false else { return }

        let session = WCSession.default
        for url in urls {
            let kind = url.lastPathComponent == "manifest.json" ? "manifest" : url.lastPathComponent
            session.transferFile(url, metadata: [
                "offlineMapPackID": packID,
                "offlineMapFileKind": kind
            ])
        }
        queuedTransferCount = session.outstandingUserInfoTransfers.count
        offlineMapTransferStatus[packID] = OfflineMapPackTransferStatus(
            phase: .sending,
            expectedFileCount: urls.count,
            completedFileCount: 0,
            lastQueuedAt: Date(),
            lastCompletedAt: offlineMapTransferStatus[packID]?.lastCompletedAt,
            lastError: nil
        )
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
            self.refreshSessionState(session)
            if let error {
                self.lastMessage = "Activation error: \(error.localizedDescription)"
                self.logEvent("activation failed", error.localizedDescription)
            } else {
                self.outboundApplicationContext = [:]
                self.logEvent("activation ready", self.reachabilityLabel)
                self.resendMainCompanionIfPossible()
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.refreshSessionState(session)
            self.logEvent("reachability", self.reachabilityLabel)
            self.resendMainCompanionIfPossible()
        }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.refreshSessionState(session)
            self.logEvent(
                "watch state",
                "paired:\(session.isPaired) installed:\(session.isWatchAppInstalled) reachable:\(session.isReachable)"
            )
            self.resendMainCompanionIfPossible()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        processPayload(applicationContext, route: "appContext")
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String : Any],
        replyHandler: @escaping ([String : Any]) -> Void
    ) {
        if message["requestMainCompanionContext"] as? Bool == true {
            Task { @MainActor in
                let context = self.currentMainCompanionContext
                    ?? self.lastMainCompanionContext
                    ?? self.currentMainCompanionProvider?()

                guard let context,
                      let payload = try? self.makeMainCompanionSyncPayload(
                        context: context,
                        token: self.pendingMainCompanionToken ?? UUID().uuidString
                      ) else {
                    replyHandler([:])
                    return
                }

                self.lastMainCompanionContext = context
                self.pendingMainCompanionToken = payload["mainCompanionSyncToken"] as? String
                do {
                    try self.updateWatchApplicationContext(adding: payload)
                } catch {
                    self.logEvent("reply main companion failed", error.localizedDescription)
                }
                replyHandler(payload)
                self.logEvent("reply main companion", context.displayName)
            }
            return
        }

        processPayload(message, route: "message+reply")
        replyHandler([:])
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        processPayload(message, route: "message")
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        processPayload(userInfo, route: "userInfo")
    }

    nonisolated func session(_ session: WCSession, didReceive file: WCSessionFile) {
        guard let kindRaw = file.metadata?["workoutSessionPackageKind"] as? String,
              let kind = WorkoutSessionPackageFileKind(rawValue: kindRaw),
              let runID = file.metadata?["workoutSessionRunID"] as? String,
              let archiveID = file.metadata?["workoutSessionArchiveID"] as? String else {
            return
        }

        Task { @MainActor in
            do {
                if let archive = try self.archivePersistence.storeReceivedWorkoutPackageFile(
                    at: file.fileURL,
                    runID: runID,
                    archiveID: archiveID,
                    kind: kind
                ) {
                    self.lastWorkoutArchive = archive
                    self.lastMessage = "Workout archive package synced"
                    self.logEvent("archive package", archive.runID)
                } else {
                    self.logEvent("archive package part", "\(runID):\(kind.rawValue)")
                }
            } catch {
                self.logEvent("archive package failed", error.localizedDescription)
            }
        }
    }

    nonisolated func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: (any Error)?) {
        guard let packID = fileTransfer.file.metadata?["offlineMapPackID"] as? String else { return }

        Task { @MainActor in
            var status = self.offlineMapTransferStatus[packID] ?? OfflineMapPackTransferStatus(
                phase: .idle,
                expectedFileCount: 0,
                completedFileCount: 0,
                lastQueuedAt: nil,
                lastCompletedAt: nil,
                lastError: nil
            )

            if let error {
                status.phase = .failed
                status.lastError = error.localizedDescription
                self.logEvent("map file failed", "\(packID):\(error.localizedDescription)")
            } else {
                status.phase = .sending
                status.completedFileCount += 1
                status.lastError = nil
                self.logEvent("map file delivered", "\(packID):\(status.completedFileCount)/\(status.expectedFileCount)")
            }

            self.offlineMapTransferStatus[packID] = status
        }
    }

    private nonisolated func processPayload(_ payload: [String: Any], route: String) {
        Task { @MainActor in
            self.lastInboundRoute = route
            self.lastInboundPayloadKeys = payload.keys.sorted()
            switch route {
            case "appContext":
                self.receivedApplicationContextCount += 1
            case "message", "message+reply":
                self.receivedMessageCount += 1
            case "userInfo":
                self.receivedUserInfoCount += 1
            default:
                break
            }

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

            if let ids = payload["offlineMapStoredPackIDs"] as? [String] {
                self.watchStoredOfflineMapPackIDs = Set(ids)
                let completedAt = Date()
                for id in ids {
                    let previous = self.offlineMapTransferStatus[id]
                    self.offlineMapTransferStatus[id] = OfflineMapPackTransferStatus(
                        phase: .storedOnWatch,
                        expectedFileCount: previous?.expectedFileCount ?? 0,
                        completedFileCount: previous?.expectedFileCount ?? previous?.completedFileCount ?? 0,
                        lastQueuedAt: previous?.lastQueuedAt,
                        lastCompletedAt: completedAt,
                        lastError: nil
                    )
                }
                self.logEvent("stored map files", "\(ids.count)")
            }

            if payload.keys.contains("selectedOfflineMapPackID") {
                self.selectedOfflineMapPackID = payload["selectedOfflineMapPackID"] as? String
                self.logEvent("selected map", self.selectedOfflineMapPackID ?? "none")
            }

            if payload["watchCompanionPing"] as? Double != nil {
                self.receivedPingCount += 1
                self.logEvent("watch companion ping", "received")
                self.resendMainCompanionIfPossible()
            }

            if let data = payload["mainCompanionContext"] as? Data,
               let context = try? JSONDecoder().decode(WatchMainCompanionContext.self, from: data) {
                self.lastMainCompanionContext = context
                self.logEvent("main companion", context.displayName)
            }

            if let ackToken = payload["mainCompanionAckToken"] as? String {
                self.lastAcknowledgedMainCompanionToken = ackToken
                self.lastAcknowledgedMainCompanionTargetID = payload["mainCompanionAckTargetID"] as? String
                if self.pendingMainCompanionToken == ackToken {
                    self.lastMessage = "Main companion applied on watch"
                    self.logEvent("main companion ack", self.lastAcknowledgedMainCompanionTargetID ?? "unknown")
                }
            }

            self.refreshSessionState(WCSession.default)
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
