import CoreLocation
import Foundation
import HealthKit
import Observation
import RunimalCore

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

    var authorizationStatus = "not requested"
    var locationStatusLabel = "not requested"
    var sessionStateLabel = "idle"
    var latestSnapshot = LiveRunSnapshot(
        elapsedSeconds: 0,
        distanceMeters: 0,
        currentHeartRate: nil,
        cadence: 170,
        elevationGainM: 0,
        averagePaceSeconds: nil
    )
    var lastReward: RunRewardSummary?
    var lastCompletedRun: CompletedRunRecord?
    var lastSavedWorkoutLabel = "No workout saved yet"
    var isDemoMode: Bool {
        ProcessInfo.processInfo.environment["RUNIMAL_AUTOPLAY_DEMO"] == "1"
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5
    }

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = "HealthKit unavailable"
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
            ]
            .compactMap { $0 })

            try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
            authorizationStatus = "authorized"
            requestLocationAuthorizationIfNeeded()
        } catch {
            authorizationStatus = "failed: \(error.localizedDescription)"
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

            startLocationCaptureIfAuthorized()
            session.startActivity(with: startDate)
            try await builder.beginCollection(at: startDate)
        } catch {
            sessionStateLabel = "start failed"
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
            sessionStateLabel = "finished"
            let reward = RunimalGameEngine.evaluateReward(for: latestSnapshot)
            let averageHeartRate = averageHeartRateAccumulator.isEmpty ? nil : averageHeartRateAccumulator.reduce(0, +) / Double(averageHeartRateAccumulator.count)

            if let routeBuilder, !routeLocations.isEmpty {
                try await insertRouteData(routeLocations, into: routeBuilder)
                try await finishRoute(using: routeBuilder, workout: workout)
                lastSavedWorkoutLabel = "Saved workout + route to HealthKit"
            } else {
                lastSavedWorkoutLabel = "Saved workout to HealthKit"
            }

            let record = RunimalGameEngine.makeCompletedRunRecord(
                reward: reward,
                snapshot: latestSnapshot,
                startedAt: startedAt ?? endDate,
                endedAt: endDate,
                averageHeartRate: averageHeartRate,
                route: routePreview,
                source: "watch-healthkit"
            )

            lastReward = reward
            lastCompletedRun = record
        } catch {
            sessionStateLabel = "finish failed"
            lastSavedWorkoutLabel = "Save failed"
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
        RunimalGameEngine.generatePet(from: latestSnapshot)
    }

    private func startDemoRun() {
        authorizationStatus = "demo"
        locationStatusLabel = "demo"
        sessionStateLabel = "running"
        lastReward = nil
        lastCompletedRun = nil
        lastSavedWorkoutLabel = "Demo session recording"
        latestSnapshot = LiveRunSnapshot(
            elapsedSeconds: 0,
            distanceMeters: 0,
            currentHeartRate: 118,
            cadence: 166,
            elevationGainM: 0,
            averagePaceSeconds: 350
        )

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
            }

            finishDemoRun()
        }
    }

    private func finishDemoRun() {
        demoTask?.cancel()
        demoTask = nil
        sessionStateLabel = "finished"
        let reward = RunimalGameEngine.evaluateReward(for: latestSnapshot)
        let endedAt = Date()
        let startedAt = endedAt.addingTimeInterval(-Double(latestSnapshot.elapsedSeconds))
        let record = RunimalGameEngine.makeCompletedRunRecord(
            reward: reward,
            snapshot: latestSnapshot,
            startedAt: startedAt,
            endedAt: endedAt,
            averageHeartRate: latestSnapshot.currentHeartRate,
            route: sampledDemoRoute(from: startedAt),
            source: "watch-demo"
        )

        lastReward = reward
        lastCompletedRun = record
        lastSavedWorkoutLabel = "Demo workout prepared"
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
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        Task { @MainActor in
            let distance = statisticsValue(for: .distanceWalkingRunning, unit: .meter())
            let heartRate = statisticsValue(for: .heartRate, unit: HKUnit(from: "count/min"))
            let speed = statisticsValue(for: .runningSpeed, unit: HKUnit.meter().unitDivided(by: .second()))
            let elapsed = Int(Date().timeIntervalSince(self.startedAt ?? Date()))
            let derivedPace = speed > 0 ? Int(1000 / speed) : nil

            if heartRate > 0 {
                self.averageHeartRateAccumulator.append(heartRate)
            }

            self.latestSnapshot = LiveRunSnapshot(
                elapsedSeconds: max(elapsed, 0),
                distanceMeters: distance,
                currentHeartRate: heartRate > 0 ? heartRate : nil,
                cadence: self.derivedCadence(from: speed),
                elevationGainM: 0,
                averagePaceSeconds: derivedPace
            )
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

    private func derivedCadence(from speed: Double) -> Int {
        guard speed > 0 else { return 170 }

        let paceSeconds = 1000 / speed

        switch paceSeconds {
        case ..<300: return 178
        case ..<330: return 174
        case ..<360: return 168
        default: return 160
        }
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
        (0..<8).map { index in
            RoutePoint(
                latitude: 37.5665 + Double(index) * 0.0007,
                longitude: 126.9780 + sin(Double(index)) * 0.0005,
                altitude: 22 + Double(index),
                timestamp: startDate.addingTimeInterval(Double(index * 45))
            )
        }
    }
}
