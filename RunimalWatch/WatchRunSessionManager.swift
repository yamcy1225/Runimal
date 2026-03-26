import Foundation
import HealthKit
import Observation
import RunimalCore

@MainActor
@Observable
final class WatchRunSessionManager: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var startedAt: Date?

    var authorizationStatus = "not requested"
    var sessionStateLabel = "idle"
    var latestSnapshot = LiveRunSnapshot(
        elapsedSeconds: 0,
        distanceMeters: 0,
        currentHeartRate: nil,
        cadence: 170,
        elevationGainM: 0,
        averagePaceSeconds: nil
    )

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = "HealthKit unavailable"
            return
        }

        do {
            let shareTypes: Set<HKSampleType> = [HKObjectType.workoutType()]
            let readTypes = Set<HKObjectType>([
                HKObjectType.workoutType(),
                HKObjectType.quantityType(forIdentifier: .heartRate),
                HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
                HKObjectType.quantityType(forIdentifier: .runningSpeed),
            ]
            .compactMap { $0 })

            try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
            authorizationStatus = "authorized"
        } catch {
            authorizationStatus = "failed: \(error.localizedDescription)"
        }
    }

    func startRun() async {
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
            sessionStateLabel = "running"

            session.startActivity(with: startDate)
            try await builder.beginCollection(at: startDate)
        } catch {
            sessionStateLabel = "start failed"
        }
    }

    func endRun() async {
        guard let workoutSession, let workoutBuilder else { return }

        let endDate = Date()
        workoutSession.end()

        do {
            try await workoutBuilder.endCollection(at: endDate)
            try await workoutBuilder.finishWorkout()
            sessionStateLabel = "finished"
        } catch {
            sessionStateLabel = "finish failed"
        }

        self.workoutSession = nil
        self.workoutBuilder = nil
    }

    var livePet: GeneratedPet {
        RunimalGameEngine.generatePet(from: latestSnapshot)
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
}
