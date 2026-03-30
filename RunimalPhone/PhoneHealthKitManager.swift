import CoreLocation
import Foundation
import HealthKit
import Observation
import RunimalCore

struct ExternalWorkoutImport: Identifiable {
    let id: String
    let sourceName: String
    let reward: RunRewardSummary
    let record: CompletedRunRecord
    let snapshot: LiveRunSnapshot
}

@MainActor
@Observable
final class PhoneHealthKitManager {
    private enum Keys {
        static let importedExternalWorkoutIDs = "runimal.phone.importedExternalWorkoutIDs"
    }

    private let healthStore = HKHealthStore()
    private let defaults: UserDefaults

    var authorizationStatus = "not requested"
    var importStatusLabel = "수동 가져오기 대기"
    var lastErrorMessage: String?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = "HealthKit unavailable"
            return
        }

        do {
            let shareTypes: Set<HKSampleType> = [HKObjectType.workoutType()]
            let readTypes = Set<HKObjectType>([
                HKObjectType.workoutType(),
                HKSeriesType.workoutRoute(),
                HKObjectType.quantityType(forIdentifier: .heartRate),
                HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
            ]
            .compactMap { $0 })

            try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
            authorizationStatus = authorizationSummary()
            importStatusLabel = "가져오기 준비 완료"
            lastErrorMessage = nil
        } catch {
            authorizationStatus = "failed"
            importStatusLabel = "권한 요청 실패"
            lastErrorMessage = error.localizedDescription
        }
    }

    func syncExternalRuns(
        claimedRewardIDs: Set<String>,
        existingRunsByID: [String: CompletedRunRecord]
    ) async -> [ExternalWorkoutImport] {
        do {
            let workouts = try await recentRunningWorkouts()
            let importedIDs = Set(defaults.stringArray(forKey: Keys.importedExternalWorkoutIDs) ?? [])
            var nextImportedIDs = importedIDs
            var imports: [ExternalWorkoutImport] = []

            for workout in workouts {
                let workoutID = workout.uuid.uuidString.lowercased()
                let bundleID = workout.sourceRevision.source.bundleIdentifier.lowercased()
                let sourceLabel = workout.sourceRevision.source.name

                guard bundleID != "com.jaw.runimal.phone.watch", bundleID != "com.jaw.runimal.phone" else { continue }
                guard supportsImport(workout) else { continue }

                let importedMetrics = try await importedMetrics(from: workout)
                let snapshot = importedMetrics.snapshot
                if let existing = existingRunsByID[workoutID],
                   matchesImportedWorkout(
                    existing,
                    snapshot: snapshot,
                    sourceBundleID: bundleID,
                    sourceLabel: sourceLabel
                   ) {
                    nextImportedIDs.insert(workoutID)
                    continue
                }

                let reward = RunimalGameEngine.evaluateImportedWorkoutReward(
                    for: snapshot,
                    claimedRewardIDs: claimedRewardIDs
                )
                let record = RunimalGameEngine.makeCompletedRunRecord(
                    reward: reward,
                    snapshot: snapshot,
                    startedAt: workout.startDate,
                    endedAt: workout.endDate,
                    averageHeartRate: nil,
                    route: importedMetrics.routePreview,
                    source: "healthkit:\(bundleID)",
                    sourceLabel: sourceLabel,
                    environmentCondition: .unknown,
                    rareEventCompleted: false,
                    id: workoutID
                )

                imports.append(
                    ExternalWorkoutImport(
                        id: workoutID,
                        sourceName: sourceLabel,
                        reward: reward,
                        record: record,
                        snapshot: snapshot
                    )
                )
                nextImportedIDs.insert(workoutID)
            }

            defaults.set(Array(nextImportedIDs).sorted(), forKey: Keys.importedExternalWorkoutIDs)
            importStatusLabel = imports.isEmpty ? "가져올 새 러닝 없음" : "\(imports.count)개 러닝 가져옴"
            lastErrorMessage = nil
            return imports.sorted { $0.record.endedAt > $1.record.endedAt }
        } catch {
            importStatusLabel = "가져오기 실패"
            lastErrorMessage = error.localizedDescription
            return []
        }
    }

    func resetImportedWorkoutIDs() {
        defaults.removeObject(forKey: Keys.importedExternalWorkoutIDs)
        importStatusLabel = "가져오기 목록 초기화"
    }

    private func recentRunningWorkouts() async throws -> [HKWorkout] {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: Calendar.current.date(byAdding: .day, value: -30, to: Date()),
                end: nil,
                options: .strictStartDate
            )
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: 24,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
            }

            healthStore.execute(query)
        }
    }

    private func importedMetrics(from workout: HKWorkout) async throws -> (snapshot: LiveRunSnapshot, routePreview: [RoutePoint]) {
        let locations = try await routeLocations(for: workout)
        let distanceMeters = recordedDistanceMeters(for: workout)
        let duration = max(Int(workout.duration.rounded()), 1)
        let pace = distanceMeters > 0
            ? Int((Double(duration) / (distanceMeters / 1000)).rounded())
            : nil

        return (
            LiveRunSnapshot(
                elapsedSeconds: duration,
                distanceMeters: distanceMeters,
                currentHeartRate: nil,
                cadence: nil,
                elevationGainM: routeElevationGain(from: locations),
                averagePaceSeconds: pace
            ),
            sampledRoutePreview(from: locations)
        )
    }

    private func recordedDistanceMeters(for workout: HKWorkout) -> Double {
        if let totalDistance = workout.totalDistance?.doubleValue(for: .meter()), totalDistance > 0 {
            return totalDistance
        }

        if let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
           let statistics = workout.statistics(for: distanceType),
           let quantity = statistics.sumQuantity() {
            return quantity.doubleValue(for: .meter())
        }

        return workout.totalDistance?.doubleValue(for: .meter()) ?? 0
    }

    private func routeLocations(for workout: HKWorkout) async throws -> [CLLocation] {
        let routes = try await workoutRoutes(for: workout)
        var allLocations: [CLLocation] = []

        for route in routes {
            allLocations.append(contentsOf: try await locations(for: route))
        }

        return allLocations.sorted { $0.timestamp < $1.timestamp }
    }

    private func workoutRoutes(for workout: HKWorkout) async throws -> [HKWorkoutRoute] {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForObjects(from: workout)
            let query = HKSampleQuery(
                sampleType: HKSeriesType.workoutRoute(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: (samples as? [HKWorkoutRoute]) ?? [])
            }

            healthStore.execute(query)
        }
    }

    private func locations(for route: HKWorkoutRoute) async throws -> [CLLocation] {
        try await withCheckedThrowingContinuation { continuation in
            var collected: [CLLocation] = []
            let query = HKWorkoutRouteQuery(route: route) { _, locationsOrNil, done, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if let locationsOrNil {
                    collected.append(contentsOf: locationsOrNil)
                }

                if done {
                    continuation.resume(returning: collected)
                }
            }

            healthStore.execute(query)
        }
    }

    private func routeDistance(from locations: [CLLocation]) -> Double {
        guard locations.count > 1 else { return 0 }

        var total = 0.0
        for index in 1..<locations.count {
            total += locations[index].distance(from: locations[index - 1])
        }
        return total
    }

    private func routeElevationGain(from locations: [CLLocation]) -> Int {
        guard locations.count > 1 else { return 0 }

        var gain = 0.0
        for index in 1..<locations.count {
            let delta = locations[index].altitude - locations[index - 1].altitude
            if delta > 0 {
                gain += delta
            }
        }
        return Int(gain.rounded())
    }

    private func sampledRoutePreview(from locations: [CLLocation]) -> [RoutePoint] {
        guard locations.count > 1 else { return [] }

        let step = max(locations.count / 20, 1)
        var preview: [RoutePoint] = []

        for index in stride(from: 0, to: locations.count, by: step) {
            let location = locations[index]
            preview.append(
                RoutePoint(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    altitude: location.altitude,
                    timestamp: location.timestamp
                )
            )
        }

        if let last = locations.last {
            let endpoint = RoutePoint(
                latitude: last.coordinate.latitude,
                longitude: last.coordinate.longitude,
                altitude: last.altitude,
                timestamp: last.timestamp
            )
            if preview.last != endpoint {
                preview.append(endpoint)
            }
        }

        return preview
    }

    private func supportsImport(_ workout: HKWorkout) -> Bool {
        let supportedTypes: Set<HKWorkoutActivityType> = [
            .running,
            .walking,
            .hiking,
        ]

        if supportedTypes.contains(workout.workoutActivityType) {
            return true
        }

        let distanceMeters = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
        return distanceMeters >= 500
    }

    private func matchesImportedWorkout(
        _ existing: CompletedRunRecord,
        snapshot: LiveRunSnapshot,
        sourceBundleID: String,
        sourceLabel: String
    ) -> Bool {
        existing.source == "healthkit:\(sourceBundleID)" &&
        existing.sourceLabel == sourceLabel &&
        abs(existing.distanceMeters - snapshot.distanceMeters) < 1 &&
        existing.durationSeconds == snapshot.elapsedSeconds &&
        existing.averagePaceSeconds == snapshot.averagePaceSeconds
    }

    private func authorizationSummary() -> String {
        let status = healthStore.authorizationStatus(for: HKObjectType.workoutType())
        switch status {
        case .sharingAuthorized:
            return "authorized"
        case .notDetermined:
            return "not requested"
        case .sharingDenied:
            return "denied"
        @unknown default:
            return "unknown"
        }
    }
}
