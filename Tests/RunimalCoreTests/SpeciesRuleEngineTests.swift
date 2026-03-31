import XCTest
@testable import RunimalCore

final class SpeciesRuleEngineTests: XCTestCase {
    func testLongStableRunFavorsWindrunner() {
        let summary = RunSummary(
            distanceKm: 12.4,
            averagePaceSeconds: 352,
            cadence: 172,
            elevationGainM: 28,
            variability: 0.08,
            aura: .day,
            shape: .outAndBack,
            environmentCondition: .wind
        )

        XCTAssertEqual(RunimalSpeciesRuleEngine.dominantSpecies(for: summary), .windrunner)
    }

    func testClimbingRunFavorsStoneback() {
        let summary = RunSummary(
            distanceKm: 8.2,
            averagePaceSeconds: 402,
            cadence: 162,
            elevationGainM: 186,
            variability: 0.11,
            aura: .dawn,
            shape: .outAndBack,
            environmentCondition: .cold
        )

        XCTAssertEqual(RunimalSpeciesRuleEngine.dominantSpecies(for: summary), .stoneback)
    }

    func testFastShortRunFavorsSparkfang() {
        let summary = RunSummary(
            distanceKm: 3.6,
            averagePaceSeconds: 302,
            cadence: 178,
            elevationGainM: 16,
            variability: 0.15,
            aura: .day,
            shape: .freeform,
            environmentCondition: .heat,
            rareEventCompleted: true
        )

        XCTAssertEqual(RunimalSpeciesRuleEngine.dominantSpecies(for: summary), .sparkfang)
    }

    func testBalancedRainRunFavorsMosshop() {
        let summary = RunSummary(
            distanceKm: 6.1,
            averagePaceSeconds: 418,
            cadence: 168,
            elevationGainM: 52,
            variability: 0.12,
            aura: .dusk,
            shape: .loop,
            environmentCondition: .rain
        )

        XCTAssertEqual(RunimalSpeciesRuleEngine.dominantSpecies(for: summary), .mosshop)
    }

    func testNightMazeRunFavorsShadebit() {
        let summary = RunSummary(
            distanceKm: 5.0,
            averagePaceSeconds: 386,
            cadence: 171,
            elevationGainM: 34,
            variability: 0.21,
            aura: .night,
            shape: .maze,
            environmentCondition: .overcast
        )

        XCTAssertEqual(RunimalSpeciesRuleEngine.dominantSpecies(for: summary), .shadebit)
    }

    func testShortRecoveryRunFavorsSeedle() {
        let summary = RunSummary(
            distanceKm: 2.3,
            averagePaceSeconds: 535,
            cadence: 154,
            elevationGainM: 12,
            variability: 0.13,
            aura: .dawn,
            shape: .freeform,
            environmentCondition: .unknown
        )

        XCTAssertEqual(RunimalSpeciesRuleEngine.dominantSpecies(for: summary), .seedle)
    }

    func testGaleShellBiasStillRespectsRunPattern() {
        let run = CompletedRunRecord(
            id: "wind-run",
            startedAt: Date(timeIntervalSince1970: 1_710_000_000),
            endedAt: Date(timeIntervalSince1970: 1_710_000_000 + 4_400),
            distanceMeters: 12_100,
            durationSeconds: 4_400,
            averageHeartRate: 151,
            averagePaceSeconds: 364,
            cadence: 171,
            elevationGainM: 38,
            reward: reward(species: .seedle),
            route: route(looped: false),
            source: "test",
            environmentCondition: .wind
        )

        let scores = RunimalSpeciesRuleEngine.shellBiasedScores(for: .gale, runs: [run])
        XCTAssertGreaterThan(scores[.windrunner, default: 0], scores[.sparkfang, default: 0])
        XCTAssertGreaterThan(scores[.windrunner, default: 0], scores[.mosshop, default: 0])
    }

    private func reward(species: PetSpecies) -> RunRewardSummary {
        RunRewardSummary(
            pet: GeneratedPet(
                species: species,
                element: .light,
                palette: "seed",
                rareVariant: nil,
                explanation: [],
                stats: PetStats(vitality: 5, agility: 5, dexterity: 5, focus: 5, defense: 5)
            ),
            coreLabel: "CORE",
            experience: 80,
            completedQuestCount: 1,
            flavorText: "test"
        )
    }

    private func route(looped: Bool) -> [RoutePoint] {
        let start = Date(timeIntervalSince1970: 1_710_000_000)
        let points = [
            RoutePoint(latitude: 37.0, longitude: 127.0, altitude: 12, timestamp: start),
            RoutePoint(latitude: 37.001, longitude: 127.002, altitude: 18, timestamp: start.addingTimeInterval(300)),
            RoutePoint(latitude: 37.002, longitude: 127.004, altitude: 24, timestamp: start.addingTimeInterval(600)),
            RoutePoint(latitude: 37.003, longitude: 127.006, altitude: 27, timestamp: start.addingTimeInterval(900)),
            RoutePoint(latitude: 37.004, longitude: 127.008, altitude: 30, timestamp: start.addingTimeInterval(1_200)),
        ]

        if looped {
            return points + [RoutePoint(latitude: 37.0, longitude: 127.0, altitude: 12, timestamp: start.addingTimeInterval(1_500))]
        }

        return points + [RoutePoint(latitude: 37.005, longitude: 127.010, altitude: 34, timestamp: start.addingTimeInterval(1_500))]
    }
}
