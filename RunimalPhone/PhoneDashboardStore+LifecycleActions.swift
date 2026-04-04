import Foundation
import RunimalCore

@MainActor
extension PhoneDashboardStore {
    func activateConnectivity() {
        connectivity.currentMainCompanionContext = watchMainCompanionContext
        connectivity.currentMainCompanionProvider = { [weak self = self] in
            self?.watchMainCompanionContext
        }
        connectivity.activate()
        syncCompanionEffects()
        syncMainCompanionSelection()
        connectivity.pushAutoPauseEnabled(progress.autoPauseEnabled)
        connectivity.pushOfflineMapPackCatalog(offlineMaps.packs)
        connectivity.pushSelectedOfflineMapPackID(offlineMaps.selectedPackID)
    }

    func bootstrap() {
        let availablePackIDs = DefaultWorldContent.packSummaries.map(\.packID)
        worldPackManifest.load(availablePackIDs: availablePackIDs)
        activeWorldPackIDs = worldPackManifest.enabledPackIDs
        progress.load()
        offlineMaps.load()
        let shouldRestoreRemoteSnapshot = progress.hasPersistedState
        let vaultSnapshot = shouldRestoreRemoteSnapshot ? vault.loadSnapshot() : nil
        let cloudSnapshot = shouldRestoreRemoteSnapshot ? cloudMirror.restoreIfAvailable() : nil

        if let vaultSnapshot, let cloudSnapshot {
            progress.restore(from: RunimalSnapshotMergeEngine.merge(vaultSnapshot, cloudSnapshot))
        } else if let single = vaultSnapshot ?? cloudSnapshot {
            progress.restore(from: single)
        }
        progress.seedIfNeeded(from: runArchive)
        progress.evaluateSanctuaryRewardIfNeeded()
        persistVault()
        cloudMirror.validateRuntime()
        telemetry.log("bootstrap", detail: "store initialized")
    }

    func toggleWorldPack(_ packID: String) {
        let availablePackIDs = DefaultWorldContent.packSummaries.map(\.packID)
        worldPackManifest.toggle(packID: packID, availablePackIDs: availablePackIDs)
        activeWorldPackIDs = worldPackManifest.enabledPackIDs
        syncMainCompanionSelection()
        telemetry.log("toggle_world_pack", detail: "\(packID):\(activeWorldPackIDs.joined(separator: ","))")
    }

    func setAutoPauseEnabled(_ enabled: Bool) {
        progress.setAutoPauseEnabled(enabled)
        connectivity.pushAutoPauseEnabled(enabled)
        telemetry.log("auto_pause_toggled", detail: enabled ? "on" : "off")
        persistVault()
    }

    func registerOfflineMapPack(_ pack: OfflineMapPackSummary) {
        offlineMaps.prepareLocalStorage(for: pack)
        offlineMaps.selectPack(id: pack.id)
        offlineMaps.markTransferredToWatch(ids: [pack.id])
        connectivity.pushOfflineMapPackCatalog(offlineMaps.packs)
        connectivity.pushSelectedOfflineMapPackID(offlineMaps.selectedPackID)
        sendOfflineMapPackFiles(id: pack.id)
        telemetry.log("offline_map_pack_registered", detail: pack.title)
    }

    func setSelectedOfflineMapPack(id: String) {
        offlineMaps.selectPack(id: id)
        connectivity.pushSelectedOfflineMapPackID(offlineMaps.selectedPackID)
        telemetry.log("offline_map_pack_selected", detail: id)
    }

    func syncWorkoutPlan() async {
        let suggestion = await planner.syncSuggestedWorkout(for: pet)
        connectivity.pushSuggestedWorkout(suggestion)
        telemetry.log("sync_workout_plan", detail: suggestion.title)
    }

    func syncCompanionEffects() {
        let context = CompanionEffectContext(
            claimedRewardIDs: Array(claimedWeeklyRewardIDs).sorted(),
            activeEffects: activeWeeklyEffects
        )
        connectivity.pushCompanionEffects(context)
    }

    func persistVault() {
        let snapshot = progress.snapshot()
        vault.save(snapshot: snapshot)
        cloudMirror.mirror(snapshot: snapshot)
    }

    func runSummary(from record: CompletedRunRecord) -> RunSummary {
        let paceSeconds = record.averagePaceSeconds ?? Int(
            (Double(max(record.durationSeconds, 1)) / max(record.distanceMeters / 1000, 1)).rounded()
        )
        let cadence = record.cadence ?? currentCadenceFallback

        return RunSummary(
            distanceKm: record.distanceMeters / 1000,
            averagePaceSeconds: paceSeconds,
            cadence: cadence,
            elevationGainM: record.elevationGainM,
            variability: routeVariability(for: record.route),
            aura: aura(for: record.startedAt),
            shape: shape(for: record.route),
            environmentCondition: record.environmentCondition,
            rareEventCompleted: record.rareEventCompleted
        )
    }

    var currentCadenceFallback: Int {
        latestCompletedRun?.cadence ?? summary.cadence
    }

    func aura(for date: Date) -> RunTimeAura {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<11:
            return .dawn
        case 11..<17:
            return .day
        case 17..<21:
            return .dusk
        default:
            return .night
        }
    }

    func shape(for route: [RoutePoint]) -> RouteShape {
        guard route.count > 2, let first = route.first, let last = route.last else {
            return .freeform
        }

        let closureMeters = hypot(first.latitude - last.latitude, first.longitude - last.longitude) * 111_000
        if closureMeters < 120 {
            return .loop
        }
        return .outAndBack
    }

    func routeVariability(for route: [RoutePoint]) -> Double {
        guard route.count > 4 else { return summary.variability }

        let latitudes = route.map(\.latitude)
        let longitudes = route.map(\.longitude)
        let latSpan = (latitudes.max() ?? 0) - (latitudes.min() ?? 0)
        let lonSpan = (longitudes.max() ?? 0) - (longitudes.min() ?? 0)
        let spread = max(latSpan, lonSpan) * 111_000
        return min(max(spread / 5000, 0.04), 0.24)
    }
}
