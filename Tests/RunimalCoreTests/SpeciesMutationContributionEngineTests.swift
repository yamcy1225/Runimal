import Foundation
import Testing
@testable import RunimalCore

struct SpeciesMutationContributionEngineTests {
    @Test
    func singleRunContributionResolvesThreeAxisSignals() {
        let run = CompletedRunRecord(
            id: "c1",
            startedAt: date(hour: 6),
            endedAt: date(hour: 6).addingTimeInterval(3_600),
            distanceMeters: 10_000,
            durationSeconds: 3_600,
            averageHeartRate: 148,
            averagePaceSeconds: 360,
            cadence: 171,
            elevationGainM: 24,
            reward: reward(species: .windrunner),
            route: [
                RoutePoint(latitude: 37.0, longitude: 127.0, altitude: 0, timestamp: .now),
                RoutePoint(latitude: 37.001, longitude: 127.0005, altitude: 0, timestamp: .now.addingTimeInterval(60))
            ],
            source: "test",
            environmentCondition: .clear
        )

        let contribution = SpeciesMutationContributionEngine.runContribution(
            for: run,
            preferredSpecies: .windrunner
        )

        #expect(contribution?.speciesID == "windrunner")
        #expect(contribution?.axes.count == 3)
        #expect(contribution?.axes.first(where: { $0.axis == .body })?.branchID == "aero-swift")
        #expect(contribution?.axes.first(where: { $0.axis == .ecology })?.branchID == "river-open")
        #expect(contribution?.axes.first(where: { $0.axis == .rhythm })?.branchID == "draft-route")
    }

    private func reward(species: PetSpecies) -> RunRewardSummary {
        RunRewardSummary(
            pet: GeneratedPet(
                species: species,
                element: .light,
                palette: "default",
                rareVariant: nil,
                explanation: [],
                stats: PetStats(vitality: 8, agility: 8, dexterity: 8, focus: 8, defense: 8)
            ),
            coreLabel: "core",
            experience: 10,
            completedQuestCount: 1,
            flavorText: "test"
        )
    }

    private func date(hour: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 1, hour: hour, minute: 0)) ?? .now
    }
}
