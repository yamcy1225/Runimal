import Foundation
import Testing
@testable import RunimalCore

struct WorldContentEngineTests {
    @Test
    func seedPackLoadsFromJSONResource() {
        let pack = WorldContentPackLoader.loadSeedPack()

        #expect(pack?.contentPack.packID == "master-seed")
        #expect(WorldContentPackLoader.availablePackResourceNames().contains("runimal-world-content.seed"))
        #expect(pack?.speciesBible.count == 5)
        #expect(pack?.regions.count == 8)
        #expect(pack?.seasons.count == 8)
        #expect(pack?.narrativeEpisodes.count == 15)
        #expect(pack?.contentPack.featuredSpeciesIDs.contains("shadebit") == false)
    }

    @Test
    func allResourcePacksLoadIncludingExpansion() {
        let packs = WorldContentPackLoader.loadAllPacks()
        let ids = packs.map(\.contentPack.packID)
        let aurora = packs.first(where: { $0.contentPack.packID == "aurora-frontier" })
        let obsidian = packs.first(where: { $0.contentPack.packID == "obsidian-circuit" })

        #expect(ids.contains("master-seed"))
        #expect(ids.contains("aurora-frontier"))
        #expect(ids.contains("obsidian-circuit"))
        #expect(packs.count >= 3)
        #expect(aurora?.regions.count == 2)
        #expect(aurora?.rareVariants.contains(where: { $0.variantID == "polar-echo" }) == true)
        #expect(obsidian?.regions.count == 2)
        #expect(obsidian?.seasons.count == 2)
    }

    @Test
    func mergedPackIncludesExpansionContent() {
        let pack = DefaultWorldContent.pack

        #expect(pack.regions.contains { $0.regionID == "glacier-veil" })
        #expect(pack.regions.contains { $0.regionID == "tide-loop" })
        #expect(pack.regions.contains { $0.regionID == "ember-belt" })
        #expect(pack.regions.contains { $0.regionID == "root-garden" })
        #expect(pack.regions.contains { $0.regionID == "signal-foundry" })
        #expect(pack.regions.contains { $0.regionID == "glass-canyon" })
        #expect(pack.seasons.contains { $0.seasonID == "aurora-frontier" })
        #expect(pack.seasons.contains { $0.seasonID == "relay-blaze" })
        #expect(pack.seasons.contains { $0.seasonID == "river-mirror" })
        #expect(pack.seasons.contains { $0.seasonID == "obsidian-circuit" })
        #expect(pack.narrativeEpisodes.contains { $0.episodeID == "episode-frostbloom" })
        #expect(pack.narrativeEpisodes.contains { $0.episodeID == "episode-shadebit-threshold" })
        #expect(pack.narrativeEpisodes.contains { $0.episodeID == "episode-foundry-surge" })
    }

    @Test
    func mergedSpeciesBibleAccumulatesExpansionHooksAndHabitats() {
        let pack = DefaultWorldContent.pack
        let sparkfang = pack.speciesBible.first(where: { $0.speciesID == "sparkfang" })
        let windrunner = pack.speciesBible.first(where: { $0.speciesID == "windrunner" })

        #expect(sparkfang?.displayName == "신더래시")
        #expect(windrunner?.displayName == "에이라리스")
        #expect(sparkfang?.habitatTags.contains("heat") == true)
        #expect(sparkfang?.narrativeHooks.contains(where: { $0.contains("제철소") || $0.contains("잔열") }) == true)
        #expect(windrunner?.visualKeywords.contains("glass-ribbon") == true)
        #expect(windrunner?.narrativeHooks.count ?? 0 > 4)
    }

    @Test
    func companionProfileIncludesFantasyAndMutation() {
        let pet = GeneratedPet(
            species: .windrunner,
            element: .light,
            palette: "default",
            rareVariant: nil,
            explanation: [],
            stats: PetStats(vitality: 10, agility: 12, dexterity: 11, focus: 9, defense: 8)
        )

        let profile = RunimalWorldContentEngine.profile(for: pet)

        #expect(profile?.fantasyLine.contains("바람길") == true)
        #expect(profile?.habitatLine.contains("도심") == true)
        #expect(profile?.mutationLine?.contains("Gale Swift") == true)
    }

    @Test
    func shadebitUsesTwilightFallbackProfile() {
        let pet = GeneratedPet(
            species: .shadebit,
            element: .lunar,
            palette: "default",
            rareVariant: .eclipseMark,
            explanation: [],
            stats: PetStats(vitality: 9, agility: 11, dexterity: 10, focus: 12, defense: 7)
        )

        let profile = RunimalWorldContentEngine.profile(for: pet)

        #expect(profile?.fantasyLine.contains("황혼 계열") == true)
        #expect(profile?.mutationLine?.contains("Eclipse Twilight") == true)
        #expect(profile?.variantLine?.contains("이클립스 마크") == true)
    }

    @Test
    func runProfileMatchesRegionForSpecies() {
        let reward = RunRewardSummary(
            pet: GeneratedPet(
                species: .stoneback,
                element: .earth,
                palette: "default",
                rareVariant: nil,
                explanation: [],
                stats: PetStats(vitality: 12, agility: 7, dexterity: 8, focus: 10, defense: 13)
            ),
            coreLabel: "Stone Core",
            experience: 24,
            completedQuestCount: 1,
            flavorText: "ridge pulse"
        )

        let run = CompletedRunRecord(
            id: "run-1",
            startedAt: .now,
            endedAt: .now.addingTimeInterval(1800),
            distanceMeters: 5200,
            durationSeconds: 1800,
            averageHeartRate: 152,
            averagePaceSeconds: 346,
            cadence: 166,
            elevationGainM: 180,
            reward: reward,
            route: [],
            source: "watch-demo",
            environmentCondition: .wind,
            rareEventCompleted: false
        )

        let profile = RunimalWorldContentEngine.profile(for: run)

        #expect(profile?.regionTitle == "고지대 구역")
        #expect(profile?.summaryLine.contains("암석 지대") == true)
    }

    @Test
    func runProfileCanResolveExpansionRegion() {
        let calendar = Calendar.current
        let startedAt = calendar.date(from: DateComponents(year: 2026, month: 1, day: 10, hour: 6, minute: 30)) ?? .now

        let reward = RunRewardSummary(
            pet: GeneratedPet(
                species: .mosshop,
                element: .leaf,
                palette: "default",
                rareVariant: nil,
                explanation: [],
                stats: PetStats(vitality: 9, agility: 8, dexterity: 8, focus: 12, defense: 10)
            ),
            coreLabel: "Moss Core",
            experience: 18,
            completedQuestCount: 1,
            flavorText: "frost bloom"
        )

        let run = CompletedRunRecord(
            id: "run-expansion-1",
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(2400),
            distanceMeters: 4100,
            durationSeconds: 2400,
            averageHeartRate: 148,
            averagePaceSeconds: 585,
            cadence: 150,
            elevationGainM: 95,
            reward: reward,
            route: [],
            source: "watch-demo",
            environmentCondition: .cold,
            rareEventCompleted: false
        )

        let profile = RunimalWorldContentEngine.profile(for: run)

        #expect(profile?.regionTitle == "서리 장막 구역")
        #expect(profile?.seasonTitle == "Aurora Frontier")
    }
}
