import Foundation
import HealthKit
import Observation

@MainActor
@Observable
final class PhoneHealthKitManager {
    private let healthStore = HKHealthStore()

    var authorizationStatus = "not requested"
    var lastErrorMessage: String?

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
            authorizationStatus = "authorized"
            lastErrorMessage = nil
        } catch {
            authorizationStatus = "failed"
            lastErrorMessage = error.localizedDescription
        }
    }
}
