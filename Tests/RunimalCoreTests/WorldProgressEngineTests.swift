import Foundation
import Testing
@testable import RunimalCore

struct WorldProgressEngineTests {
    @Test
    func firstUrbanRunUnlocksRegionSeasonAndEpisode() {
        let run = makeRun(
            id: "urban-1",
            species: .seedle,
            startedAt: makeDate(hour: 7),
            distanceMeters: 2_400,
            cadence: 162,
            elevationGainM: 18
        )

        let snapshot = RunimalWorldProgressEngine.rebuild(from: [run])

        #expect(snapshot.regions.contains(where: { $0.regionID == "urban-core" }))
        #expect(snapshot.seasons.contains(where: { $0.seasonID == "quiet-signal" }))
        #expect(snapshot.episodes.contains(where: { $0.episodeID == "episode-awakening-signal" && $0.unlockedAt != nil }))
        #expect(snapshot.lastImpact?.regionID == "urban-core")
    }

    @Test
    func cumulativeNatureRunsUnlockMossbreathEpisode() {
        let runs = (0..<5).map { index in
            makeRun(
                id: "nature-\(index)",
                species: .mosshop,
                startedAt: makeDate(dayOffset: index, hour: 9),
                distanceMeters: 2_500,
                cadence: 158,
                elevationGainM: 22
            )
        }

        let snapshot = RunimalWorldProgressEngine.rebuild(from: runs)
        let episode = snapshot.episodes.first(where: { $0.episodeID == "episode-mossbreath" })

        #expect(snapshot.regions.contains(where: { $0.regionID == "nature-trail" }))
        #expect(snapshot.seasons.contains(where: { $0.seasonID == "verdant-circuit" }))
        #expect(episode?.unlockedAt != nil)
        #expect(episode?.totalDistanceKm == 12.5)
    }

    @Test
    func cumulativeNightRunsUnlockMoonmarkEpisode() {
        let runs = (0..<5).map { index in
            makeRun(
                id: "night-\(index)",
                species: .sparkfang,
                startedAt: makeDate(dayOffset: index, hour: 22),
                distanceMeters: 2_000,
                cadence: 174,
                elevationGainM: 16
            )
        }

        let snapshot = RunimalWorldProgressEngine.rebuild(from: runs)
        let episode = snapshot.episodes.first(where: { $0.episodeID == "episode-moonmark" })

        #expect(snapshot.regions.contains(where: { $0.regionID == "moonlight-alley" }))
        #expect(snapshot.seasons.contains(where: { $0.seasonID == "hollow-dusk" }))
        #expect(episode?.nightRunCount == 5)
        #expect(episode?.unlockedAt != nil)
    }

    private func makeRun(
        id: String,
        species: PetSpecies,
        startedAt: Date,
        distanceMeters: Double,
        cadence: Int,
        elevationGainM: Int
    ) -> CompletedRunRecord {
        let pet = GeneratedPet(
            species: species,
            element: .leaf,
            palette: "test",
            rareVariant: nil,
            explanation: [],
            stats: PetStats(vitality: 10, agility: 10, dexterity: 10, focus: 10, defense: 10)
        )
        let reward = RunRewardSummary(
            pet: pet,
            coreLabel: "\(species.rawValue)-core",
            experience: 100,
            completedQuestCount: 1,
            flavorText: ""
        )
        let endedAt = startedAt.addingTimeInterval(1_800)

        return CompletedRunRecord(
            id: id,
            startedAt: startedAt,
            endedAt: endedAt,
            distanceMeters: distanceMeters,
            durationSeconds: 1_800,
            averageHeartRate: 148,
            averagePaceSeconds: 360,
            cadence: cadence,
            elevationGainM: elevationGainM,
            reward: reward,
            route: [],
            source: "test"
        )
    }

    private func makeDate(dayOffset: Int = 0, hour: Int) -> Date {
        Calendar(identifier: .gregorian).date(
            from: DateComponents(
                year: 2026,
                month: 4,
                day: 1 + dayOffset,
                hour: hour,
                minute: 0
            )
        ) ?? Date(timeIntervalSince1970: 0)
    }
}
