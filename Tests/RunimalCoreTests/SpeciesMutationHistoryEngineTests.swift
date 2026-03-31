import Foundation
import Testing
@testable import RunimalCore

struct SpeciesMutationHistoryEngineTests {
    @Test
    func historyTracksUnlockedBranchesAcrossRunSequence() {
        let runs = [
            run(id: "w1", distanceKm: 10.2, pace: 355, cadence: 171, elevation: 28, aura: .day, shape: .outAndBack, environment: .clear),
            run(id: "w2", distanceKm: 9.4, pace: 362, cadence: 170, elevation: 34, aura: .dawn, shape: .outAndBack, environment: .wind),
            run(id: "w3", distanceKm: 8.7, pace: 368, cadence: 172, elevation: 30, aura: .day, shape: .loop, environment: .overcast),
        ]

        let history = SpeciesMutationHistoryEngine.history(for: runs, preferredSpecies: .windrunner)

        #expect(history?.speciesID == "windrunner")
        #expect(history?.currentForm.displayTitle == "Zephyr Frontier")
        #expect(history?.runCount == 3)
        #expect(history?.axes.count == 3)
        #expect(history?.axes.first(where: { $0.axis == .body })?.unlockedTitles.contains("Aero Swift") == true)
        #expect(history?.axes.first(where: { $0.axis == .body })?.currentProgress ?? 0 > 0)
        #expect(history?.axes.first(where: { $0.axis == .body })?.branches.count == 3)
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
