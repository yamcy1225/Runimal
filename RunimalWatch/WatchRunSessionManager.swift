import CoreLocation
import CoreMotion
import Foundation
import HealthKit
import Observation
import RunimalCore
import WeatherKit
import WatchKit

enum WatchUICaptureScenario: String {
    case dashboard
    case runningCompanion = "running-companion"
    case runningMetrics = "running-metrics"
    case runningPulse = "running-pulse"

    static var current: WatchUICaptureScenario? {
        ProcessInfo.processInfo.environment["RUNIMAL_WATCH_UI_CAPTURE_SCENARIO"].flatMap(Self.init(rawValue:))
    }
}

enum WatchUICaptureFixtures {
    static let captureDate = Calendar(identifier: .gregorian).date(
        from: DateComponents(year: 2026, month: 4, day: 5, hour: 6, minute: 24)
    ) ?? Date(timeIntervalSince1970: 0)

    static let companion = GeneratedPet(
        species: .windrunner,
        element: .light,
        palette: PetSpecies.windrunner.paletteName(rareVariant: .loopSigil),
        rareVariant: .loopSigil,
        explanation: ["watch capture"],
        stats: PetStats(vitality: 13, agility: 16, dexterity: 12, focus: 14, defense: 9)
    )

    static let companionContext = WatchMainCompanionContext(
        selection: MainCompanionSelection(kind: .pet, targetID: "watch-capture-companion"),
        pet: companion,
        petName: companion.displayName,
        petHeadline: "워치에서 실시간으로 반응하는 동행",
        detailText: "러닝 중에는 이 화면이 리듬과 반응을 바로 보여 줍니다.",
        companionLevel: 12,
        companionStageLabel: "유아기",
        growthStageIndex: 1,
        mutationBodyStage: 1,
        mutationEcologyStage: 1,
        mutationRhythmStage: 2,
        mutationRhythmBranchID: "loop-sigil",
        updatedAt: captureDate
    )

    static let activeEffects = [
        WeeklyRewardEffect(id: "growth-feed", title: "Growth Feed", detail: "첫 성장 보상을 또렷하게 고정"),
        WeeklyRewardEffect(id: "field-cycle", title: "Field Cycle", detail: "리듬 반응을 빠르게 드러냄"),
    ]

    static let dashboardSnapshot = LiveRunSnapshot(
        elapsedSeconds: 0,
        distanceMeters: 0,
        currentHeartRate: 102,
        cadence: nil,
        elevationGainM: 0,
        averagePaceSeconds: nil
    )

    static let runningSnapshot = LiveRunSnapshot(
        elapsedSeconds: 23 * 60 + 18,
        distanceMeters: 4860,
        currentHeartRate: 154,
        cadence: 173,
        elevationGainM: 28,
        averagePaceSeconds: 308
    )

    static let runningReaction = MutationRuntimeReactionSnapshot(
        id: "watch-capture-rhythm",
        axis: .rhythm,
        stage: 2,
        title: "리듬 반응",
        detail: "페이스와 케이던스가 맞아 박동 문양이 살아납니다."
    )

    static let runningObjective = LiveCompanionObjectiveSnapshot(
        title: "첫 성장 리듬 유지",
        detail: "3분 더 유지하면 잠재와 성장 신호가 모두 고정됩니다.",
        progress: 0.76
    )

    static let runningPreview = RunimalRunCoreGrowthBalanceEngine.liveInteractionPreview(
        snapshot: runningSnapshot,
        routePointCount: 18,
        gpsAccuracyMeters: 6,
        isGPSFresh: true,
        environmentCondition: .clear,
        rareEventCompleted: false,
        isNightWindow: false,
        mutationReaction: runningReaction,
        objective: runningObjective
    )

    static let runtimeAlert = WatchRuntimeAlert(
        title: "성장 신호 유지",
        detail: "지금 리듬이면 첫 성장 보상이 확정됩니다.",
        kind: .goal
    )
}

struct WatchRuntimeAlert: Identifiable, Equatable {
    enum Kind {
        case goal
        case reward
        case rare
    }

    let id = UUID()
    let title: String
    let detail: String
    let kind: Kind
}

private struct WatchSuddenEvent: Equatable {
    enum Metric {
        case cadence
        case pace
    }

    let id: String
    let title: String
    let detail: String
    let metric: Metric
    let targetValue: Int
    let requiredSeconds: Int
}

@MainActor
@Observable
final class WatchRunSessionManager: NSObject, CLLocationManagerDelegate, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    private enum StorageKeys {
        static let interactionBonusBuffer = "runimal.watch.interactionBonusBuffer"
    }

    private let healthStore = HKHealthStore()
    private let locationManager = CLLocationManager()
    private let pedometer = CMPedometer()
    private let defaults = UserDefaults.standard
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var routeBuilder: HKWorkoutRouteBuilder?
    private var startedAt: Date?
    private var demoTask: Task<Void, Never>?
    private var routeLocations: [CLLocation] = []
    private var routePreview: [RoutePoint] = []
    private var archiveTrackPoints: [WorkoutTrackPoint] = []
    private var sessionEvents: [WorkoutSessionEvent] = []
    private var liveRouteDistanceMeters: Double = 0
    private var liveElevationGainMeters: Double = 0
    private var averageHeartRateAccumulator: [Double] = []
    private var averageCadenceAccumulator: [Double] = []
    private var livePedometerCadence: Int?
    private var lastStepCountTotal: Double?
    private var lastStepCountDate: Date?
    private var lastResolvedCadence: Int?
    private var lastAcceptedRouteTimestamp: Date?
    private var lastGPSUpdateAt: Date?
    private var didTriggerCadenceHaptic = false
    private var dispatchedGoalIDs: Set<String> = []
    private var dispatchedSignalIDs: Set<String> = []
    private var targetCadence = 170
    private var lastMetronomeTickAt: Date?
    private var metronomeBeatCount = 0
    private var activeSuddenEvent: WatchSuddenEvent?
    private var suddenEventProgressStartedAt: Date?
    private var rareEventCompleted = false
    private var environmentCondition: EnvironmentCondition = .unknown
    private var companionVisualState: MutationVisualState = .none
    private var mutationBridgeSnapshots: [MutationRuntimeReactionSnapshot.Axis: MutationBranchBridgeSnapshot] = [:]
    private var lastMutationReactionID: String?
    private var lastMutationReactionAt: Date?
    private var highestProjectedPotentialExperience = 0
    private var interactionBonusBuffer = WatchRunSessionManager.loadInteractionBonusBuffer()
    var autoPauseEnabled = true

    var authorizationStatus = "not requested"
    var locationStatusLabel = "not requested"
    var sessionStateLabel = "idle"
    var latestGPSAccuracyMeters: Double?
    var latestSnapshot = LiveRunSnapshot(
        elapsedSeconds: 0,
        distanceMeters: 0,
        currentHeartRate: nil,
        cadence: nil,
        elevationGainM: 0,
        averagePaceSeconds: nil
    )
    var lastReward: RunRewardSummary?
    var lastCompletedRun: CompletedRunRecord?
    var lastWorkoutArchive: WorkoutSessionArchive?
    var lastSavedWorkoutLabel = "No workout saved yet"
    var claimedWeeklyRewardIDs: Set<String> = []
    var activeWeeklyEffects: [WeeklyRewardEffect] = []
    var recentSessionEvents: [SyncDiagnosticEvent] = []
    var runtimeAlert: WatchRuntimeAlert?
    var mutationReaction: MutationRuntimeReactionSnapshot?
    var liveInteractionPreview: LiveCompanionInteractionPreview = .empty
    var latestInteractionAward: WatchInteractionAwardFeedback?
    var isDemoMode: Bool {
        ProcessInfo.processInfo.environment["RUNIMAL_AUTOPLAY_DEMO"] == "1"
    }

    var pendingHomeBonusLabel: String? {
        sessionStateLabel == "running" ? nil : interactionBonusBuffer.pendingHomeLabel
    }

    var liveInteractionBonusLabel: String? {
        sessionStateLabel == "running" ? interactionBonusBuffer.runCounterLabel : nil
    }

    var suddenEventLabel: String {
        activeSuddenEvent?.detail ?? "현재 돌발 목표 없음"
    }

    var cadenceGuideLabel: String {
        "\(targetCadence) spm 메트로놈"
    }

    var gpsLastUpdatedAt: Date? {
        lastGPSUpdateAt
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5
        persistInteractionBonusBuffer()
    }

    var sessionShell: EggShellType {
        if latestSnapshot.elevationGainM >= 80 { return .stone }
        if (latestSnapshot.cadence ?? 0) >= 170 { return .ember }
        if (latestSnapshot.averagePaceSeconds ?? 999) <= 320 { return .gale }
        return .moss
    }

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = "HealthKit unavailable"
            logSessionEvent("healthkit", "unavailable")
            return
        }

        do {
            let shareTypes: Set<HKSampleType> = [
                HKObjectType.workoutType(),
                HKSeriesType.workoutRoute(),
            ]
            let readTypes = Set<HKObjectType>([
                HKObjectType.workoutType(),
                HKSeriesType.workoutRoute(),
                HKObjectType.quantityType(forIdentifier: .heartRate),
                HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
                HKObjectType.quantityType(forIdentifier: .runningSpeed),
                HKObjectType.quantityType(forIdentifier: .stepCount),
            ]
            .compactMap { $0 })

            try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
            authorizationStatus = "authorized"
            requestLocationAuthorizationIfNeeded()
            logSessionEvent("healthkit", "authorized")
        } catch {
            authorizationStatus = "failed: \(error.localizedDescription)"
            logSessionEvent("healthkit failed", error.localizedDescription)
        }
    }

    func startRun() async {
        if isDemoMode {
            startDemoRun()
            return
        }

        do {
            let configuration = HKWorkoutConfiguration()
            configuration.activityType = .running
            configuration.locationType = .outdoor

            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            session.delegate = self
            builder.delegate = self

            let startDate = Date()
            startedAt = startDate
            workoutSession = session
            workoutBuilder = builder
            routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: .local())
            sessionStateLabel = "running"
            lastReward = nil
            lastCompletedRun = nil
            lastSavedWorkoutLabel = "Saving run..."
            routeLocations = []
            routePreview = []
            archiveTrackPoints = []
            sessionEvents = [WorkoutSessionEvent(kind: .start, timestamp: startDate)]
            liveRouteDistanceMeters = 0
            liveElevationGainMeters = 0
            averageHeartRateAccumulator = []
            averageCadenceAccumulator = []
            livePedometerCadence = nil
            lastStepCountTotal = nil
            lastStepCountDate = nil
            lastResolvedCadence = nil
            lastAcceptedRouteTimestamp = nil
            lastGPSUpdateAt = nil
            latestGPSAccuracyMeters = nil
            didTriggerCadenceHaptic = false
            dispatchedGoalIDs = []
            dispatchedSignalIDs = []
            lastMetronomeTickAt = nil
            metronomeBeatCount = 0
            activeSuddenEvent = generateSuddenEvent()
            suddenEventProgressStartedAt = nil
            rareEventCompleted = false
            environmentCondition = .unknown
            runtimeAlert = nil
            mutationReaction = nil
            lastMutationReactionID = nil
            lastMutationReactionAt = nil
            highestProjectedPotentialExperience = 0
            liveInteractionPreview = .empty
            latestInteractionAward = nil
            interactionBonusBuffer.prepareForRun()
            persistInteractionBonusBuffer()
            logSessionEvent("run start", "HealthKit session started")

            startLocationCaptureIfAuthorized()
            startPedometerUpdates(from: startDate)
            session.startActivity(with: startDate)
            try await builder.beginCollection(at: startDate)
        } catch {
            sessionStateLabel = "start failed: \(error.localizedDescription)"
            lastSavedWorkoutLabel = "Run start failed"
            logSessionEvent("run start failed", error.localizedDescription)
        }
    }

    func endRun() async {
        if demoTask != nil {
            finishDemoRun()
            return
        }

        guard let workoutSession, let workoutBuilder else { return }

        let endDate = Date()
        workoutSession.end()
        stopLocationCapture()
        stopPedometerUpdates()

        do {
            try await workoutBuilder.endCollection(at: endDate)
            let workout = try await finishWorkout(using: workoutBuilder)
            let finalizedSnapshot = finalizedSnapshot(from: workout, builder: workoutBuilder)
            latestSnapshot = finalizedSnapshot
            sessionStateLabel = "finished"
            let baseReward = RunimalGameEngine.evaluateReward(for: finalizedSnapshot, claimedRewardIDs: claimedWeeklyRewardIDs)
            let reward = interactionAdjustedReward(from: baseReward)
            let averageHeartRate = finalizedAverageHeartRate(using: workoutBuilder)
            let environmentCondition = await captureEnvironmentCondition()

            if let routeBuilder, !routeLocations.isEmpty {
                try await insertRouteData(routeLocations, into: routeBuilder)
                try await finishRoute(using: routeBuilder, workout: workout)
                lastSavedWorkoutLabel = "Saved workout + route to HealthKit"
                logSessionEvent("save success", "workout + route saved")
            } else {
                lastSavedWorkoutLabel = "Saved workout to HealthKit"
                logSessionEvent("save success", "workout saved")
            }

            let runID = UUID().uuidString
            let archive = buildWorkoutArchive(
                runID: runID,
                snapshot: finalizedSnapshot,
                averageHeartRate: averageHeartRate,
                averageCadence: finalizedSnapshot.cadence,
                startedAt: startedAt ?? endDate,
                endedAt: endDate,
                source: "watch-healthkit"
            )
            let record = RunimalGameEngine.makeCompletedRunRecord(
                reward: reward,
                snapshot: finalizedSnapshot,
                startedAt: startedAt ?? endDate,
                endedAt: endDate,
                averageHeartRate: averageHeartRate,
                route: archive.effectiveDisplayTrackPoints,
                source: "watch-healthkit",
                environmentCondition: environmentCondition,
                rareEventCompleted: rareEventCompleted,
                id: runID
            )

            lastReward = reward
            lastCompletedRun = record
            lastWorkoutArchive = archive
            emitRuntimeAlert(
                title: "보상 확보",
                detail: "\(reward.coreLabel) · +\(reward.experience) XP",
                kind: .reward
            )
        } catch {
            sessionStateLabel = "finish failed"
            lastSavedWorkoutLabel = "Save failed"
            logSessionEvent("save failed", "HealthKit save pipeline failed")
        }

        self.workoutSession = nil
        self.workoutBuilder = nil
        self.routeBuilder = nil
        mutationReaction = nil
    }

    func autoplayDemoIfNeeded() {
        guard isDemoMode, demoTask == nil, sessionStateLabel == "idle" else { return }
        startDemoRun()
    }

    func applyCaptureScenario(_ scenario: WatchUICaptureScenario) {
        demoTask?.cancel()
        demoTask = nil
        authorizationStatus = "demo"
        locationStatusLabel = "gps stable"
        latestGPSAccuracyMeters = 6
        lastGPSUpdateAt = WatchUICaptureFixtures.captureDate
        lastReward = nil
        lastCompletedRun = nil
        lastWorkoutArchive = nil
        lastSavedWorkoutLabel = "Capture preview ready"
        routePreview = []
        runtimeAlert = nil
        latestInteractionAward = nil

        switch scenario {
        case .dashboard:
            sessionStateLabel = "idle"
            latestSnapshot = WatchUICaptureFixtures.dashboardSnapshot
            mutationReaction = nil
            liveInteractionPreview = .empty
            interactionBonusBuffer.resetForCapture(pendingHomeXP: 1, inRunXP: 0)
        case .runningCompanion, .runningMetrics, .runningPulse:
            sessionStateLabel = "running"
            latestSnapshot = WatchUICaptureFixtures.runningSnapshot
            mutationReaction = WatchUICaptureFixtures.runningReaction
            liveInteractionPreview = WatchUICaptureFixtures.runningPreview
            runtimeAlert = WatchUICaptureFixtures.runtimeAlert
            interactionBonusBuffer.resetForCapture(pendingHomeXP: 1, inRunXP: 3)
        }
    }

    var livePet: GeneratedPet {
        RunimalGameEngine.generatePet(from: latestSnapshot, claimedRewardIDs: claimedWeeklyRewardIDs)
    }

    var liveRoutePreview: [RoutePoint] {
        routePreview
    }

    func applyCompanionContext(_ context: CompanionEffectContext) {
        claimedWeeklyRewardIDs = Set(context.claimedRewardIDs)
        activeWeeklyEffects = context.activeEffects
        updateLiveInteractionPreview()
    }

    func applyMainCompanionContext(_ context: WatchMainCompanionContext?) {
        companionVisualState = MutationVisualState(
            bodyStage: context?.mutationBodyStage ?? 0,
            ecologyStage: context?.mutationEcologyStage ?? 0,
            rhythmStage: context?.mutationRhythmStage ?? 0
        )
        mutationBridgeSnapshots = bridgeSnapshots(from: context)

        if companionVisualState == .none {
            mutationReaction = nil
            lastMutationReactionID = nil
            lastMutationReactionAt = nil
        }

        updateLiveInteractionPreview()
    }

    func setAutoPauseEnabled(_ enabled: Bool) {
        autoPauseEnabled = enabled
    }

    func prepareGPSPreview() {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            startLocationCaptureIfAuthorized(isPreview: true)
        default:
            updateLocationStatus(locationManager.authorizationStatus)
        }
    }

    private func startDemoRun() {
        authorizationStatus = "demo"
        locationStatusLabel = "demo"
        sessionStateLabel = "running"
        lastReward = nil
        lastCompletedRun = nil
        lastSavedWorkoutLabel = "Demo session recording"
        logSessionEvent("demo", "demo run started")
        latestSnapshot = LiveRunSnapshot(
            elapsedSeconds: 0,
            distanceMeters: 0,
            currentHeartRate: 118,
            cadence: 166,
            elevationGainM: 0,
            averagePaceSeconds: 350
        )
        latestGPSAccuracyMeters = 8
        lastGPSUpdateAt = Date()
        didTriggerCadenceHaptic = false
        dispatchedGoalIDs = []
        dispatchedSignalIDs = []
        lastMetronomeTickAt = nil
        metronomeBeatCount = 0
        activeSuddenEvent = generateSuddenEvent()
        suddenEventProgressStartedAt = nil
        rareEventCompleted = false
        environmentCondition = .clear
        runtimeAlert = nil
        mutationReaction = nil
        lastMutationReactionID = nil
        lastMutationReactionAt = nil
        highestProjectedPotentialExperience = 0
        liveInteractionPreview = .empty
        latestInteractionAward = nil
        interactionBonusBuffer.prepareForRun()
        persistInteractionBonusBuffer()

        demoTask?.cancel()
        demoTask = Task { @MainActor in
            for step in 1...8 {
                try? await Task.sleep(for: .seconds(1))

                guard !Task.isCancelled else { return }

                latestSnapshot = LiveRunSnapshot(
                    elapsedSeconds: step * 45,
                    distanceMeters: Double(step) * 420,
                    currentHeartRate: 118 + Double(step * 5),
                    cadence: 166 + step,
                    elevationGainM: step * 3,
                    averagePaceSeconds: max(300, 352 - step * 7)
                )
                triggerCadenceHapticIfNeeded()
                tickCadenceMetronomeIfNeeded()
                evaluateRuntimeAlerts()
            }

            finishDemoRun()
        }
    }

    private func finishDemoRun() {
        demoTask?.cancel()
        demoTask = nil
        sessionStateLabel = "finished"
        let baseReward = RunimalGameEngine.evaluateReward(for: latestSnapshot, claimedRewardIDs: claimedWeeklyRewardIDs)
        let reward = interactionAdjustedReward(from: baseReward)
        let endedAt = Date()
        let startedAt = endedAt.addingTimeInterval(-Double(latestSnapshot.elapsedSeconds))
        let runID = UUID().uuidString
        let archive = buildDemoWorkoutArchive(runID: runID, startedAt: startedAt, endedAt: endedAt)
        let record = RunimalGameEngine.makeCompletedRunRecord(
            reward: reward,
            snapshot: latestSnapshot,
            startedAt: startedAt,
            endedAt: endedAt,
            averageHeartRate: latestSnapshot.currentHeartRate,
            route: archive.effectiveDisplayTrackPoints,
            source: "watch-demo",
            environmentCondition: environmentCondition,
            rareEventCompleted: rareEventCompleted,
            id: runID
        )

        lastReward = reward
        lastCompletedRun = record
        lastWorkoutArchive = archive
        lastSavedWorkoutLabel = "Demo workout prepared"
        logSessionEvent("demo", "demo run finished")
        emitRuntimeAlert(
            title: "보상 확보",
            detail: "\(reward.coreLabel) · +\(reward.experience) XP",
            kind: .reward
        )
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Task { @MainActor in
            switch toState {
            case .running:
                self.sessionStateLabel = "running"
                self.recordSessionEvent(.resume, at: date, detail: "running")
            case .ended:
                self.sessionStateLabel = "ended"
                self.recordSessionEvent(.end, at: date, detail: "ended")
            case .paused:
                self.sessionStateLabel = "paused"
                self.recordSessionEvent(.pause, at: date, detail: "paused")
            default:
                self.sessionStateLabel = "transitioning"
            }
        }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        Task { @MainActor in
            self.sessionStateLabel = "error: \(error.localizedDescription)"
            self.logSessionEvent("session error", error.localizedDescription)
        }
    }

    private func logSessionEvent(_ title: String, _ detail: String) {
        recentSessionEvents.insert(SyncDiagnosticEvent(title: title, detail: detail), at: 0)
        recentSessionEvents = Array(recentSessionEvents.prefix(6))
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        Task { @MainActor in
            let distance = statisticsValue(for: .distanceWalkingRunning, unit: .meter())
            let liveDistance = max(distance, self.liveRouteDistanceMeters)
            let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
            let heartRate = discreteStatisticsValue(for: .heartRate, unit: heartRateUnit)
            let speed = discreteStatisticsValue(for: .runningSpeed, unit: HKUnit.meter().unitDivided(by: .second()))
            let stepCount = cumulativeStatisticsValue(for: .stepCount, unit: .count())
            let elapsed = Int(Date().timeIntervalSince(self.startedAt ?? Date()))
            let derivedPace: Int?
            if speed > 0 {
                derivedPace = Int(1000 / speed)
            } else if liveDistance > 0, elapsed > 0 {
                derivedPace = Int((Double(elapsed) / liveDistance) * 1000.0)
            } else {
                derivedPace = nil
            }
            let cadence = self.resolvedCadence(speed: speed, stepCountTotal: stepCount, at: Date())
            let averagedCadence = self.averagedCadence(fallback: cadence)
            let resolvedHeartRate = heartRate > 0 ? heartRate : self.latestSnapshot.currentHeartRate

            if heartRate > 0 {
                self.averageHeartRateAccumulator.append(heartRate)
                self.averageHeartRateAccumulator = Array(self.averageHeartRateAccumulator.suffix(180))
            }

            self.latestSnapshot = LiveRunSnapshot(
                elapsedSeconds: max(elapsed, 0),
                distanceMeters: liveDistance,
                currentHeartRate: resolvedHeartRate,
                cadence: averagedCadence,
                elevationGainM: Int(self.liveElevationGainMeters.rounded()),
                averagePaceSeconds: derivedPace
            )
            self.triggerCadenceHapticIfNeeded()
            self.tickCadenceMetronomeIfNeeded()
            self.evaluateRuntimeAlerts()
        }
    }

    private func triggerCadenceHapticIfNeeded() {
        guard didTriggerCadenceHaptic == false else { return }
        guard (latestSnapshot.cadence ?? 0) >= 170 else { return }
        didTriggerCadenceHaptic = true
        let cue = shellSignalCue(for: sessionShell)
        WKInterfaceDevice.current().play(cue.haptic)
        logSessionEvent("signal spike", cue.log)
    }

    private func shellSignalCue(for shell: EggShellType) -> (haptic: WKHapticType, log: String) {
        switch shell {
        case .ember:
            return (.directionUp, "ember signal window rising")
        case .gale:
            return (.click, "gale drift window confirmed")
        case .moss:
            return (.success, "moss balance window confirmed")
        case .dusk:
            return (.notification, "dusk interference window confirmed")
        case .stone:
            return (.retry, "stone core window confirmed")
        }
    }

    private func evaluateRuntimeAlerts() {
        let goals = RunimalGameEngine.liveGoals(
            for: latestSnapshot,
            claimedRewardIDs: claimedWeeklyRewardIDs
        )

        if let completedGoal = goals.first(where: { $0.progress >= 1 && dispatchedGoalIDs.contains($0.id) == false }) {
            dispatchedGoalIDs.insert(completedGoal.id)
            emitRuntimeAlert(
                title: "목표 달성",
                detail: completedGoal.title,
                kind: .goal
            )
        }

        let feedback = RunimalGameEngine.evaluateLiveFeedback(
            for: latestSnapshot,
            claimedRewardIDs: claimedWeeklyRewardIDs
        )

        if feedback.label == "Rare Window", dispatchedSignalIDs.contains("rare-window") == false {
            dispatchedSignalIDs.insert("rare-window")
            emitRuntimeAlert(
                title: "희귀 신호 감지",
                detail: "이번 러닝은 희귀 생성 확률이 상승했습니다.",
                kind: .rare
            )
        }

        evaluateMutationReaction()
        evaluateSuddenEventProgress()
        updateLiveInteractionPreview()
    }

    private func evaluateMutationReaction() {
        guard sessionStateLabel == "running" else {
            mutationReaction = nil
            return
        }

        let reaction = MutationRuntimeReactionEngine.reaction(
            for: companionVisualState,
            snapshot: latestSnapshot,
            gpsAccuracyMeters: latestGPSAccuracyMeters,
            isGPSFresh: gpsLastUpdatedAt.map { Date().timeIntervalSince($0) <= 8 } ?? false,
            bridgeSnapshots: mutationBridgeSnapshots
        )

        guard let reaction else {
            mutationReaction = nil
            return
        }

        mutationReaction = reaction
        let now = Date()
        let lastAt = lastMutationReactionAt ?? .distantPast
        let isCooldownComplete = now.timeIntervalSince(lastAt) >= 18
        guard lastMutationReactionID != reaction.id || isCooldownComplete else { return }

        lastMutationReactionID = reaction.id
        lastMutationReactionAt = now
        WKInterfaceDevice.current().play(mutationReactionHaptic(for: reaction.axis))
        logSessionEvent("mutation reaction", reaction.id)
    }

    private func mutationReactionHaptic(for axis: MutationRuntimeReactionSnapshot.Axis) -> WKHapticType {
        switch axis {
        case .body:
            return .directionUp
        case .ecology:
            return .success
        case .rhythm:
            return .click
        }
    }

    private func bridgeSnapshots(
        from context: WatchMainCompanionContext?
    ) -> [MutationRuntimeReactionSnapshot.Axis: MutationBranchBridgeSnapshot] {
        guard let species = context?.pet?.species else { return [:] }

        var snapshots: [MutationRuntimeReactionSnapshot.Axis: MutationBranchBridgeSnapshot] = [:]

        if let bodyBranchID = context?.mutationBodyBranchID,
           let bridge = SpeciesGrowthMutationBridgeEngine.bridge(for: species, axis: .body, branchID: bodyBranchID) {
            snapshots[.body] = bridge
        }
        if let ecologyBranchID = context?.mutationEcologyBranchID,
           let bridge = SpeciesGrowthMutationBridgeEngine.bridge(for: species, axis: .ecology, branchID: ecologyBranchID) {
            snapshots[.ecology] = bridge
        }
        if let rhythmBranchID = context?.mutationRhythmBranchID,
           let bridge = SpeciesGrowthMutationBridgeEngine.bridge(for: species, axis: .rhythm, branchID: rhythmBranchID) {
            snapshots[.rhythm] = bridge
        }

        return snapshots
    }

    private func emitRuntimeAlert(title: String, detail: String, kind: WatchRuntimeAlert.Kind) {
        runtimeAlert = WatchRuntimeAlert(title: title, detail: detail, kind: kind)

        switch kind {
        case .goal:
            RunimalCuePlayer.playAlertCue(kind: .goal)
        case .reward:
            RunimalCuePlayer.playAlertCue(kind: .reward)
        case .rare:
            RunimalCuePlayer.playAlertCue(kind: .rare)
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.4))
            if runtimeAlert?.title == title, runtimeAlert?.detail == detail {
                runtimeAlert = nil
            }
        }
    }

    private func updateLiveInteractionPreview() {
        let preview = RunimalRunCoreGrowthBalanceEngine.liveInteractionPreview(
            snapshot: latestSnapshot,
            routePointCount: routePreview.count,
            gpsAccuracyMeters: latestGPSAccuracyMeters,
            isGPSFresh: gpsLastUpdatedAt.map { Date().timeIntervalSince($0) <= 8 } ?? false,
            environmentCondition: environmentCondition,
            rareEventCompleted: rareEventCompleted,
            isNightWindow: isNightWindow(),
            mutationReaction: mutationReaction,
            objective: liveObjectiveSnapshot()
        )
        liveInteractionPreview = preview

        guard sessionStateLabel == "running" else { return }
        guard preview.projectedPotentialExperience > 0 else { return }
        guard preview.projectedPotentialExperience > highestProjectedPotentialExperience else { return }

        highestProjectedPotentialExperience = preview.projectedPotentialExperience
        guard runtimeAlert == nil else { return }
        emitRuntimeAlert(
            title: "잠재 상승",
            detail: "지금 종료하면 저장 잠재 +\(preview.projectedPotentialExperience) XP 예상",
            kind: .goal
        )
    }

    func registerCompanionInteraction(_ style: WatchCompanionInteractionStyle) -> WatchInteractionAwardFeedback? {
        let source: WatchInteractionAwardSource = sessionStateLabel == "running" ? .running : .home
        let now = Date()
        guard interactionBonusBuffer.canAward(source: source, at: now) else { return nil }

        let resolvedAward = resolvedInteractionAward(for: source, style: style)
        guard let feedback = interactionBonusBuffer.applyAward(resolvedAward, source: source, at: now) else { return nil }

        latestInteractionAward = feedback
        persistInteractionBonusBuffer()
        logSessionEvent("interaction xp", "\(feedback.summaryLabel) · \(style.rawValue)")
        return feedback
    }

    private func resolvedInteractionAward(
        for source: WatchInteractionAwardSource,
        style: WatchCompanionInteractionStyle
    ) -> Int {
        let roll = Int.random(in: 0..<100)

        switch (source, style) {
        case (.home, .tap):
            return roll < 34 ? 1 : 0
        case (.home, .bond):
            return roll < 58 ? 1 : 0
        case (.running, .tap):
            if roll < 14 { return 2 }
            if roll < 48 { return 1 }
            return 0
        case (.running, .bond):
            if roll < 24 { return 2 }
            if roll < 64 { return 1 }
            return 0
        }
    }

    private func interactionAdjustedReward(from reward: RunRewardSummary) -> RunRewardSummary {
        let consumed = interactionBonusBuffer.consumeForCompletedRun()
        latestInteractionAward = nil
        persistInteractionBonusBuffer()
        guard consumed.totalXP > 0 else { return reward }

        var bonusLabels = reward.bonusLabels
        if consumed.homeXP > 0 {
            bonusLabels.append("교감 예열 +\(consumed.homeXP)")
        }
        if consumed.runXP > 0 {
            bonusLabels.append("실시간 교감 +\(consumed.runXP)")
        }
        let uniqueLabels = Array(NSOrderedSet(array: bonusLabels)) as? [String] ?? bonusLabels

        return RunRewardSummary(
            pet: reward.pet,
            coreLabel: reward.coreLabel,
            experience: reward.experience + consumed.totalXP,
            completedQuestCount: reward.completedQuestCount,
            flavorText: reward.flavorText,
            bonusLabels: uniqueLabels
        )
    }

    private func persistInteractionBonusBuffer() {
        if let data = try? JSONEncoder().encode(interactionBonusBuffer) {
            defaults.set(data, forKey: StorageKeys.interactionBonusBuffer)
        }
    }

    private static func loadInteractionBonusBuffer() -> WatchInteractionBonusBuffer {
        guard let data = UserDefaults.standard.data(forKey: StorageKeys.interactionBonusBuffer),
              let decoded = try? JSONDecoder().decode(WatchInteractionBonusBuffer.self, from: data) else {
            return WatchInteractionBonusBuffer()
        }

        return WatchInteractionBonusBuffer(
            pendingHomeXP: decoded.pendingHomeXP,
            inRunXP: 0,
            lastHomeAwardAt: decoded.lastHomeAwardAt,
            lastRunAwardAt: nil
        )
    }

    private func liveObjectiveSnapshot() -> LiveCompanionObjectiveSnapshot? {
        guard let activeSuddenEvent else { return nil }

        let progress: Double
        if rareEventCompleted {
            progress = 1
        } else if let suddenEventProgressStartedAt {
            progress = min(Date().timeIntervalSince(suddenEventProgressStartedAt) / Double(activeSuddenEvent.requiredSeconds), 1)
        } else {
            progress = objectiveWarmupProgress(for: activeSuddenEvent)
        }

        let detail: String
        if rareEventCompleted {
            detail = "돌발 목표를 확보했습니다."
        } else if progress > 0.01 {
            detail = activeSuddenEvent.detail
        } else {
            detail = "조건이 맞는 순간부터 시간이 쌓입니다."
        }

        return LiveCompanionObjectiveSnapshot(
            title: activeSuddenEvent.title,
            detail: detail,
            progress: progress
        )
    }

    private func objectiveWarmupProgress(for event: WatchSuddenEvent) -> Double {
        switch event.metric {
        case .cadence:
            let cadence = latestSnapshot.cadence ?? 0
            return min(Double(cadence) / Double(max(event.targetValue, 1)), 1) * 0.35
        case .pace:
            guard let pace = latestSnapshot.averagePaceSeconds, pace > 0 else { return 0 }
            let ratio = Double(event.targetValue) / Double(pace)
            return min(max(ratio, 0), 1) * 0.35
        }
    }

    private func isNightWindow(referenceDate: Date = Date()) -> Bool {
        let hour = Calendar.current.component(.hour, from: referenceDate)
        return (5...6).contains(hour) || (18...23).contains(hour) || (0...4).contains(hour)
    }

    private func cumulativeStatisticsValue(for identifier: HKQuantityTypeIdentifier, unit: HKUnit) -> Double {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier),
              let statistics = workoutBuilder?.statistics(for: quantityType),
              let quantity = statistics.sumQuantity() ?? statistics.mostRecentQuantity() else {
            return 0
        }

        return quantity.doubleValue(for: unit)
    }

    private func discreteStatisticsValue(for identifier: HKQuantityTypeIdentifier, unit: HKUnit) -> Double {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier),
              let statistics = workoutBuilder?.statistics(for: quantityType),
              let quantity = statistics.mostRecentQuantity() ?? statistics.averageQuantity() else {
            return 0
        }

        return quantity.doubleValue(for: unit)
    }

    private func statisticsValue(for identifier: HKQuantityTypeIdentifier, unit: HKUnit) -> Double {
        switch identifier {
        case .distanceWalkingRunning, .stepCount:
            return cumulativeStatisticsValue(for: identifier, unit: unit)
        default:
            return discreteStatisticsValue(for: identifier, unit: unit)
        }
    }

    private func finalizedSnapshot(from workout: HKWorkout, builder: HKLiveWorkoutBuilder) -> LiveRunSnapshot {
        let durationSeconds = max(Int(workout.duration.rounded()), latestSnapshot.elapsedSeconds)
        let distanceMeters = finalizedDistanceMeters(from: workout, builder: builder)
        let averagePaceSeconds = distanceMeters > 0
            ? Int((Double(durationSeconds) / distanceMeters) * 1000.0)
            : latestSnapshot.averagePaceSeconds
        let cadence = finalizedCadence(builder: builder, durationSeconds: durationSeconds)
        let heartRate = finalizedAverageHeartRate(using: builder) ?? latestSnapshot.currentHeartRate

        return LiveRunSnapshot(
            elapsedSeconds: durationSeconds,
            distanceMeters: distanceMeters,
            currentHeartRate: heartRate,
            cadence: cadence,
            elevationGainM: latestSnapshot.elevationGainM,
            averagePaceSeconds: averagePaceSeconds
        )
    }

    private func finalizedDistanceMeters(from workout: HKWorkout, builder: HKLiveWorkoutBuilder) -> Double {
        if let totalDistance = workout.totalDistance?.doubleValue(for: .meter()), totalDistance > 0 {
            return totalDistance
        }

        if let quantityType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
           let statistics = builder.statistics(for: quantityType),
           let quantity = statistics.sumQuantity() ?? statistics.mostRecentQuantity() {
            let distance = quantity.doubleValue(for: .meter())
            if distance > 0 {
                return distance
            }
        }

        return latestSnapshot.distanceMeters
    }

    private func finalizedCadence(builder: HKLiveWorkoutBuilder, durationSeconds: Int) -> Int? {
        guard durationSeconds > 0 else { return latestSnapshot.cadence }

        let trustedAverageCadence = trustedAverageCadenceSample()
        let stepCountCadence = finalizedCadenceFromStepCount(builder: builder, durationSeconds: durationSeconds)

        if let trustedAverageCadence, let stepCountCadence {
            if abs(trustedAverageCadence - stepCountCadence) <= 12 {
                return Int(((Double(trustedAverageCadence) + Double(stepCountCadence)) / 2.0).rounded())
            }

            if stepCountCadence < 120, trustedAverageCadence >= 145 {
                return trustedAverageCadence
            }

            if trustedAverageCadence >= 170, stepCountCadence <= 160 {
                return stepCountCadence
            }

            return trustedAverageCadence
        }

        if let stepCountCadence {
            return stepCountCadence
        }

        if let trustedAverageCadence {
            return trustedAverageCadence
        }

        return latestSnapshot.cadence
    }

    private func finalizedCadenceFromStepCount(builder: HKLiveWorkoutBuilder, durationSeconds: Int) -> Int? {
        guard durationSeconds > 0,
              let quantityType = HKObjectType.quantityType(forIdentifier: .stepCount),
              let statistics = builder.statistics(for: quantityType),
              let quantity = statistics.sumQuantity() else {
            return nil
        }

        let totalSteps = quantity.doubleValue(for: .count())
        let cadence = Int((totalSteps / Double(durationSeconds)) * 60.0)
        return (80...240).contains(cadence) ? cadence : nil
    }

    private func finalizedAverageHeartRate(using builder: HKLiveWorkoutBuilder) -> Double? {
        if let average = statisticsAverageValue(for: .heartRate, unit: HKUnit.count().unitDivided(by: .minute()), builder: builder),
           average > 0 {
            return average
        }

        guard !averageHeartRateAccumulator.isEmpty else { return nil }
        let average = averageHeartRateAccumulator.reduce(0, +) / Double(averageHeartRateAccumulator.count)
        return average > 0 ? average : nil
    }

    private func statisticsAverageValue(
        for identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        builder: HKLiveWorkoutBuilder
    ) -> Double? {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier),
              let statistics = builder.statistics(for: quantityType),
              let quantity = statistics.averageQuantity() else {
            return nil
        }

        return quantity.doubleValue(for: unit)
    }

    private func resolvedCadence(speed: Double, stepCountTotal: Double, at date: Date) -> Int? {
        if let livePedometerCadence, (80...240).contains(livePedometerCadence) {
            lastResolvedCadence = livePedometerCadence
            return livePedometerCadence
        }

        if let stepCadence = cadenceFromSteps(total: stepCountTotal, at: date) {
            appendTrustedCadenceSample(stepCadence)
            lastResolvedCadence = stepCadence
            return stepCadence
        }

        if let speedCadence = cadenceFromSpeed(speed, elapsedSeconds: latestSnapshot.elapsedSeconds) {
            lastResolvedCadence = speedCadence
            return speedCadence
        }

        return lastResolvedCadence
    }

    private func averagedCadence(fallback: Int?) -> Int? {
        guard !averageCadenceAccumulator.isEmpty else { return fallback }

        let average = trustedAverageCadenceSample()
            ?? Int((averageCadenceAccumulator.reduce(0, +) / Double(averageCadenceAccumulator.count)).rounded())
        if (80...240).contains(average) {
            return average
        }

        return fallback
    }

    private func cadenceFromSteps(total: Double, at date: Date) -> Int? {
        defer {
            lastStepCountTotal = total
            lastStepCountDate = date
        }

        guard let lastStepCountTotal, let lastStepCountDate else { return nil }

        let deltaSteps = total - lastStepCountTotal
        let deltaTime = date.timeIntervalSince(lastStepCountDate)

        guard deltaSteps > 0.5, deltaTime >= 4 else { return nil }

        let cadence = Int((deltaSteps / deltaTime) * 60)
        guard (80...240).contains(cadence) else { return nil }
        return cadence
    }

    private func cadenceFromSpeed(_ speed: Double, elapsedSeconds: Int) -> Int? {
        guard speed > 0.8, elapsedSeconds >= 12 else { return nil }

        let paceSeconds = 1000 / speed

        switch paceSeconds {
        case ..<270: return 184
        case ..<300: return 180
        case ..<330: return 176
        case ..<360: return 170
        case ..<390: return 164
        default: return 158
        }
    }

    private func appendTrustedCadenceSample(_ cadence: Int) {
        guard sessionStateLabel == "running",
              latestSnapshot.elapsedSeconds >= 15,
              (80...240).contains(cadence) else {
            return
        }

        averageCadenceAccumulator.append(Double(cadence))
        averageCadenceAccumulator = Array(averageCadenceAccumulator.suffix(180))
    }

    private func trustedAverageCadenceSample() -> Int? {
        let sorted = averageCadenceAccumulator.sorted()
        guard sorted.isEmpty == false else { return nil }

        if sorted.count < 6 {
            let average = sorted.reduce(0, +) / Double(sorted.count)
            let cadence = Int(average.rounded())
            return (80...240).contains(cadence) ? cadence : nil
        }

        let trimCount = max(1, Int(Double(sorted.count) * 0.1))
        let trimmed = Array(sorted.dropFirst(trimCount).dropLast(trimCount))
        guard trimmed.isEmpty == false else { return nil }

        let average = trimmed.reduce(0, +) / Double(trimmed.count)
        let cadence = Int(average.rounded())
        return (80...240).contains(cadence) ? cadence : nil
    }

    private func tickCadenceMetronomeIfNeeded() {
        guard sessionStateLabel == "running" else { return }

        let interval = max(0.34, 120.0 / Double(targetCadence))
        let now = Date()

        if let lastMetronomeTickAt, now.timeIntervalSince(lastMetronomeTickAt) < interval {
            return
        }

        lastMetronomeTickAt = now
        metronomeBeatCount += 1
        RunimalCuePlayer.playMetronomeTick(shell: sessionShell, isStrongBeat: metronomeBeatCount.isMultiple(of: 4))
    }

    private func generateSuddenEvent() -> WatchSuddenEvent {
        if Bool.random() {
            return WatchSuddenEvent(
                id: "tempo-window",
                title: "돌발 목표",
                detail: "1분간 170spm 이상 유지하면 희귀 공명이 상승합니다.",
                metric: .cadence,
                targetValue: 170,
                requiredSeconds: 60
            )
        }

        return WatchSuddenEvent(
            id: "pace-window",
            title: "돌발 목표",
            detail: "1분간 4:30/km 안쪽 페이스를 유지하면 희귀 공명이 상승합니다.",
            metric: .pace,
            targetValue: 270,
            requiredSeconds: 60
        )
    }

    private func evaluateSuddenEventProgress() {
        guard let activeSuddenEvent, rareEventCompleted == false else { return }

        let meetsTarget: Bool

        switch activeSuddenEvent.metric {
        case .cadence:
            meetsTarget = (latestSnapshot.cadence ?? 0) >= activeSuddenEvent.targetValue
        case .pace:
            meetsTarget = (latestSnapshot.averagePaceSeconds ?? Int.max) <= activeSuddenEvent.targetValue
        }

        if meetsTarget {
            if suddenEventProgressStartedAt == nil {
                suddenEventProgressStartedAt = Date()
            }

            let elapsed = Int(Date().timeIntervalSince(suddenEventProgressStartedAt ?? Date()))
            if elapsed >= activeSuddenEvent.requiredSeconds {
                rareEventCompleted = true
                emitRuntimeAlert(
                    title: "희귀 공명 확보",
                    detail: "돌발 목표 달성으로 희귀 변이 확률이 상승했습니다.",
                    kind: .rare
                )
                logSessionEvent("rare event", activeSuddenEvent.id)
            }
        } else {
            suddenEventProgressStartedAt = nil
        }
    }

    private func captureEnvironmentCondition() async -> EnvironmentCondition {
        let referenceLocation = routeLocations.last ?? locationManager.location
        guard let referenceLocation else { return fallbackEnvironmentCondition() }

        do {
            let weather = try await WeatherService().weather(for: referenceLocation)
            let label = String(describing: weather.currentWeather.condition).lowercased()

            if label.contains("rain") { return .rain }
            if label.contains("snow") || label.contains("sleet") || label.contains("hail") { return .snow }
            if label.contains("wind") { return .wind }
            if label.contains("clear") || label.contains("sun") { return .clear }
            if label.contains("cloud") || label.contains("overcast") || label.contains("fog") { return .overcast }

            let temperature = weather.currentWeather.temperature.value
            if temperature >= 28 { return .heat }
            if temperature <= 2 { return .cold }
            return .unknown
        } catch {
            logSessionEvent("weather fallback", error.localizedDescription)
            return fallbackEnvironmentCondition()
        }
    }

    private func fallbackEnvironmentCondition() -> EnvironmentCondition {
        if let bpm = latestSnapshot.currentHeartRate, bpm >= 165 {
            return .heat
        }
        if sessionShell == .moss {
            return .rain
        }
        return .unknown
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.updateLocationStatus(manager.authorizationStatus)
            if self.sessionStateLabel == "running" {
                self.startLocationCaptureIfAuthorized()
            } else if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
                self.startLocationCaptureIfAuthorized(isPreview: true)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            let validLocations = locations.filter {
                $0.horizontalAccuracy >= 0 && $0.horizontalAccuracy <= 65
            }
            guard !validLocations.isEmpty else { return }

            if let bestLocation = validLocations.min(by: { $0.horizontalAccuracy < $1.horizontalAccuracy }) {
                self.latestGPSAccuracyMeters = bestLocation.horizontalAccuracy
                self.lastGPSUpdateAt = bestLocation.timestamp
                if self.sessionStateLabel != "running" {
                    self.locationStatusLabel = "gps ready"
                }
            }

            guard self.sessionStateLabel == "running" else { return }
            self.absorbRouteLocations(validLocations)
            self.routePreview = self.sampleRoutePreview(from: self.routeLocations)
            self.updateLiveInteractionPreview()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.locationStatusLabel = "location failed: \(error.localizedDescription)"
            self.latestGPSAccuracyMeters = nil
        }
    }

    private func requestLocationAuthorizationIfNeeded() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            updateLocationStatus(locationManager.authorizationStatus)
        }
    }

    private func startLocationCaptureIfAuthorized(isPreview: Bool = false) {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            locationStatusLabel = isPreview ? "gps ready" : "tracking route"
        case .notDetermined:
            requestLocationAuthorizationIfNeeded()
        case .denied, .restricted:
            locationStatusLabel = "location denied"
        @unknown default:
            locationStatusLabel = "location unknown"
        }
    }

    private func stopLocationCapture() {
        locationManager.stopUpdatingLocation()
        if locationStatusLabel == "tracking route" {
            locationStatusLabel = "route captured"
        }
    }

    private func startPedometerUpdates(from startDate: Date) {
        guard CMPedometer.isCadenceAvailable() else { return }

        pedometer.startUpdates(from: startDate) { [weak self] data, _ in
            guard let self, let cadencePerSecond = data?.currentCadence?.doubleValue else { return }

            let cadence = Int((cadencePerSecond * 60.0).rounded())
            guard (80...240).contains(cadence) else { return }

            Task { @MainActor in
                self.livePedometerCadence = cadence
                self.appendTrustedCadenceSample(cadence)
            }
        }
    }

    private func stopPedometerUpdates() {
        pedometer.stopUpdates()
    }

    private func updateLocationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationStatusLabel = "requesting"
        case .restricted:
            locationStatusLabel = "restricted"
        case .denied:
            locationStatusLabel = "denied"
        case .authorizedAlways, .authorizedWhenInUse:
            locationStatusLabel = "authorized"
        @unknown default:
            locationStatusLabel = "unknown"
        }
    }

    private func finishWorkout(using builder: HKLiveWorkoutBuilder) async throws -> HKWorkout {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKWorkout, Error>) in
            builder.finishWorkout { workout, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let workout else {
                    continuation.resume(throwing: NSError(domain: "RunimalWatch", code: 10, userInfo: nil))
                    return
                }

                continuation.resume(returning: workout)
            }
        }
    }

    private func insertRouteData(_ locations: [CLLocation], into builder: HKWorkoutRouteBuilder) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.insertRouteData(locations) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: NSError(domain: "RunimalWatch", code: 11, userInfo: nil))
                }
            }
        }
    }

    private func finishRoute(using builder: HKWorkoutRouteBuilder, workout: HKWorkout) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.finishRoute(with: workout, metadata: nil) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: ())
            }
        }
    }

    private func sampleRoutePreview(from locations: [CLLocation]) -> [RoutePoint] {
        guard !locations.isEmpty else { return [] }

        let targetCount = 24
        let stride = max(1, locations.count / targetCount)

        return locations.enumerated().compactMap { index, location in
            guard index.isMultiple(of: stride) || index == locations.count - 1 else {
                return nil
            }

            return RoutePoint(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                altitude: location.altitude,
                timestamp: location.timestamp
            )
        }
    }

    private func sampledDemoRoute(from startDate: Date) -> [RoutePoint] {
        var route: [RoutePoint] = []
        route.reserveCapacity(8)

        for index in 0..<8 {
            let step = Double(index)
            let point = RoutePoint(
                latitude: 37.5665 + (step * 0.0007),
                longitude: 126.9780 + (Foundation.sin(step) * 0.0005),
                altitude: 22 + step,
                timestamp: startDate.addingTimeInterval(step * 45)
            )
            route.append(point)
        }

        return route
    }

    private func absorbRouteLocations(_ locations: [CLLocation]) {
        for location in locations {
            guard location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 65 else { continue }
            guard let acceptedLocation = validatedRouteLocation(location) else { continue }

            if let previous = routeLocations.last {
                let segment = acceptedLocation.distance(from: previous)
                let delta = acceptedLocation.timestamp.timeIntervalSince(previous.timestamp)
                if isUsableDistanceSegment(
                    distance: segment,
                    delta: delta,
                    current: acceptedLocation,
                    previous: previous
                ) {
                    liveRouteDistanceMeters += segment
                }

                let climb = acceptedLocation.altitude - previous.altitude
                if climb > 0.5, abs(climb) <= 40 {
                    liveElevationGainMeters += climb
                }
            }

            routeLocations.append(acceptedLocation)
            lastAcceptedRouteTimestamp = acceptedLocation.timestamp
            lastGPSUpdateAt = acceptedLocation.timestamp
            latestGPSAccuracyMeters = acceptedLocation.horizontalAccuracy
            archiveTrackPoints.append(
                WorkoutTrackPoint(
                    timestamp: acceptedLocation.timestamp,
                    latitude: acceptedLocation.coordinate.latitude,
                    longitude: acceptedLocation.coordinate.longitude,
                    altitude: acceptedLocation.altitude,
                    horizontalAccuracy: acceptedLocation.horizontalAccuracy,
                    speedMetersPerSecond: acceptedLocation.speed >= 0 ? acceptedLocation.speed : nil,
                    heartRate: latestSnapshot.currentHeartRate,
                    cadence: latestSnapshot.cadence,
                    gpsPoor: acceptedLocation.horizontalAccuracy > 30,
                    paused: sessionStateLabel == "paused"
                )
            )
        }
    }

    private func buildWorkoutArchive(
        runID: String,
        snapshot: LiveRunSnapshot,
        averageHeartRate: Double?,
        averageCadence: Int?,
        startedAt: Date,
        endedAt: Date,
        source: String
    ) -> WorkoutSessionArchive {
        let reconciledDistanceMeters = reconciledArchiveDistanceMeters(snapshotDistance: snapshot.distanceMeters)
        let inferredMovingTime = inferMovingTimeSeconds(from: archiveTrackPoints)
        let inferredPace = averagePaceSeconds(
            distanceMeters: reconciledDistanceMeters,
            durationSeconds: snapshot.elapsedSeconds
        ) ?? snapshot.averagePaceSeconds
        let baseArchive = WorkoutSessionArchive(
            runID: runID,
            startedAt: startedAt,
            endedAt: endedAt,
            elapsedTimeSeconds: snapshot.elapsedSeconds,
            timerTimeSeconds: snapshot.elapsedSeconds,
            movingTimeSeconds: inferredMovingTime,
            distanceMeters: reconciledDistanceMeters,
            averageHeartRate: averageHeartRate,
            averageCadence: averageCadence,
            averagePaceSeconds: inferredPace,
            elevationGainM: snapshot.elevationGainM,
            source: source,
            trackPoints: archiveTrackPoints,
            laps: [WorkoutLap(
            index: 1,
            startTime: startedAt,
            endTime: endedAt,
            distanceMeters: reconciledDistanceMeters,
            timerTimeSeconds: snapshot.elapsedSeconds,
            averageHeartRate: averageHeartRate,
            averageCadence: averageCadence,
            averagePaceSeconds: inferredPace,
            elevationGainM: snapshot.elevationGainM
        )],
            events: normalizedSessionEvents(startedAt: startedAt, endedAt: endedAt)
        )

        return WorkoutArchiveCanonicalizer.canonicalize(
            baseArchive,
            configuration: workoutAnalysisConfiguration()
        )
    }

    private func buildDemoWorkoutArchive(runID: String, startedAt: Date, endedAt: Date) -> WorkoutSessionArchive {
        let points = sampledDemoRoute(from: startedAt).map {
            WorkoutTrackPoint(
                timestamp: $0.timestamp,
                latitude: $0.latitude,
                longitude: $0.longitude,
                altitude: $0.altitude,
                horizontalAccuracy: 8,
                speedMetersPerSecond: nil,
                heartRate: latestSnapshot.currentHeartRate,
                cadence: latestSnapshot.cadence,
                gpsPoor: false,
                paused: false
            )
        }

        let archive = WorkoutSessionArchive(
            runID: runID,
            startedAt: startedAt,
            endedAt: endedAt,
            elapsedTimeSeconds: latestSnapshot.elapsedSeconds,
            timerTimeSeconds: latestSnapshot.elapsedSeconds,
            movingTimeSeconds: latestSnapshot.elapsedSeconds,
            distanceMeters: latestSnapshot.distanceMeters,
            averageHeartRate: latestSnapshot.currentHeartRate,
            averageCadence: latestSnapshot.cadence,
            averagePaceSeconds: latestSnapshot.averagePaceSeconds,
            elevationGainM: latestSnapshot.elevationGainM,
            source: "watch-demo",
            trackPoints: points,
            laps: [WorkoutLap(
            index: 1,
            startTime: startedAt,
            endTime: endedAt,
            distanceMeters: latestSnapshot.distanceMeters,
            timerTimeSeconds: latestSnapshot.elapsedSeconds,
            averageHeartRate: latestSnapshot.currentHeartRate,
            averageCadence: latestSnapshot.cadence,
            averagePaceSeconds: latestSnapshot.averagePaceSeconds,
            elevationGainM: latestSnapshot.elevationGainM
        )],
            events: normalizedSessionEvents(startedAt: startedAt, endedAt: endedAt)
        )

        return WorkoutArchiveCanonicalizer.canonicalize(
            archive,
            configuration: workoutAnalysisConfiguration()
        )
    }

    private func workoutAnalysisConfiguration() -> WorkoutArchiveAnalyzer.Configuration {
        if autoPauseEnabled {
            return .init()
        }

        return .init(
            lapDistanceMeters: 1_000,
            pauseSpeedThreshold: 0.5,
            pauseHoldSeconds: .infinity,
            resumeSpeedThreshold: 1.0,
            resumeHoldSeconds: .infinity,
            movingSpeedThreshold: 0.5
        )
    }

    private func inferMovingTimeSeconds(from points: [WorkoutTrackPoint]) -> Int {
        guard points.count > 1 else { return latestSnapshot.elapsedSeconds }
        var total: TimeInterval = 0
        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let delta = current.timestamp.timeIntervalSince(previous.timestamp)
            guard delta > 0 else { continue }
            let segmentDistance = CLLocation(latitude: current.latitude, longitude: current.longitude)
                .distance(from: CLLocation(latitude: previous.latitude, longitude: previous.longitude))
            let resolvedSpeed = current.speedMetersPerSecond
                ?? previous.speedMetersPerSecond
                ?? (segmentDistance / delta)

            if current.paused == false,
               current.gpsPoor == false,
               segmentDistance >= 1,
               segmentDistance <= 120,
               resolvedSpeed >= 0.5,
               resolvedSpeed <= 8.5 {
                total += delta
            }
        }
        return max(Int(total.rounded()), 0)
    }

    private func validatedRouteLocation(_ location: CLLocation) -> CLLocation? {
        if let lastAcceptedRouteTimestamp, location.timestamp <= lastAcceptedRouteTimestamp {
            return nil
        }

        guard let previous = routeLocations.last else { return location }

        let delta = location.timestamp.timeIntervalSince(previous.timestamp)
        guard delta > 0 else { return nil }

        let segment = location.distance(from: previous)
        if segment < 0.8, delta < 1.2 {
            return nil
        }

        let impliedSpeed = segment / delta
        if impliedSpeed > 8.5, location.horizontalAccuracy > 18 {
            return nil
        }

        if segment > 120 {
            return nil
        }

        return location
    }

    private func isUsableDistanceSegment(distance: Double, delta: TimeInterval, current: CLLocation, previous: CLLocation) -> Bool {
        guard delta > 0 else { return false }
        guard distance >= 1, distance <= 120 else { return false }

        let speed = current.speed >= 0 ? current.speed : (distance / delta)
        guard speed <= 8.5 else { return false }

        if current.horizontalAccuracy > 30 || previous.horizontalAccuracy > 30 {
            return distance >= 3
        }

        return true
    }

    private func reconciledArchiveDistanceMeters(snapshotDistance: Double) -> Double {
        let routeDistance = inferredRouteDistanceMeters(from: archiveTrackPoints)
        guard routeDistance > 0 else { return snapshotDistance }
        guard snapshotDistance > 0 else { return routeDistance }

        let deltaRatio = abs(routeDistance - snapshotDistance) / snapshotDistance
        if deltaRatio <= 0.08 {
            return routeDistance
        }

        return snapshotDistance
    }

    private func inferredRouteDistanceMeters(from points: [WorkoutTrackPoint]) -> Double {
        guard points.count > 1 else { return 0 }
        var total: Double = 0

        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            guard current.gpsPoor == false else { continue }

            let previousLocation = CLLocation(latitude: previous.latitude, longitude: previous.longitude)
            let currentLocation = CLLocation(latitude: current.latitude, longitude: current.longitude)
            let distance = currentLocation.distance(from: previousLocation)
            let delta = current.timestamp.timeIntervalSince(previous.timestamp)

            if delta > 0, distance >= 1, distance <= 120, (distance / delta) <= 8.5 {
                total += distance
            }
        }

        return total
    }

    private func averagePaceSeconds(distanceMeters: Double, durationSeconds: Int) -> Int? {
        guard distanceMeters > 0, durationSeconds > 0 else { return nil }
        return Int((Double(durationSeconds) / distanceMeters * 1000.0).rounded())
    }

    private func recordSessionEvent(_ kind: WorkoutEventKind, at date: Date, detail: String?) {
        sessionEvents.append(WorkoutSessionEvent(kind: kind, timestamp: date, detail: detail))
    }

    private func normalizedSessionEvents(startedAt: Date, endedAt: Date) -> [WorkoutSessionEvent] {
        var events = sessionEvents
        if events.contains(where: { $0.kind == .start }) == false {
            events.insert(WorkoutSessionEvent(kind: .start, timestamp: startedAt), at: 0)
        }
        if events.contains(where: { $0.kind == .end }) == false {
            events.append(WorkoutSessionEvent(kind: .end, timestamp: endedAt))
        }
        return events.sorted { $0.timestamp < $1.timestamp }
    }
}
