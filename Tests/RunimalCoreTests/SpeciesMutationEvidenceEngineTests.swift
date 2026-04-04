import XCTest
@testable import RunimalCore

final class SpeciesMutationEvidenceEngineTests: XCTestCase {
    func testEvidenceIncludesAggregateAndRecentReasons() {
        let run = CompletedRunRecord(
            id: "run-1",
            startedAt: Date(timeIntervalSince1970: 1_700_000_000),
            endedAt: Date(timeIntervalSince1970: 1_700_003_000),
            distanceMeters: 3_800,
            durationSeconds: 1_200,
            averageHeartRate: 168,
            averagePaceSeconds: 315,
            cadence: 178,
            elevationGainM: 24,
            reward: .init(
                pet: GeneratedPet(
                    species: .sparkfang,
                    element: .flame,
                    palette: "test",
                    rareVariant: nil,
                    explanation: ["test"],
                    stats: PetStats(vitality: 4, agility: 6, dexterity: 7, focus: 5, defense: 3)
                ),
                coreLabel: "tempo",
                experience: 120,
                completedQuestCount: 1,
                flavorText: "test"
            ),
            route: [
                .init(latitude: 37.0, longitude: 127.0, altitude: 0, timestamp: Date(timeIntervalSince1970: 1_700_000_000)),
                .init(latitude: 37.001, longitude: 127.001, altitude: 0, timestamp: Date(timeIntervalSince1970: 1_700_001_000)),
                .init(latitude: 37.002, longitude: 127.002, altitude: 0, timestamp: Date(timeIntervalSince1970: 1_700_002_000)),
            ],
            source: "test",
            environmentCondition: .clear
        )

        let evidence = SpeciesMutationEvidenceEngine.evidence(
            for: [run],
            preferredSpecies: .sparkfang
        )

        let rhythm = evidence?.evidence(for: .rhythm)
        XCTAssertNotNil(rhythm)
        XCTAssertFalse(rhythm?.aggregateReason.isEmpty ?? true)
        XCTAssertFalse(rhythm?.recentReason?.isEmpty ?? true)
    }
}
