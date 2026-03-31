import Foundation
import Testing
@testable import RunimalCore

struct SpeciesMutationUnlockEngineTests {
    @Test
    func windrunnerLongRiverRunsResolveToCruiseForm() {
        let runs = [
            run(id: "w1", distanceKm: 10.2, pace: 355, cadence: 171, elevation: 28, aura: .day, shape: .outAndBack, environment: .clear),
            run(id: "w2", distanceKm: 9.4, pace: 362, cadence: 170, elevation: 34, aura: .dawn, shape: .outAndBack, environment: .wind),
            run(id: "w3", distanceKm: 8.7, pace: 368, cadence: 172, elevation: 30, aura: .day, shape: .loop, environment: .overcast),
        ]

        let result = SpeciesMutationUnlockEngine.resolveForm(for: runs, preferredSpecies: .windrunner)

        #expect(result?.speciesID == "windrunner")
        #expect(result?.bodyBranchID == "aero-swift")
        #expect(result?.ecologyBranchID == "river-open")
        #expect(result?.rhythmBranchID == "draft-route")
    }

    @Test
    func stonebackClimbRunsResolveToStormSlopeForm() {
        let runs = [
            run(id: "s1", distanceKm: 7.2, pace: 430, cadence: 160, elevation: 152, aura: .day, shape: .outAndBack, environment: .wind),
            run(id: "s2", distanceKm: 6.8, pace: 442, cadence: 159, elevation: 168, aura: .dusk, shape: .maze, environment: .cold),
            run(id: "s3", distanceKm: 7.5, pace: 425, cadence: 162, elevation: 174, aura: .day, shape: .outAndBack, environment: .wind),
        ]

        let result = SpeciesMutationUnlockEngine.resolveForm(for: runs, preferredSpecies: .stoneback)

        #expect(result?.speciesID == "stoneback")
        #expect(result?.bodyBranchID == "summit-core")
        #expect(result?.ecologyBranchID == "storm-slope")
        #expect(result?.rhythmBranchID == "climb-pulse")
    }

    @Test
    func sparkfangNightSignalsResolveToTwilightCapableForm() {
        let runs = [
            run(id: "f1", distanceKm: 4.2, pace: 322, cadence: 178, elevation: 18, aura: .night, shape: .maze, environment: .clear, rare: true),
            run(id: "f2", distanceKm: 4.6, pace: 334, cadence: 177, elevation: 24, aura: .night, shape: .maze, environment: .heat),
            run(id: "f3", distanceKm: 3.9, pace: 328, cadence: 179, elevation: 20, aura: .dusk, shape: .freeform, environment: .clear),
        ]

        let result = SpeciesMutationUnlockEngine.resolveForm(for: runs, preferredSpecies: .shadebit)

        #expect(result?.speciesID == "sparkfang")
        #expect(result?.bodyBranchID == "burst-swift")
        #expect(result?.ecologyBranchID == "signal-track")
        #expect(result?.rhythmBranchID == "surge-fang")
    }

    @Test
    func seedleHabitRunsResolveToGrowthLoop() {
        let runs = [
            run(id: "e1", distanceKm: 3.2, pace: 470, cadence: 166, elevation: 16, aura: .dusk, shape: .loop, environment: .overcast),
            run(id: "e2", distanceKm: 3.6, pace: 452, cadence: 167, elevation: 20, aura: .dusk, shape: .loop, environment: .clear),
            run(id: "e3", distanceKm: 4.1, pace: 445, cadence: 168, elevation: 18, aura: .night, shape: .outAndBack, environment: .unknown),
            run(id: "e4", distanceKm: 4.5, pace: 438, cadence: 169, elevation: 22, aura: .dusk, shape: .loop, environment: .clear),
        ]

        let result = SpeciesMutationUnlockEngine.resolveForm(for: runs, preferredSpecies: .seedle)

        #expect(result?.speciesID == "seedle")
        #expect(result?.bodyBranchID == "root-guard")
        #expect(result?.ecologyBranchID == "twilight-bud")
        #expect(result?.rhythmBranchID == "grow-loop")
    }

    @Test
    func mutationSnapshotCarriesResolvedFormFields() {
        let runs = [
            run(id: "m1", distanceKm: 8.1, pace: 360, cadence: 171, elevation: 32, aura: .day, shape: .outAndBack, environment: .clear),
            run(id: "m2", distanceKm: 8.9, pace: 356, cadence: 172, elevation: 28, aura: .day, shape: .outAndBack, environment: .wind),
        ]

        let result = SpeciesMutationUnlockEngine.resolveForm(for: runs, preferredSpecies: .windrunner)
        let snapshot = result?.snapshot

        #expect(snapshot?.speciesID == "windrunner")
        #expect(snapshot?.formID == result?.form.formID)
        #expect(snapshot?.shortLabel == result?.form.shortLabel)
        #expect(snapshot?.confidence == result?.confidence)
    }

    private func run(
        id: String,
        distanceKm: Double,
        pace: Int,
        cadence: Int,
        elevation: Int,
        aura: RunTimeAura,
        shape: RouteShape,
        environment: EnvironmentCondition,
        rare: Bool = false
    ) -> CompletedRunRecord {
        let startedAt = date(for: aura)
        return CompletedRunRecord(
            id: id,
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(Double(pace) * distanceKm),
            distanceMeters: distanceKm * 1_000,
            durationSeconds: Int(Double(pace) * distanceKm),
            averageHeartRate: 150,
            averagePaceSeconds: pace,
            cadence: cadence,
            elevationGainM: elevation,
            reward: RunRewardSummary(
                pet: GeneratedPet(
                    species: .seedle,
                    element: .leaf,
                    palette: "default",
                    rareVariant: rare ? .eclipseMark : nil,
                    explanation: [],
                    stats: PetStats(vitality: 8, agility: 8, dexterity: 8, focus: 8, defense: 8)
                ),
                coreLabel: "core",
                experience: 10,
                completedQuestCount: 1,
                flavorText: "test"
            ),
            route: route(for: shape),
            source: "test",
            environmentCondition: environment,
            rareEventCompleted: rare
        )
    }

    private func date(for aura: RunTimeAura) -> Date {
        let hour: Int
        switch aura {
        case .dawn: hour = 6
        case .day: hour = 13
        case .dusk: hour = 18
        case .night: hour = 22
        }

        return Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 31, hour: hour, minute: 0)) ?? .now
    }

    private func route(for shape: RouteShape) -> [RoutePoint] {
        switch shape {
        case .loop:
            return [
                point(37.0, 127.0),
                point(37.001, 127.001),
                point(37.002, 127.0),
                point(37.001, 126.999),
                point(37.0, 127.0),
            ]
        case .outAndBack:
            return [
                point(37.0, 127.0),
                point(37.001, 127.0005),
                point(37.002, 127.001),
                point(37.003, 127.0015),
                point(37.004, 127.002),
                point(37.005, 127.0025),
                point(37.006, 127.003),
                point(37.007, 127.0035),
                point(37.008, 127.004),
                point(37.009, 127.0045),
                point(37.010, 127.005),
            ]
        case .maze:
            return [
                point(37.0, 127.0),
                point(37.0005, 127.002),
                point(37.0015, 127.001),
                point(37.002, 127.003),
                point(37.001, 127.004),
            ]
        case .freeform:
            return [
                point(37.0, 127.0),
                point(37.001, 127.002),
                point(37.003, 127.003),
                point(37.004, 127.001),
            ]
        }
    }

    private func point(_ latitude: Double, _ longitude: Double) -> RoutePoint {
        RoutePoint(latitude: latitude, longitude: longitude, altitude: 0, timestamp: .now)
    }
}
