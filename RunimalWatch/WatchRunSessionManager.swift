import CoreLocation
import Foundation
import HealthKit
import Observation
import RunimalCore
import WeatherKit
import WatchKit

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
    private let healthStore = HKHealthStore()
    private let locationManager = CLLocationManager()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var routeBuilder: HKWorkoutRouteBuilder?
    private var startedAt: Date?
    private var demoTask: Task<Void, Never>?
    private var routeLocations: [CLLocation] = []
    private var routePreview: [RoutePoint] = []
    private var averageHeartRateAccumulator: [Double] = []
    private var lastStepCountTotal: Double?
    private var lastStepCountDate: Date?
    private var lastResolvedCadence: Int?
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

    var authorizationStatus = "not requested"
    var locationStatusLabel = "not requested"
    var sessionStateLabel = "idle"
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
    var lastSavedWorkoutLabel = "No workout saved yet"
    var claimedWeeklyRewardIDs: Set<String> = []
    var activeWeeklyEffects: [WeeklyRewardEffect] = []
    var recentSessionEvents: [SyncDiagnosticEvent] = []
    var runtimeAlert: WatchRuntimeAlert?
    var isDemoMode: Bool {
        ProcessInfo.processInfo.environment["RUNIMAL_AUTOPLAY_DEMO"] == "1"
    }

    var suddenEventLabel: String {
        activeSuddenEvent?.detail ?? "현재 돌발 목표 없음"
    }

    var cadenceGuideLabel: String {
        "\(targetCadence) spm 메트로놈"
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5
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
            averageHeartRateAccumulator = []
            lastStepCountTotal = nil
            lastStepCountDate = nil
            lastResolvedCadence = nil
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
            logSessionEvent("run start", "HealthKit session started")

            startLocationCaptureIfAuthorized()
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

        do {
            try await workoutBuilder.endCollection(at: endDate)
            let workout = try await finishWorkout(using: workoutBuilder)
            let finalizedSnapshot = finalizedSnapshot(from: workout, builder: workoutBuilder)
            latestSnapshot = finalizedSnapshot
            sessionStateLabel = "finished"
            let reward = RunimalGameEngine.evaluateReward(for: finalizedSnapshot, claimedRewardIDs: claimedWeeklyRewardIDs)
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

            let record = RunimalGameEngine.makeCompletedRunRecord(
                reward: reward,
                snapshot: finalizedSnapshot,
                startedAt: startedAt ?? endDate,
                endedAt: endDate,
                averageHeartRate: averageHeartRate,
                route: routePreview,
                source: "watch-healthkit",
                environmentCondition: environmentCondition,
                rareEventCompleted: rareEventCompleted
            )

            lastReward = reward
            lastCompletedRun = record
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
    }

    func autoplayDemoIfNeeded() {
        guard isDemoMode, demoTask == nil, sessionStateLabel == "idle" else { return }
        startDemoRun()
    }

    var livePet: GeneratedPet {
        RunimalGameEngine.generatePet(from: latestSnapshot, claimedRewardIDs: claimedWeeklyRewardIDs)
    }

    func applyCompanionContext(_ context: CompanionEffectContext) {
        claimedWeeklyRewardIDs = Set(context.claimedRewardIDs)
        activeWeeklyEffects = context.activeEffects
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
        let reward = RunimalGameEngine.evaluateReward(for: latestSnapshot, claimedRewardIDs: claimedWeeklyRewardIDs)
        let endedAt = Date()
        let startedAt = endedAt.addingTimeInterval(-Double(latestSnapshot.elapsedSeconds))
        let record = RunimalGameEngine.makeCompletedRunRecord(
            reward: reward,
            snapshot: latestSnapshot,
            startedAt: startedAt,
            endedAt: endedAt,
            averageHeartRate: latestSnapshot.currentHeartRate,
            route: sampledDemoRoute(from: startedAt),
            source: "watch-demo",
            environmentCondition: environmentCondition,
            rareEventCompleted: rareEventCompleted
        )

        lastReward = reward
        lastCompletedRun = record
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
            case .ended:
                self.sessionStateLabel = "ended"
            case .paused:
                self.sessionStateLabel = "paused"
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
            let heartRate = statisticsValue(for: .heartRate, unit: HKUnit(from: "count/min"))
            let speed = statisticsValue(for: .runningSpeed, unit: HKUnit.meter().unitDivided(by: .second()))
            let stepCount = statisticsValue(for: .stepCount, unit: .count())
            let elapsed = Int(Date().timeIntervalSince(self.startedAt ?? Date()))
            let derivedPace = speed > 0 ? Int(1000 / speed) : nil
            let cadence = self.resolvedCadence(speed: speed, stepCountTotal: stepCount, at: Date())

            if heartRate > 0 {
                self.averageHeartRateAccumulator.append(heartRate)
            }

            self.latestSnapshot = LiveRunSnapshot(
                elapsedSeconds: max(elapsed, 0),
                distanceMeters: distance,
                currentHeartRate: heartRate > 0 ? heartRate : nil,
                cadence: cadence,
                elevationGainM: 0,
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

        evaluateSuddenEventProgress()
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

    private func statisticsValue(for identifier: HKQuantityTypeIdentifier, unit: HKUnit) -> Double {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier),
              let statistics = workoutBuilder?.statistics(for: quantityType),
              let quantity = statistics.mostRecentQuantity() ?? statistics.sumQuantity() else {
            return 0
        }

        return quantity.doubleValue(for: unit)
    }

    private func finalizedSnapshot(from workout: HKWorkout, builder: HKLiveWorkoutBuilder) -> LiveRunSnapshot {
        let durationSeconds = max(Int(workout.duration.rounded()), latestSnapshot.elapsedSeconds)
        let distanceMeters = finalizedDistanceMeters(from: workout, builder: builder)
        let averagePaceSeconds = distanceMeters > 0
            ? Int((Double(durationSeconds) / distanceMeters) * 1000.0)
            : latestSnapshot.averagePaceSeconds
        let cadence = finalizedCadence(builder: builder, durationSeconds: durationSeconds)
        let heartRate = statisticsAverageValue(for: .heartRate, unit: HKUnit.count().unitDivided(by: .minute()), builder: builder)
            ?? latestSnapshot.currentHeartRate

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

        if let quantityType = HKObjectType.quantityType(forIdentifier: .stepCount),
           let statistics = builder.statistics(for: quantityType),
           let quantity = statistics.sumQuantity() {
            let totalSteps = quantity.doubleValue(for: .count())
            let cadence = Int((totalSteps / Double(durationSeconds)) * 60.0)
            if (80...240).contains(cadence) {
                return cadence
            }
        }

        return latestSnapshot.cadence
    }

    private func finalizedAverageHeartRate(using builder: HKLiveWorkoutBuilder) -> Double? {
        if let average = statisticsAverageValue(for: .heartRate, unit: HKUnit.count().unitDivided(by: .minute()), builder: builder) {
            return average
        }

        guard !averageHeartRateAccumulator.isEmpty else { return nil }
        return averageHeartRateAccumulator.reduce(0, +) / Double(averageHeartRateAccumulator.count)
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
        if let stepCadence = cadenceFromSteps(total: stepCountTotal, at: date) {
            lastResolvedCadence = stepCadence
            return stepCadence
        }

        if let speedCadence = cadenceFromSpeed(speed) {
            lastResolvedCadence = speedCadence
            return speedCadence
        }

        return lastResolvedCadence
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

    private func cadenceFromSpeed(_ speed: Double) -> Int? {
        guard speed > 0 else { return nil }

        let paceSeconds = 1000 / speed

        switch paceSeconds {
        case ..<300: return 178
        case ..<330: return 174
        case ..<360: return 168
        default: return 160
        }
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
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            let validLocations = locations.filter { $0.horizontalAccuracy >= 0 }
            guard !validLocations.isEmpty else { return }

            self.routeLocations.append(contentsOf: validLocations)
            self.routePreview = self.sampleRoutePreview(from: self.routeLocations)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.locationStatusLabel = "location failed: \(error.localizedDescription)"
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

    private func startLocationCaptureIfAuthorized() {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            locationStatusLabel = "tracking route"
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
}
