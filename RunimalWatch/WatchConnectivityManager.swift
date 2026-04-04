import Foundation
import Observation
import RunimalCore
import WatchConnectivity

@MainActor
@Observable
final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    private enum StorageKeys {
        static let syncAuditTrail = "runimal.watch.syncAuditTrail"
    }

    static let shared = WatchConnectivityManager()

    private enum Keys {
        static let mainCompanionContext = "runimal.watch.mainCompanionContext"
    }

    let offlineMapStorage = WatchOfflineMapPackStorage()
    var activationStateLabel = "inactive"
    var reachabilityLabel = "offline"
    var isCompanionAppInstalled = false
    var lastSyncedWorkoutTitle = "No plan yet"
    var claimedRewardIDs: Set<String> = []
    var activeEffects: [WeeklyRewardEffect] = []
    var autoPauseEnabled = true
    var mainCompanionContext: WatchMainCompanionContext?
    var lastRawMainCompanionTargetID: String?
    var lastRawMainCompanionName: String?
    var lastFileMainCompanionTargetID: String?
    var offlineMapPacks: [OfflineMapPackSummary] = []
    var selectedOfflineMapPackID: String?
    var queuedTransferCount = 0
    var recentEvents: [SyncDiagnosticEvent] = []
    var lastInboundRoute = "none"
    var receivedApplicationContextCount = 0
    var receivedMessageCount = 0
    var receivedUserInfoCount = 0
    var receivedFileCount = 0
    var lastInboundPayloadKeys: [String] = []
    private var mainCompanionRetryTask: Task<Void, Never>?
    private var mainCompanionPollingTask: Task<Void, Never>?
    private var outboundApplicationContext: [String: Any] = [:]
    private var hasActivatedSession = false
    private let fileManager = FileManager.default

    override init() {
        super.init()
        loadPersistedAuditTrail()
    }

    private func loadPersistedAuditTrail() {
        guard let data = UserDefaults.standard.data(forKey: StorageKeys.syncAuditTrail),
              let trail = try? JSONDecoder().decode(SyncAuditTrail.self, from: data) else {
            return
        }

        lastInboundRoute = trail.lastInboundRoute
        lastInboundPayloadKeys = trail.lastInboundPayloadKeys
        recentEvents = trail.recentEvents
        lastSyncedWorkoutTitle = trail.lastMessage
    }

    private func persistAuditTrail() {
        let trail = SyncAuditTrail(
            lastMessage: lastSyncedWorkoutTitle,
            lastInboundRoute: lastInboundRoute,
            lastInboundPayloadKeys: lastInboundPayloadKeys,
            recentEvents: recentEvents
        )

        guard let data = try? JSONEncoder().encode(trail) else { return }
        UserDefaults.standard.set(data, forKey: StorageKeys.syncAuditTrail)
    }

    private func refreshSessionState(_ session: WCSession) {
        reachabilityLabel = session.isReachable ? "reachable" : "paired"
        queuedTransferCount = session.outstandingUserInfoTransfers.count
        isCompanionAppInstalled = session.isCompanionAppInstalled
    }

    private func updatePhoneApplicationContext(adding values: [String: Any]) throws {
        for (key, value) in values {
            outboundApplicationContext[key] = value
        }
        try WCSession.default.updateApplicationContext(outboundApplicationContext)
    }

    private func loadPersistedMainCompanionContext() {
        guard let data = UserDefaults.standard.data(forKey: Keys.mainCompanionContext),
              let context = try? JSONDecoder().decode(WatchMainCompanionContext.self, from: data) else {
            return
        }

        if let current = mainCompanionContext, current.updatedAt >= context.updatedAt {
            return
        }

        mainCompanionContext = context
        logEvent("main companion restored", context.displayName)
    }

    private func applyMainCompanionContextIfNewer(_ context: WatchMainCompanionContext) {
        if let current = mainCompanionContext,
           current.selection == context.selection,
           current.updatedAt > context.updatedAt {
            logEvent("main companion ignored", context.displayName)
            return
        }

        mainCompanionRetryTask?.cancel()
        mainCompanionPollingTask?.cancel()
        let mergedContext = mergeMainCompanionContext(current: mainCompanionContext, incoming: context)
        mainCompanionContext = mergedContext
        if let data = try? JSONEncoder().encode(mergedContext) {
            UserDefaults.standard.set(data, forKey: Keys.mainCompanionContext)
        }
        logEvent("main companion", mergedContext.displayName)
    }

    private func mergeMainCompanionContext(
        current: WatchMainCompanionContext?,
        incoming: WatchMainCompanionContext
    ) -> WatchMainCompanionContext {
        guard let current, current.selection == incoming.selection else {
            return incoming
        }

        switch incoming.selection.kind {
        case .pet:
            return WatchMainCompanionContext(
                selection: incoming.selection,
                pet: incoming.pet ?? current.pet,
                petName: incoming.petName ?? current.petName,
                petHeadline: incoming.petHeadline ?? current.petHeadline,
                detailText: incoming.detailText ?? current.detailText,
                companionLevel: incoming.companionLevel ?? current.companionLevel,
                companionStageLabel: incoming.companionStageLabel ?? current.companionStageLabel,
                growthStageIndex: incoming.growthStageIndex ?? current.growthStageIndex,
                mutationBodyStage: incoming.mutationBodyStage ?? current.mutationBodyStage,
                mutationEcologyStage: incoming.mutationEcologyStage ?? current.mutationEcologyStage,
                mutationRhythmStage: incoming.mutationRhythmStage ?? current.mutationRhythmStage,
                mutationBodyBranchID: incoming.mutationBodyBranchID ?? current.mutationBodyBranchID,
                mutationEcologyBranchID: incoming.mutationEcologyBranchID ?? current.mutationEcologyBranchID,
                mutationRhythmBranchID: incoming.mutationRhythmBranchID ?? current.mutationRhythmBranchID,
                updatedAt: incoming.updatedAt
            )
        case .egg:
            return WatchMainCompanionContext(
                selection: incoming.selection,
                detailText: incoming.detailText ?? current.detailText,
                eggShell: incoming.eggShell ?? current.eggShell,
                eggTitle: incoming.eggTitle ?? current.eggTitle,
                eggProgressRatio: incoming.eggProgressRatio ?? current.eggProgressRatio,
                eggReadyToHatch: incoming.eggReadyToHatch || current.eggReadyToHatch,
                updatedAt: incoming.updatedAt
            )
        }
    }

    private func minimalMainCompanionContext(from payload: [String: Any]) -> WatchMainCompanionContext? {
        guard let kindRaw = payload["mainCompanion_kind"] as? String,
              let kind = MainCompanionKind(rawValue: kindRaw),
              let targetID = payload["mainCompanion_targetID"] as? String else {
            return nil
        }

        let updatedAt = Date(timeIntervalSince1970: payload["mainCompanion_updatedAt"] as? Double ?? Date().timeIntervalSince1970)
        let selection = MainCompanionSelection(kind: kind, targetID: targetID)

        switch kind {
        case .pet:
            return WatchMainCompanionContext(
                selection: selection,
                petName: payload["mainCompanion_petName"] as? String,
                petHeadline: payload["mainCompanion_petHeadline"] as? String,
                detailText: payload["mainCompanion_detailText"] as? String,
                companionLevel: payload["mainCompanion_companionLevel"] as? Int,
                companionStageLabel: payload["mainCompanion_companionStageLabel"] as? String,
                updatedAt: updatedAt
            )
        case .egg:
            return WatchMainCompanionContext(
                selection: selection,
                detailText: payload["mainCompanion_detailText"] as? String,
                eggShell: (payload["mainCompanion_eggShell"] as? String).flatMap(EggShellType.init(rawValue:)),
                eggTitle: payload["mainCompanion_eggTitle"] as? String,
                eggProgressRatio: payload["mainCompanion_eggProgressRatio"] as? Double,
                eggReadyToHatch: payload["mainCompanion_eggReadyToHatch"] as? Bool ?? false,
                updatedAt: updatedAt
            )
        }
    }

    private func acknowledgeMainCompanionContext(token: String?, targetID: String) {
        guard WCSession.isSupported(), let token else { return }
        let payload: [String: Any] = [
            "mainCompanionAckToken": token,
            "mainCompanionAckTargetID": targetID,
        ]
        let session = WCSession.default
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil)
        } else {
            session.transferUserInfo(payload)
            queuedTransferCount = session.outstandingUserInfoTransfers.count
        }
        logEvent("main companion ack", targetID)
    }

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
        offlineMapStorage.reloadFromDisk()
        refreshSessionState(session)
        loadPersistedMainCompanionContext()
        if session.receivedApplicationContext.isEmpty == false {
            processPayload(session.receivedApplicationContext, route: "cachedAppContext")
        }
        guard hasActivatedSession == false else {
            logEvent("activation", "WCSession already active")
            bootstrapMainCompanionSync(reason: "activate-repeat")
            return
        }

        hasActivatedSession = true
        session.activate()
        logEvent("activation", "WCSession activate requested")
        bootstrapMainCompanionSync(reason: "activate")
    }

    func refreshMainCompanionContext() {
        loadPersistedMainCompanionContext()
        bootstrapMainCompanionSync(reason: "refresh")
    }

    func resolvedMainCompanionContext() -> WatchMainCompanionContext? {
        loadPersistedMainCompanionContext()
        return mainCompanionContext
    }

    func send(snapshot: LiveRunSnapshot) {
        guard WCSession.isSupported() else { return }

        do {
            let data = try JSONEncoder().encode(snapshot)
            let session = WCSession.default
            if session.isReachable {
                try updatePhoneApplicationContext(adding: ["liveRunSnapshot": data])
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
                try updatePhoneApplicationContext(adding: ["runRewardSummary": data])
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
                try updatePhoneApplicationContext(adding: ["completedRunRecord": data])
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
                try updatePhoneApplicationContext(adding: ["workoutSessionArchive": data])
            }
            session.transferUserInfo(["workoutSessionArchive": data])
            queuedTransferCount = session.outstandingUserInfoTransfers.count
            logEvent("queue archive", workoutArchive.runID)
            try queueWorkoutArchivePackageTransfer(for: workoutArchive)
        } catch {
            lastSyncedWorkoutTitle = "Archive sync failed"
            logEvent("push archive failed", error.localizedDescription)
        }
    }

    private func queueWorkoutArchivePackageTransfer(for archive: WorkoutSessionArchive) throws {
        let session = WCSession.default
        let supportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let packageDirectoryURL = supportURL
            .appendingPathComponent("WorkoutSessionPackages", isDirectory: true)
            .appendingPathComponent("\(archive.runID)-\(archive.id)", isDirectory: true)
        try fileManager.createDirectory(at: packageDirectoryURL, withIntermediateDirectories: true)

        let packageFiles: [(WorkoutSessionPackageFileKind, Data)] = [
            (.summary, try WorkoutSessionPackageCodec.summaryData(for: archive)),
            (.rawTrack, try WorkoutSessionPackageCodec.rawTrackData(for: archive)),
            (.events, try WorkoutSessionPackageCodec.eventsData(for: archive)),
            (.laps, try WorkoutSessionPackageCodec.lapsData(for: archive)),
        ]

        for (kind, data) in packageFiles {
            let fileURL = packageDirectoryURL.appendingPathComponent(kind.filename)
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
            try data.write(to: fileURL, options: .atomic)
            session.transferFile(
                fileURL,
                metadata: [
                    "workoutSessionPackageKind": kind.rawValue,
                    "workoutSessionRunID": archive.runID,
                    "workoutSessionArchiveID": archive.id,
                ]
            )
        }

        logEvent("queue archive package", archive.runID)
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
                self.lastSyncedWorkoutTitle = error.localizedDescription
                self.logEvent("activation failed", error.localizedDescription)
            } else {
                self.logEvent("activation ready", activationState.description)
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.refreshSessionState(session)
            if session.receivedApplicationContext.isEmpty == false {
                self.processPayload(session.receivedApplicationContext, route: "cachedAppContext")
            }
            self.bootstrapMainCompanionSync(reason: "reachability")
            self.logEvent("reachability", self.reachabilityLabel)
        }
    }

    nonisolated func sessionCompanionAppInstalledDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.refreshSessionState(session)
            self.logEvent("phone app state", session.isCompanionAppInstalled ? "installed" : "missing")
            self.bootstrapMainCompanionSync(reason: "companion-state")
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        processPayload(applicationContext, route: "appContext")
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        processPayload(message, route: "message")
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String : Any],
        replyHandler: @escaping ([String : Any]) -> Void
    ) {
        if message["requestMainCompanionContext"] as? Bool == true {
            Task { @MainActor in
                let payload = self.mainCompanionContext?.watchSelectionTransportPayload ?? [:]
                replyHandler(payload)
            }
            return
        }

        processPayload(message, route: "message+reply")

        Task { @MainActor in
            var reply: [String: Any] = [:]
            if let token = message["mainCompanionSyncToken"] as? String {
                reply["mainCompanionAckToken"] = token
            }
            if let targetID = self.lastRawMainCompanionTargetID {
                reply["mainCompanionAckTargetID"] = targetID
                reply["watchSelected_targetID"] = targetID
            }
            if let selectionID = self.mainCompanionContext?.selection.id {
                reply["watchSelected_contextID"] = selectionID
            }
            if let name = self.lastRawMainCompanionName {
                reply["watchSelected_displayName"] = name
            }
            replyHandler(reply)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        processPayload(userInfo, route: "userInfo")
    }

    nonisolated func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let isWatchSelectionFile =
            (file.metadata?["watchSelectionSync"] as? Bool == true) ||
            file.fileURL.lastPathComponent.hasPrefix("runimal-watch-selection-")

        if isWatchSelectionFile {
            Task { @MainActor in
                do {
                    let data = try Data(contentsOf: file.fileURL)
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    guard var payload = json as? [String: Any] else {
                        self.logEvent("watch selection file failed", "invalid payload")
                        return
                    }

                    if payload["mainCompanionSyncToken"] == nil,
                       let token = file.metadata?["mainCompanionSyncToken"] as? String {
                        payload["mainCompanionSyncToken"] = token
                    }

                    self.lastFileMainCompanionTargetID =
                        (payload["watchSelected_targetID"] as? String) ??
                        (payload["mainCompanion_targetID"] as? String)
                    self.receivedFileCount += 1
                    self.logEvent(
                        "watch selection file",
                        self.lastFileMainCompanionTargetID ?? "unknown"
                    )
                    self.processPayload(payload, route: "file")
                } catch {
                    self.logEvent("watch selection file failed", error.localizedDescription)
                }
            }
            return
        }

        guard let packID = file.metadata?["offlineMapPackID"] as? String,
              let kind = file.metadata?["offlineMapFileKind"] as? String else { return }

        Task { @MainActor in
            self.offlineMapStorage.storeTransferredFile(
                tempURL: file.fileURL,
                packID: packID,
                kind: kind
            )
            self.pushOfflineMapStoredPackIDs()
            self.logEvent("map file", "\(packID):\(kind)")
        }
    }

    private nonisolated func processPayload(_ payload: [String: Any], route: String) {
        Task { @MainActor in
            self.lastInboundRoute = route
            self.lastInboundPayloadKeys = payload.keys.sorted()
            switch route {
            case "appContext", "cachedAppContext":
                self.receivedApplicationContextCount += 1
            case "message", "message+reply":
                self.receivedMessageCount += 1
            case "userInfo":
                self.receivedUserInfoCount += 1
            default:
                break
            }

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

            if let rawTargetID = payload["watchSelected_targetID"] as? String {
                self.lastRawMainCompanionTargetID = rawTargetID
                self.lastRawMainCompanionName =
                    payload["watchSelected_petName"] as? String ??
                    payload["watchSelected_eggTitle"] as? String ??
                    payload["watchSelected_displayName"] as? String
            } else if let rawTargetID = payload["mainCompanion_targetID"] as? String {
                self.lastRawMainCompanionTargetID = rawTargetID
                self.lastRawMainCompanionName = payload["mainCompanion_petName"] as? String ?? payload["mainCompanion_eggTitle"] as? String
            }

            if let data = payload["mainCompanionContext"] as? Data,
               let context = try? JSONDecoder().decode(WatchMainCompanionContext.self, from: data) {
                self.applyMainCompanionContextIfNewer(context)
                self.acknowledgeMainCompanionContext(
                    token: payload["mainCompanionSyncToken"] as? String,
                    targetID: context.selection.targetID
                )
            } else if let context = WatchMainCompanionContext(flattenedWCPayload: payload) {
                self.applyMainCompanionContextIfNewer(context)
                self.acknowledgeMainCompanionContext(
                    token: payload["mainCompanionSyncToken"] as? String,
                    targetID: context.selection.targetID
                )
            } else if let rawPayload = payload["mainCompanionContextPayload"] as? [String: Any],
                      let context = WatchMainCompanionContext(wcPayload: rawPayload) {
                self.applyMainCompanionContextIfNewer(context)
                self.acknowledgeMainCompanionContext(
                    token: payload["mainCompanionSyncToken"] as? String,
                    targetID: context.selection.targetID
                )
            } else if let context = WatchMainCompanionContext(watchSelectionTransportPayload: payload) {
                self.applyMainCompanionContextIfNewer(context)
                self.acknowledgeMainCompanionContext(
                    token: payload["mainCompanionSyncToken"] as? String,
                    targetID: context.selection.targetID
                )
            } else if let context = minimalMainCompanionContext(from: payload) {
                self.applyMainCompanionContextIfNewer(context)
                self.acknowledgeMainCompanionContext(
                    token: payload["mainCompanionSyncToken"] as? String,
                    targetID: context.selection.targetID
                )
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

            self.refreshSessionState(WCSession.default)
            self.persistAuditTrail()
        }
    }

    private func pushOfflineMapStoredPackIDs() {
        guard WCSession.isSupported() else { return }
        let ids = Array(offlineMapStorage.storedPackIDs).sorted()
        let payload: [String: Any] = ["offlineMapStoredPackIDs": ids]
        let session = WCSession.default
        do {
            if session.isReachable {
                try updatePhoneApplicationContext(adding: payload)
            } else {
                session.transferUserInfo(payload)
                refreshSessionState(session)
            }
        } catch {
            logEvent("push stored map ids failed", error.localizedDescription)
        }
    }

    private func bootstrapMainCompanionSync(reason: String) {
        pushOfflineMapStoredPackIDs()
        sendWatchCompanionPing(reason: reason)
        requestMainCompanionContextIfPossible()
        scheduleMainCompanionRetry()
        startMainCompanionPolling()
    }

    private func sendWatchCompanionPing(reason: String) {
        guard WCSession.isSupported() else { return }
        let payload: [String: Any] = [
            "watchCompanionPing": Date().timeIntervalSince1970,
            "requestMainCompanionContext": true,
        ]
        let session = WCSession.default
        do {
            try updatePhoneApplicationContext(adding: payload)
        } catch {
            logEvent("watch ping context failed", error.localizedDescription)
        }
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { error in
                Task { @MainActor in
                    self.logEvent("watch ping failed", error.localizedDescription)
                }
            }
        }
        refreshSessionState(session)
        logEvent("watch ping", "\(reason):\(session.isReachable ? "live" : "queued")")
    }

    private func requestMainCompanionContextIfPossible() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.isReachable else { return }

        session.sendMessage(["requestMainCompanionContext": true], replyHandler: { payload in
            self.processPayload(payload, route: "messageReply")
        }, errorHandler: { error in
            Task { @MainActor in
                self.logEvent("request main companion failed", error.localizedDescription)
            }
        })
    }

    private func startMainCompanionPolling() {
        mainCompanionPollingTask?.cancel()
        mainCompanionPollingTask = Task { @MainActor in
            for _ in 0..<5 {
                guard Task.isCancelled == false else { return }
                let session = WCSession.default
                self.loadPersistedMainCompanionContext()
                guard self.mainCompanionContext == nil else { return }
                if session.receivedApplicationContext.isEmpty == false {
                    self.processPayload(session.receivedApplicationContext, route: "cachedAppContext")
                }
                self.sendWatchCompanionPing(reason: "poll")
                self.requestMainCompanionContextIfPossible()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    private func scheduleMainCompanionRetry() {
        mainCompanionRetryTask?.cancel()
        mainCompanionRetryTask = Task { @MainActor in
            for delay in [0.5, 1.5, 3.0, 5.0] {
                try? await Task.sleep(for: .seconds(delay))
                guard Task.isCancelled == false else { return }
                guard self.mainCompanionContext == nil else { return }
                self.requestMainCompanionContextIfPossible()
            }
        }
    }

    private func logEvent(_ title: String, _ detail: String) {
        recentEvents.insert(SyncDiagnosticEvent(title: title, detail: detail), at: 0)
        recentEvents = Array(recentEvents.prefix(12))
        persistAuditTrail()
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
