import Foundation
import Testing
@testable import RunimalCore

struct LaunchGateFTUETests {
    @Test
    func firstRunGuaranteesStarterEggOpportunity() {
        let opportunity = RunimalEggEngine.opportunity(
            for: sampleRun(id: "first", source: "watch-live"),
            unlockedAchievementIDs: [],
            collectionIsEmpty: true,
            eggInventoryIsEmpty: true,
            completedRunCount: 1
        )

        #expect(opportunity.eligible)
        #expect(opportunity.isFirstRecoveryRun)
    }

    @Test
    func meaningfulSecondRunGuaranteesStarterEggHatch() {
        let egg = starterEgg()
        let secondRun = sampleRun(
            id: "second",
            source: "watch-live",
            distanceMeters: 3_200,
            experience: 14
        )

        let gain = RunimalEggEngine.incubationExperienceGain(for: secondRun, egg: egg)

        #expect(egg.storedExperience + gain >= egg.hatchThreshold)
    }

    @Test
    func starterCompanionFirstMeaningfulFeedGuaranteesVisibleStageAdvance() {
        let record = CompanionGrowthRecord(
            companionID: "starter",
            totalExperience: RunimalEggEngine.starterGrowthSeed(for: starterEgg()),
            storedPotentialExperience: 0,
            feedCount: 0,
            assignedRunIDs: ["first-run", "second-run"],
            lastFedAt: nil
        )
        let run = sampleRun(
            id: "third",
            source: "watch-live",
            distanceMeters: 4_100,
            experience: 18
        )

        let shouldGuarantee = RunimalStarterLoopEngine.shouldGuaranteeFirstVisibleStageAdvance(
            record: record,
            currentStageLabel: RunimalBalanceConfig.evolutionStageLabels[1],
            run: run
        )
        let guaranteedTotal = RunimalStarterLoopEngine.guaranteedFirstVisibleStageTotalExperience(for: .seedle)
        let guaranteedGain = RunimalStarterLoopEngine.guaranteedFirstVisibleStageGain(
            currentExperience: record.totalExperience,
            species: .seedle
        )

        #expect(shouldGuarantee)
        #expect(record.totalExperience < guaranteedTotal)
        #expect(record.totalExperience + guaranteedGain >= guaranteedTotal)
    }

    @Test
    func importedWorkoutUsesSameStarterLoopClassificationAsLiveWorkout() {
        let liveRun = sampleRun(id: "live", source: "watch-live")
        let importedRun = sampleRun(id: "imported", source: "healthkit:import")

        #expect(RunimalEggEngine.shell(for: liveRun) == RunimalEggEngine.shell(for: importedRun))
        #expect(RunimalStarterLoopEngine.isMeaningfulRun(liveRun) == RunimalStarterLoopEngine.isMeaningfulRun(importedRun))
        #expect(RunimalSpeciesRuleEngine.summarize(run: liveRun) == RunimalSpeciesRuleEngine.summarize(run: importedRun))
    }

    @Test
    func rareVariantBannerCopyRemainsLaunchReadable() {
        #expect(RareVariantMeta.labels[.eclipseMark] == "밤의 흔적")
        #expect(RareVariantMeta.labels[.loopSigil]?.isEmpty == false)
    }

    private func starterEgg() -> EggInventoryEntry {
        EggInventoryEntry(
            id: "starter-egg",
            shell: .moss,
            title: "???",
            createdAt: Date(),
            sourceRunID: "first-run",
            storedExperience: 18,
            hatchThreshold: 44,
            incubationRunIDs: [],
            unlockedAchievementIDs: [],
            starterBoosted: true
        )
    }

    private func sampleRun(
        id: String,
        source: String,
        distanceMeters: Double = 3_200,
        experience: Int = 12
    ) -> CompletedRunRecord {
        let startedAt = Date(timeIntervalSince1970: 1_712_188_800)
        let reward = RunRewardSummary(
            pet: GeneratedPet(
                species: .seedle,
                element: .leaf,
                palette: PetSpecies.seedle.basePaletteName,
                rareVariant: nil,
                explanation: [],
                stats: PetStats(vitality: 8, agility: 8, dexterity: 8, focus: 8, defense: 8)
            ),
            coreLabel: "starter",
            experience: experience,
            completedQuestCount: 0,
            flavorText: "starter"
        )

        return CompletedRunRecord(
            id: id,
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(1_500),
            distanceMeters: distanceMeters,
            durationSeconds: 1_500,
            averageHeartRate: 148,
            averagePaceSeconds: 338,
            cadence: 170,
            elevationGainM: 16,
            reward: reward,
            route: [
                RoutePoint(latitude: 37.52, longitude: 127.04, altitude: 12, timestamp: startedAt),
                RoutePoint(latitude: 37.525, longitude: 127.045, altitude: 18, timestamp: startedAt.addingTimeInterval(600))
            ],
            source: source,
            environmentCondition: .clear,
            rareEventCompleted: false
        )
    }
}
