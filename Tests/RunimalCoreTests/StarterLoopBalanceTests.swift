import Foundation
import Testing
@testable import RunimalCore

struct StarterLoopBalanceTests {
    @Test
    func shortRunRewardIsHeavilyReducedForVeryLightSessions() {
        let summary = RunSummary(
            distanceKm: 0.25,
            averagePaceSeconds: 390,
            cadence: 158,
            elevationGainM: 0,
            variability: 0.18,
            aura: .day,
            shape: .freeform
        )

        let reward = RunimalGameEngine.evaluateReward(for: summary)

        #expect(reward.experience <= 8)
    }

    @Test
    func starterEggNeedsMeaningfulProgressBeforeHatching() {
        let pet = GeneratedPet(
            species: .seedle,
            element: .leaf,
            palette: "starter",
            rareVariant: nil,
            explanation: [],
            stats: PetStats(vitality: 5, agility: 5, dexterity: 5, focus: 5, defense: 5)
        )
        let reward = RunRewardSummary(
            pet: pet,
            coreLabel: "starter",
            experience: 6,
            completedQuestCount: 0,
            flavorText: "starter"
        )
        let run = CompletedRunRecord(
            id: "run",
            startedAt: Date(),
            endedAt: Date(),
            distanceMeters: 250,
            durationSeconds: 120,
            averageHeartRate: nil,
            averagePaceSeconds: 480,
            cadence: 158,
            elevationGainM: 0,
            reward: reward,
            route: [],
            source: "test"
        )
        let egg = EggInventoryEntry(
            id: "egg",
            shell: .moss,
            title: "???",
            createdAt: Date(),
            sourceRunID: "seed",
            storedExperience: 18,
            hatchThreshold: 44,
            incubationRunIDs: [],
            unlockedAchievementIDs: [],
            starterBoosted: true
        )

        let gained = RunimalEggEngine.incubationExperienceGain(for: run, egg: egg)
        let nextExperience = egg.storedExperience + gained

        #expect(nextExperience < egg.hatchThreshold)
    }

    @Test
    func starterGrowthSeedKeepsFreshlyHatchedCompanionAtLevelOne() {
        let egg = EggInventoryEntry(
            id: "starter",
            shell: .moss,
            title: "???",
            createdAt: Date(),
            sourceRunID: "seed",
            storedExperience: 44,
            hatchThreshold: 44,
            incubationRunIDs: [],
            unlockedAchievementIDs: [],
            starterBoosted: true
        )

        let seedXP = RunimalEggEngine.starterGrowthSeed(for: egg)

        #expect(RunimalBalanceConfig.companionLevel(forExperience: seedXP) == 1)
    }

    @Test
    func mutationVisualsStayDormantUntilGrowthStageSettles() {
        let state = MutationVisualState(bodyStage: 3, ecologyStage: 2, rhythmStage: 1)

        let infant = MutationVisualEvolutionEngine.visibleState(for: state, growthStageIndex: 1)
        let youth = MutationVisualEvolutionEngine.visibleState(for: state, growthStageIndex: 2)
        let teen = MutationVisualEvolutionEngine.visibleState(for: state, growthStageIndex: 3)

        #expect(infant == .none)
        #expect(youth == MutationVisualState(bodyStage: 1, ecologyStage: 1, rhythmStage: 1))
        #expect(teen == MutationVisualState(bodyStage: 2, ecologyStage: 2, rhythmStage: 1))
    }

    @Test
    func mutationIdentityStaysHiddenDuringInfantStage() {
        #expect(MutationVisualEvolutionEngine.allowsMutationIdentity(growthStageIndex: 1) == false)
        #expect(MutationVisualEvolutionEngine.allowsMutationIdentity(growthStageIndex: 2))
    }

    @Test
    func subTenKilometerSessionsCannotSkipMoreThanOneLevel() {
        let currentExperience = 12
        let currentLevel = RunimalBalanceConfig.companionLevel(forExperience: currentExperience)

        let capped = RunimalBalanceConfig.cappedExperienceGain(
            currentExperience: currentExperience,
            proposedGain: 400,
            currentLevel: currentLevel,
            runDistanceKm: 9.8
        )

        let levelAfter = RunimalBalanceConfig.companionLevel(forExperience: currentExperience + capped)

        #expect(levelAfter - currentLevel == 1)
    }
}
