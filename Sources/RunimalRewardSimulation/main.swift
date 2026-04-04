import Foundation
import RunimalCore

struct RewardScenario {
    let id: String
    let summary: RunSummary
}

struct GrowthScenario {
    let id: String
    let summary: RunSummary
    let routePointCount: Int
    let averageHeartRate: Double?
    let source: String
    let sourceLabel: String?
    let environmentCondition: EnvironmentCondition
    let rareEventCompleted: Bool
    let liveCompanionName: String?
    let mutationAxisCount: Int
    let worldImpact: WorldRunImpact?
    let activeEffects: [WeeklyRewardEffect]
    let season: WeeklySeason
    let forgeInventory: ForgeInventory
    let buildState: CompanionBuildState?
    let companionID: String
    let companionHeadline: String
    let companionBond: Int
    let currentGrowthRecord: CompanionGrowthRecord?
    let latestAssignedRun: CompletedRunRecord?
}

struct GrowthSimulationResult {
    let scenarioID: String
    let baseExperience: Int
    let resonanceBonus: Int
    let forgeBonus: Int
    let buildBonus: Int
    let interactionBonus: Int
    let dataBonus: Int
    let potentialGenerated: Int
    let potentialSpent: Int
    let stageLockBonus: Int
    let totalGainedExperience: Int
    let levelBefore: Int
    let levelAfter: Int
    let stageBefore: String
    let stageAfter: String
    let interactionLabels: [String]
    let outputLabels: [String]
}

struct GrowthStepResult {
    let result: GrowthSimulationResult
    let updatedRecord: CompanionGrowthRecord
    let run: CompletedRunRecord
}

struct AdulthoodProfile {
    let id: String
    let title: String
    let summary: RunSummary
    let routePointCount: Int
    let averageHeartRate: Double?
    let source: String
    let sourceLabel: String?
    let environmentCondition: EnvironmentCondition
    let rareEventCompleted: Bool
    let mutationAxisCount: Int
    let companionBond: Int
    let seasonAffinity: Bool
    let activeEffects: [WeeklyRewardEffect]
    let livePotentialEnabled: Bool
}

struct AdulthoodSimulationResult {
    let profileID: String
    let profileTitle: String
    let species: PetSpecies
    let runsToAdult: Int
    let totalExperienceAtAdult: Int
    let adultLevel: Int
    let firstGain: Int
    let averageGain: Int
    let finalGain: Int
}

struct MaxLevelSimulationResult {
    let profileID: String
    let profileTitle: String
    let species: PetSpecies
    let runsToAdult: Int
    let runsToLevelCap: Int
    let postAdultRuns: Int
    let totalExperienceAtCap: Int
    let firstGain: Int
    let averageGain: Int
    let postAdultAverageGain: Int
    let finalGain: Int
}

let scenarios: [RewardScenario] = [
    RewardScenario(
        id: "steady_5k",
        summary: RunSummary(
            distanceKm: 5.2,
            averagePaceSeconds: 332,
            cadence: 169,
            elevationGainM: 24,
            variability: 0.08,
            aura: .day,
            shape: .freeform,
            environmentCondition: .clear,
            rareEventCompleted: false
        )
    ),
    RewardScenario(
        id: "tempo_rare",
        summary: RunSummary(
            distanceKm: 4.6,
            averagePaceSeconds: 298,
            cadence: 176,
            elevationGainM: 18,
            variability: 0.11,
            aura: .night,
            shape: .loop,
            environmentCondition: .wind,
            rareEventCompleted: true
        )
    ),
    RewardScenario(
        id: "climb_sync",
        summary: RunSummary(
            distanceKm: 6.4,
            averagePaceSeconds: 355,
            cadence: 166,
            elevationGainM: 102,
            variability: 0.1,
            aura: .dawn,
            shape: .maze,
            environmentCondition: .rain,
            rareEventCompleted: false
        )
    ),
]

let activeEffects: [WeeklyRewardEffect] = [
    WeeklyRewardEffect(id: "weekly-badge", title: "Field Badge", detail: "이번 주 배지 효과"),
    WeeklyRewardEffect(id: "weekly-evo-boost", title: "Evolution Boost", detail: "진화 가속 효과"),
]

let growthScenarios: [GrowthScenario] = {
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime]

    func date(_ value: String) -> Date {
        isoFormatter.date(from: value) ?? Date(timeIntervalSince1970: 0)
    }

    let plainSeason = makeSeason(
        title: "Archive Relay",
        focusSpecies: .windrunner,
        focusVariant: nil
    )
    let sparkSeason = makeSeason(
        title: "Ember Circuit",
        focusSpecies: .sparkfang,
        focusVariant: .tempoSurge
    )
    let shadeSeason = makeSeason(
        title: "Lunar Relay",
        focusSpecies: .shadebit,
        focusVariant: .eclipseMark
    )

    let plainSummary = RunSummary(
        distanceKm: 4.1,
        averagePaceSeconds: 352,
        cadence: 164,
        elevationGainM: 6,
        variability: 0.09,
        aura: .day,
        shape: .outAndBack,
        environmentCondition: .unknown,
        rareEventCompleted: false
    )
    let richSummary = RunSummary(
        distanceKm: 6.8,
        averagePaceSeconds: 324,
        cadence: 170,
        elevationGainM: 28,
        variability: 0.1,
        aura: .day,
        shape: .loop,
        environmentCondition: .rain,
        rareEventCompleted: false
    )
    let liveSummary = RunSummary(
        distanceKm: 8.4,
        averagePaceSeconds: 304,
        cadence: 176,
        elevationGainM: 42,
        variability: 0.07,
        aura: .night,
        shape: .loop,
        environmentCondition: .wind,
        rareEventCompleted: true
    )
    let unlockSummary = RunSummary(
        distanceKm: 9.2,
        averagePaceSeconds: 296,
        cadence: 178,
        elevationGainM: 58,
        variability: 0.06,
        aura: .night,
        shape: .maze,
        environmentCondition: .cold,
        rareEventCompleted: true
    )

    let richReward = RunimalGameEngine.evaluateReward(for: richSummary)
    let liveReward = RunimalGameEngine.evaluateReward(for: liveSummary)
    let unlockReward = RunimalGameEngine.evaluateReward(for: unlockSummary)

    let richCompanion = makeCompanion(
        id: "companion-rich",
        pet: GeneratedPet(
            species: richReward.pet.species,
            element: richReward.pet.element,
            palette: richReward.pet.palette,
            rareVariant: richReward.pet.rareVariant,
            explanation: richReward.pet.explanation,
            stats: richReward.pet.stats
        ),
        level: 10,
        bond: 28,
        headline: "비 오는 길이 익숙한 동행"
    )
    let liveCompanion = makeCompanion(
        id: "companion-live",
        pet: GeneratedPet(
            species: liveReward.pet.species,
            element: liveReward.pet.element,
            palette: liveReward.pet.palette,
            rareVariant: liveReward.pet.rareVariant,
            explanation: liveReward.pet.explanation,
            stats: liveReward.pet.stats
        ),
        level: 18,
        bond: 46,
        headline: "밤 리듬에 강한 동행"
    )
    let unlockCompanion = makeCompanion(
        id: "companion-unlock",
        pet: GeneratedPet(
            species: .shadebit,
            element: unlockReward.pet.element,
            palette: unlockReward.pet.palette,
            rareVariant: .eclipseMark,
            explanation: unlockReward.pet.explanation,
            stats: unlockReward.pet.stats
        ),
        level: 27,
        bond: 68,
        headline: "구역 신호를 읽는 동행"
    )

    let livePotentialSeedRecord = makeCompletedRun(
        id: "record-live-seed",
        summary: liveSummary,
        averageHeartRate: 156,
        routePointCount: 10,
        source: "watch",
        sourceLabel: "Apple Watch",
        reward: liveReward,
        environmentCondition: .wind,
        rareEventCompleted: true,
        liveCompanionID: liveCompanion.id,
        liveCompanionName: liveCompanion.pet.species.displayName,
        mutationAxisCount: 2,
        worldImpact: WorldRunImpact(
            regionID: "ember-circuit",
            regionTitle: "엠버 서킷",
            seasonID: "summer-2026",
            seasonTitle: "여름 회로",
            episodeID: "ember-02",
            episodeTitle: "심야 고리",
            unlockedRegion: false,
            unlockedSeason: false,
            unlockedEpisode: false,
            distanceKmDelta: liveSummary.distanceKm,
            elevationGainDelta: liveSummary.elevationGainM,
            nightRunDelta: 1,
            cadencePeakDelta: liveSummary.cadence
        )
    )

    return [
        GrowthScenario(
            id: "plain_import_first_feed",
            summary: plainSummary,
            routePointCount: 0,
            averageHeartRate: nil,
            source: "healthkit:import",
            sourceLabel: "가져온 기록",
            environmentCondition: .unknown,
            rareEventCompleted: false,
            liveCompanionName: nil,
            mutationAxisCount: 0,
            worldImpact: nil,
            activeEffects: [],
            season: plainSeason,
            forgeInventory: ForgeInventory(overdriveCharges: 0, seasonSigils: 0),
            buildState: nil,
            companionID: "companion-plain",
            companionHeadline: "처음 기록을 기다리는 동행",
            companionBond: 12,
            currentGrowthRecord: nil,
            latestAssignedRun: nil
        ),
        GrowthScenario(
            id: "rich_import_midgame",
            summary: richSummary,
            routePointCount: 8,
            averageHeartRate: 149,
            source: "fit:import",
            sourceLabel: "FIT 가져오기",
            environmentCondition: .rain,
            rareEventCompleted: false,
            liveCompanionName: nil,
            mutationAxisCount: 2,
            worldImpact: WorldRunImpact(
                regionID: "verdant-loop",
                regionTitle: "버던트 루프",
                seasonID: "spring-2026",
                seasonTitle: "봄 순환",
                episodeID: "verdant-01",
                episodeTitle: "첫 이끼 길",
                unlockedRegion: false,
                unlockedSeason: false,
                unlockedEpisode: false,
                distanceKmDelta: richSummary.distanceKm,
                elevationGainDelta: richSummary.elevationGainM,
                nightRunDelta: 0,
                cadencePeakDelta: richSummary.cadence
            ),
            activeEffects: activeEffects,
            season: makeSeason(
                title: "Verdant Loop",
                focusSpecies: richCompanion.pet.species,
                focusVariant: richCompanion.pet.rareVariant
            ),
            forgeInventory: ForgeInventory(overdriveCharges: 0, seasonSigils: 1),
            buildState: CompanionBuildState(
                companionID: richCompanion.id,
                selectedRole: .oracle,
                unlockedNodeIDs: ["echo-lens"]
            ),
            companionID: richCompanion.id,
            companionHeadline: richCompanion.headline,
            companionBond: richCompanion.bond,
            currentGrowthRecord: CompanionGrowthRecord(
                companionID: richCompanion.id,
                totalExperience: RunimalBalanceConfig.companionExperienceTotal(forLevel: 10),
                storedPotentialExperience: 0,
                feedCount: 5,
                assignedRunIDs: ["old-rich-1"],
                lastFedAt: date("2026-04-01T07:30:00Z")
            ),
            latestAssignedRun: makeCompletedRun(
                id: "old-rich-1",
                summary: richSummary,
                averageHeartRate: 146,
                routePointCount: 6,
                source: "simulation",
                sourceLabel: "이전 먹이",
                reward: richReward,
                environmentCondition: .rain,
                rareEventCompleted: false,
                liveCompanionID: nil,
                liveCompanionName: nil,
                mutationAxisCount: 1,
                worldImpact: WorldRunImpact(
                    regionID: "verdant-loop",
                    regionTitle: "버던트 루프",
                    seasonID: "spring-2026",
                    seasonTitle: "봄 순환",
                    episodeID: nil,
                    episodeTitle: nil,
                    unlockedRegion: false,
                    unlockedSeason: false,
                    unlockedEpisode: false,
                    distanceKmDelta: 4.5,
                    elevationGainDelta: 12,
                    nightRunDelta: 0,
                    cadencePeakDelta: 168
                )
            )
        ),
        GrowthScenario(
            id: "live_sync_same_companion",
            summary: liveSummary,
            routePointCount: 10,
            averageHeartRate: 156,
            source: "watch",
            sourceLabel: "Apple Watch",
            environmentCondition: .wind,
            rareEventCompleted: true,
            liveCompanionName: liveCompanion.pet.species.displayName,
            mutationAxisCount: 2,
            worldImpact: livePotentialSeedRecord.worldImpact,
            activeEffects: activeEffects,
            season: sparkSeason,
            forgeInventory: ForgeInventory(overdriveCharges: 1, seasonSigils: 1),
            buildState: CompanionBuildState(
                companionID: liveCompanion.id,
                selectedRole: .relay,
                unlockedNodeIDs: ["surge-link", "pace-weave"]
            ),
            companionID: liveCompanion.id,
            companionHeadline: liveCompanion.headline,
            companionBond: liveCompanion.bond,
            currentGrowthRecord: CompanionGrowthRecord(
                companionID: liveCompanion.id,
                totalExperience: RunimalBalanceConfig.companionExperienceTotal(forLevel: 18),
                storedPotentialExperience: RunimalRunCoreGrowthBalanceEngine.livePotential(for: livePotentialSeedRecord).storedPotentialExperience,
                feedCount: 9,
                assignedRunIDs: ["record-live-seed"],
                lastFedAt: date("2026-04-01T19:50:00Z")
            ),
            latestAssignedRun: livePotentialSeedRecord
        ),
        GrowthScenario(
            id: "world_unlock_peak",
            summary: unlockSummary,
            routePointCount: 12,
            averageHeartRate: 162,
            source: "watch",
            sourceLabel: "Apple Watch",
            environmentCondition: .cold,
            rareEventCompleted: true,
            liveCompanionName: unlockCompanion.pet.species.displayName,
            mutationAxisCount: 3,
            worldImpact: WorldRunImpact(
                regionID: "lunar-depth",
                regionTitle: "루나 딥스",
                seasonID: "winter-2026",
                seasonTitle: "겨울 조류",
                episodeID: "lunar-03",
                episodeTitle: "깊은 파장",
                unlockedRegion: true,
                unlockedSeason: true,
                unlockedEpisode: true,
                distanceKmDelta: unlockSummary.distanceKm,
                elevationGainDelta: unlockSummary.elevationGainM,
                nightRunDelta: 1,
                cadencePeakDelta: unlockSummary.cadence
            ),
            activeEffects: activeEffects,
            season: shadeSeason,
            forgeInventory: ForgeInventory(overdriveCharges: 1, seasonSigils: 1),
            buildState: CompanionBuildState(
                companionID: unlockCompanion.id,
                selectedRole: .oracle,
                unlockedNodeIDs: ["oracle-window", "echo-lens", "lunar-index"]
            ),
            companionID: unlockCompanion.id,
            companionHeadline: unlockCompanion.headline,
            companionBond: unlockCompanion.bond,
            currentGrowthRecord: CompanionGrowthRecord(
                companionID: unlockCompanion.id,
                totalExperience: RunimalBalanceConfig.companionExperienceTotal(forLevel: 27),
                storedPotentialExperience: 18,
                feedCount: 14,
                assignedRunIDs: ["record-live-seed", "old-unlock-1"],
                lastFedAt: date("2026-04-01T18:00:00Z")
            ),
            latestAssignedRun: makeCompletedRun(
                id: "old-unlock-1",
                summary: liveSummary,
                averageHeartRate: 154,
                routePointCount: 8,
                source: "watch",
                sourceLabel: "Apple Watch",
                reward: unlockReward,
                environmentCondition: .cold,
                rareEventCompleted: true,
                liveCompanionID: unlockCompanion.id,
                liveCompanionName: unlockCompanion.pet.species.displayName,
                mutationAxisCount: 2,
                worldImpact: WorldRunImpact(
                    regionID: "lunar-depth",
                    regionTitle: "루나 딥스",
                    seasonID: "winter-2026",
                    seasonTitle: "겨울 조류",
                    episodeID: "lunar-02",
                    episodeTitle: "빙결 고리",
                    unlockedRegion: false,
                    unlockedSeason: false,
                    unlockedEpisode: false,
                    distanceKmDelta: 7.4,
                    elevationGainDelta: 34,
                    nightRunDelta: 1,
                    cadencePeakDelta: 174
                )
            )
        ),
    ]
}()

let adulthoodProfiles: [AdulthoodProfile] = [
    AdulthoodProfile(
        id: "light_import",
        title: "가벼운 가져오기",
        summary: RunSummary(
            distanceKm: 4.1,
            averagePaceSeconds: 352,
            cadence: 164,
            elevationGainM: 6,
            variability: 0.09,
            aura: .day,
            shape: .outAndBack,
            environmentCondition: .unknown,
            rareEventCompleted: false
        ),
        routePointCount: 0,
        averageHeartRate: nil,
        source: "healthkit:import",
        sourceLabel: "가져온 기록",
        environmentCondition: .unknown,
        rareEventCompleted: false,
        mutationAxisCount: 0,
        companionBond: 12,
        seasonAffinity: false,
        activeEffects: [],
        livePotentialEnabled: false
    ),
    AdulthoodProfile(
        id: "rich_import",
        title: "풍부한 가져오기",
        summary: RunSummary(
            distanceKm: 6.8,
            averagePaceSeconds: 324,
            cadence: 170,
            elevationGainM: 28,
            variability: 0.1,
            aura: .day,
            shape: .loop,
            environmentCondition: .rain,
            rareEventCompleted: false
        ),
        routePointCount: 8,
        averageHeartRate: 149,
        source: "fit:import",
        sourceLabel: "FIT 가져오기",
        environmentCondition: .rain,
        rareEventCompleted: false,
        mutationAxisCount: 2,
        companionBond: 20,
        seasonAffinity: true,
        activeEffects: activeEffects,
        livePotentialEnabled: false
    ),
    AdulthoodProfile(
        id: "live_sync",
        title: "실시간 동행",
        summary: RunSummary(
            distanceKm: 8.4,
            averagePaceSeconds: 304,
            cadence: 176,
            elevationGainM: 42,
            variability: 0.07,
            aura: .night,
            shape: .loop,
            environmentCondition: .wind,
            rareEventCompleted: true
        ),
        routePointCount: 10,
        averageHeartRate: 156,
        source: "watch",
        sourceLabel: "Apple Watch",
        environmentCondition: .wind,
        rareEventCompleted: true,
        mutationAxisCount: 2,
        companionBond: 28,
        seasonAffinity: true,
        activeEffects: activeEffects,
        livePotentialEnabled: true
    ),
]

func baselineExperience(for summary: RunSummary) -> Int {
    let completedQuestCount = RunimalGameEngine.evaluateRunQuests(for: summary).filter(\.completed).count
    return max(40, Int(summary.distanceKm * 14) + completedQuestCount * 18)
}

func printScenarioTable() {
    print("=== Reward Pulse Simulation ===")
    for scenario in scenarios {
        let baseline = baselineExperience(for: scenario.summary)
        let tuned = RunimalGameEngine.evaluateReward(for: scenario.summary)
        print("")
        print("[\(scenario.id)]")
        print("baseline_xp=\(baseline)")
        print("tuned_xp=\(tuned.experience)")
        print("bonus_labels=\(tuned.bonusLabels.joined(separator: ", "))")
        print("pet=\(tuned.pet.species.rawValue)")
    }
}

func printThresholdSimulations() {
    let sampleRun = CompletedRunRecord(
        id: "sim-run-1",
        startedAt: .now,
        endedAt: .now,
        distanceMeters: 5100,
        durationSeconds: 1700,
        averageHeartRate: 152,
        averagePaceSeconds: 335,
        cadence: 168,
        elevationGainM: 20,
        reward: RunimalGameEngine.evaluateReward(for: scenarios[0].summary),
        route: [],
        source: "simulation",
        environmentCondition: .clear
    )

    let stageProgress = EvolutionProgress(
        stageLabel: "유아기",
        totalExperience: 326,
        nextThreshold: 340,
        progressRatio: 0.91,
        headline: "다음 진화까지 14 XP 남았습니다."
    )
    let stageLock = RunimalRewardPulseEngine.stageLock(
        currentProgress: stageProgress,
        proposedExperience: sampleRun.reward.experience
    )

    let sampleEgg = EggInventoryEntry(
        id: "sim-egg",
        shell: .moss,
        title: "???",
        createdAt: .now,
        sourceRunID: "source-run",
        storedExperience: 128,
        hatchThreshold: 140,
        incubationRunIDs: [],
        unlockedAchievementIDs: [],
        starterBoosted: false
    )
    let hatchLock = RunimalRewardPulseEngine.hatchLock(
        egg: sampleEgg,
        proposedExperience: 6
    )

    print("")
    print("=== Threshold Assist Simulation ===")
    print("stage_lock_bonus=\(stageLock.bonusExperience) labels=\(stageLock.bonusLabels.joined(separator: ", "))")
    print("decode_lock_bonus=\(hatchLock.bonusExperience) labels=\(hatchLock.bonusLabels.joined(separator: ", "))")
}

func printGrowthSimulationTable() {
    print("")
    print("=== Growth Feed Simulation ===")
    for scenario in growthScenarios {
        let result = simulateGrowth(for: scenario)
        print("")
        print("[\(result.scenarioID)]")
        print("base_xp=\(result.baseExperience)")
        print("resonance_bonus=\(result.resonanceBonus)")
        print("forge_bonus=\(result.forgeBonus)")
        print("build_bonus=\(result.buildBonus)")
        print("interaction_bonus=\(result.interactionBonus)")
        print("data_bonus=\(result.dataBonus)")
        print("potential_generated=\(result.potentialGenerated)")
        print("potential_spent=\(result.potentialSpent)")
        print("stage_lock_bonus=\(result.stageLockBonus)")
        print("total_gain=\(result.totalGainedExperience)")
        print("level=\(result.levelBefore)->\(result.levelAfter)")
        print("stage=\(result.stageBefore)->\(result.stageAfter)")
        print("interaction_labels=\(result.interactionLabels.joined(separator: ", "))")
        print("bonus_labels=\(result.outputLabels.joined(separator: ", "))")
    }
}

func printAdulthoodSimulationTable() {
    print("")
    print("=== Adulthood Run Simulation ===")
    for profile in adulthoodProfiles {
        print("")
        print("[\(profile.id)]")
        for species in PetSpecies.allCases {
            let result = simulateRunsToAdult(for: species, profile: profile)
            print(
                "\(species.rawValue) runs=\(result.runsToAdult) " +
                "adult_level=\(result.adultLevel) " +
                "xp=\(result.totalExperienceAtAdult) " +
                "gain=\(result.firstGain)/\(result.averageGain)/\(result.finalGain)"
            )
        }
    }
}

func printMaxLevelSimulationTable() {
    print("")
    print("=== Level Cap Run Simulation ===")
    for profile in adulthoodProfiles {
        print("")
        print("[\(profile.id)]")
        for species in PetSpecies.allCases {
            let result = simulateRunsToLevelCap(for: species, profile: profile)
            print(
                "\(species.rawValue) adult=\(result.runsToAdult) " +
                "cap=\(result.runsToLevelCap) " +
                "post_adult=\(result.postAdultRuns) " +
                "post_gain=\(result.postAdultAverageGain) " +
                "gain=\(result.firstGain)/\(result.averageGain)/\(result.finalGain)"
            )
        }
    }
}

func simulateGrowth(for scenario: GrowthScenario) -> GrowthSimulationResult {
    let reward = RunimalGameEngine.evaluateReward(for: scenario.summary)
    let pet = companionPet(for: scenario, reward: reward)
    let companion = makeCompanion(
        id: scenario.companionID,
        pet: pet,
        level: scenario.currentGrowthRecord.map { RunimalBalanceConfig.companionLevel(forExperience: $0.totalExperience) } ?? 1,
        bond: scenario.companionBond,
        headline: scenario.companionHeadline
    )

    let run = makeCompletedRun(
        id: "run-\(scenario.id)",
        summary: scenario.summary,
        averageHeartRate: scenario.averageHeartRate,
        routePointCount: scenario.routePointCount,
        source: scenario.source,
        sourceLabel: scenario.sourceLabel,
        reward: reward,
        environmentCondition: scenario.environmentCondition,
        rareEventCompleted: scenario.rareEventCompleted,
        liveCompanionID: scenario.liveCompanionName == nil ? nil : companion.id,
        liveCompanionName: scenario.liveCompanionName,
        mutationAxisCount: scenario.mutationAxisCount,
        worldImpact: scenario.worldImpact
    )

    let currentRecord = scenario.currentGrowthRecord
    let beforeProgress = RunimalCompanionGrowthEngine.evolutionProgress(
        for: currentRecord,
        species: companion.pet.species
    )
    let levelBefore = RunimalBalanceConfig.companionLevel(forExperience: currentRecord?.totalExperience ?? 0)

    let resonance = RunimalEffectResonanceEngine.effectResonance(
        for: companion,
        progress: beforeProgress,
        activeEffects: scenario.activeEffects
    )
    let resonanceBonus = RunimalCompanionGrowthEngine.feedBonusExperience(
        baseExperience: run.reward.experience,
        resonance: resonance
    )
    let forgeBonusProfile = RunimalEssenceForgeEngine.bonusExperience(
        using: scenario.forgeInventory,
        companion: companion,
        season: scenario.season
    )
    let buildBonus = RunimalCompanionBuildEngine.feedBonus(
        for: scenario.buildState,
        run: run,
        companion: companion
    )

    var interactionEvents: [CompanionProgressionEvent] = []
    if let lastFedAt = currentRecord?.lastFedAt {
        if Calendar.current.isDate(lastFedAt, inSameDayAs: Date()) == false {
            interactionEvents.append(.firstFeedOfDay)
        }
    } else {
        interactionEvents.append(.firstFeedOfDay)
    }
    if canonicalProgressionSpeciesID(for: run.reward.pet.species) == canonicalProgressionSpeciesID(for: companion.pet.species) {
        interactionEvents.append(.matchingSpecies)
    }
    if let runVariant = run.reward.pet.rareVariant,
       runVariant == companion.pet.rareVariant {
        interactionEvents.append(.matchingVariant)
    }
    if RunimalGameEngine.seasonAffinity(for: companion.pet, season: scenario.season) {
        interactionEvents.append(.seasonAffinity)
    }
    if run.reward.completedQuestCount >= 2 {
        interactionEvents.append(.masteryLink)
    }
    if let latestAssignedRun = scenario.latestAssignedRun,
       latestAssignedRun.worldImpact?.regionID == run.worldImpact?.regionID {
        interactionEvents.append(.homeRegion)
    }
    if run.worldImpact?.episodeID != nil {
        interactionEvents.append(.episodeSignal)
    }
    if run.worldImpact?.unlockedRegion == true {
        interactionEvents.append(.regionUnlock)
    }
    if run.worldImpact?.unlockedSeason == true {
        interactionEvents.append(.seasonUnlock)
    }
    if run.worldImpact?.unlockedEpisode == true {
        interactionEvents.append(.episodeUnlock)
    }

    let interactionBonus = RunimalCompanionProgressionEngine.interactionBonus(
        baseExperience: run.reward.experience,
        events: interactionEvents,
        stageIndex: RunimalCompanionGrowthEngine.stageIndex(for: beforeProgress)
    )
    let dataProfile = RunimalRunCoreGrowthBalanceEngine.dataProfile(for: run)
    let generatedPotential = RunimalRunCoreGrowthBalanceEngine.livePotential(for: run)
    let seasonAligned = RunimalGameEngine.seasonAffinity(for: companion.pet, season: scenario.season)
    let storedPotential = currentRecord?.storedPotentialExperience ?? 0
    let potentialSpend = min(
        storedPotential,
        RunimalRunCoreGrowthBalanceEngine.potentialSpendCap(
            baseExperience: run.reward.experience,
            level: levelBefore
        )
    )
    let lateGrowthBonus = RunimalCompanionProgressionEngine.lateGrowthBonus(
        level: levelBefore,
        dataProfile: dataProfile,
        potentialSpend: potentialSpend,
        seasonAligned: seasonAligned,
        worldImpact: run.worldImpact
    )
    let retainedGrowthLabels = RunimalCompanionProgressionEngine.lateGrowthRetentionLabels(
        level: levelBefore,
        run: run,
        dataProfile: dataProfile,
        seasonTitle: scenario.season.title,
        seasonAligned: seasonAligned
    )
    let rawExperience = run.reward.experience +
        dataProfile.bonusExperience +
        resonanceBonus +
        forgeBonusProfile.bonus +
        buildBonus +
        interactionBonus.bonusExperience +
        lateGrowthBonus.bonusExperience +
        potentialSpend
    let starterStageGuarantee = (currentRecord?.feedCount ?? 0) == 0 &&
        (currentRecord?.totalExperience ?? 0) >= 100 &&
        beforeProgress.stageLabel == RunimalBalanceConfig.eggStageLabel
    let stageLock = RunimalRewardPulseEngine.stageLock(
        currentProgress: beforeProgress,
        proposedExperience: rawExperience
    )

    let gainedExperience: Int
    if starterStageGuarantee {
        let firstThreshold = RunimalBalanceConfig.evolutionThresholds(for: companion.pet.species)[1]
        gainedExperience = max(
            rawExperience + stageLock.bonusExperience,
            max(0, firstThreshold - (currentRecord?.totalExperience ?? 0))
        )
    } else {
        gainedExperience = rawExperience + stageLock.bonusExperience
    }

    let updated = CompanionGrowthRecord(
        companionID: companion.id,
        totalExperience: (currentRecord?.totalExperience ?? 0) + gainedExperience,
        storedPotentialExperience: max(storedPotential - potentialSpend, 0),
        feedCount: (currentRecord?.feedCount ?? 0) + 1,
        assignedRunIDs: (currentRecord?.assignedRunIDs ?? []) + [run.id],
        lastFedAt: run.endedAt
    )
    let afterProgress = RunimalCompanionGrowthEngine.evolutionProgress(
        for: updated,
        species: companion.pet.species
    )
    let outputLabels = stageLock.bonusLabels +
        interactionBonus.labels +
        lateGrowthBonus.labels +
        retainedGrowthLabels +
        (potentialSpend > 0 ? ["동행 잠재 사용 +\(potentialSpend)"] : [])

    return GrowthSimulationResult(
        scenarioID: scenario.id,
        baseExperience: run.reward.experience,
        resonanceBonus: resonanceBonus,
        forgeBonus: forgeBonusProfile.bonus,
        buildBonus: buildBonus,
        interactionBonus: interactionBonus.bonusExperience,
        dataBonus: dataProfile.bonusExperience,
        potentialGenerated: generatedPotential.storedPotentialExperience,
        potentialSpent: potentialSpend,
        stageLockBonus: stageLock.bonusExperience,
        totalGainedExperience: gainedExperience,
        levelBefore: levelBefore,
        levelAfter: RunimalBalanceConfig.companionLevel(forExperience: updated.totalExperience),
        stageBefore: beforeProgress.stageLabel,
        stageAfter: afterProgress.stageLabel,
        interactionLabels: interactionBonus.labels,
        outputLabels: outputLabels
    )
}

func simulateGrowthStep(
    scenarioID: String,
    companion: PetCollectionEntry,
    currentRecord: CompanionGrowthRecord?,
    latestAssignedRun: CompletedRunRecord?,
    profile: AdulthoodProfile,
    season: WeeklySeason
) -> GrowthStepResult {
    let reward = makeRewardAligned(
        to: companion.pet.species,
        reward: RunimalGameEngine.evaluateReward(for: profile.summary)
    )
    let run = makeCompletedRun(
        id: scenarioID,
        summary: profile.summary,
        averageHeartRate: profile.averageHeartRate,
        routePointCount: profile.routePointCount,
        source: profile.source,
        sourceLabel: profile.sourceLabel,
        reward: reward,
        environmentCondition: profile.environmentCondition,
        rareEventCompleted: profile.rareEventCompleted,
        liveCompanionID: profile.livePotentialEnabled ? companion.id : nil,
        liveCompanionName: profile.livePotentialEnabled ? companion.pet.species.displayName : nil,
        mutationAxisCount: profile.mutationAxisCount,
        worldImpact: nil
    )

    let beforeProgress = RunimalCompanionGrowthEngine.evolutionProgress(
        for: currentRecord,
        species: companion.pet.species
    )
    let levelBefore = RunimalBalanceConfig.companionLevel(forExperience: currentRecord?.totalExperience ?? 0)
    let resonance = RunimalEffectResonanceEngine.effectResonance(
        for: companion,
        progress: beforeProgress,
        activeEffects: profile.activeEffects
    )
    let resonanceBonus = RunimalCompanionGrowthEngine.feedBonusExperience(
        baseExperience: run.reward.experience,
        resonance: resonance
    )

    var interactionEvents: [CompanionProgressionEvent] = []
    if let lastFedAt = currentRecord?.lastFedAt {
        if Calendar.current.isDate(lastFedAt, inSameDayAs: Date()) == false {
            interactionEvents.append(.firstFeedOfDay)
        }
    } else {
        interactionEvents.append(.firstFeedOfDay)
    }
    interactionEvents.append(.matchingSpecies)
    if RunimalGameEngine.seasonAffinity(for: companion.pet, season: season) {
        interactionEvents.append(.seasonAffinity)
    }
    if run.reward.completedQuestCount >= 2 {
        interactionEvents.append(.masteryLink)
    }
    if let latestAssignedRun,
       latestAssignedRun.worldImpact?.regionID == run.worldImpact?.regionID {
        interactionEvents.append(.homeRegion)
    }

    let interactionBonus = RunimalCompanionProgressionEngine.interactionBonus(
        baseExperience: run.reward.experience,
        events: interactionEvents,
        stageIndex: RunimalCompanionGrowthEngine.stageIndex(for: beforeProgress)
    )
    let dataProfile = RunimalRunCoreGrowthBalanceEngine.dataProfile(for: run)
    let generatedPotential = RunimalRunCoreGrowthBalanceEngine.livePotential(for: run)
    let seasonAligned = RunimalGameEngine.seasonAffinity(for: companion.pet, season: season)
    let storedPotential = currentRecord?.storedPotentialExperience ?? 0
    let potentialSpend = min(
        storedPotential,
        RunimalRunCoreGrowthBalanceEngine.potentialSpendCap(
            baseExperience: run.reward.experience,
            level: levelBefore
        )
    )
    let lateGrowthBonus = RunimalCompanionProgressionEngine.lateGrowthBonus(
        level: levelBefore,
        dataProfile: dataProfile,
        potentialSpend: potentialSpend,
        seasonAligned: seasonAligned,
        worldImpact: run.worldImpact
    )
    let retainedGrowthLabels = RunimalCompanionProgressionEngine.lateGrowthRetentionLabels(
        level: levelBefore,
        run: run,
        dataProfile: dataProfile,
        seasonTitle: season.title,
        seasonAligned: seasonAligned
    )
    let rawExperience = run.reward.experience +
        dataProfile.bonusExperience +
        resonanceBonus +
        interactionBonus.bonusExperience +
        lateGrowthBonus.bonusExperience +
        potentialSpend
    let stageLock = RunimalRewardPulseEngine.stageLock(
        currentProgress: beforeProgress,
        proposedExperience: rawExperience
    )
    let gainedExperience = rawExperience + stageLock.bonusExperience
    let updated = CompanionGrowthRecord(
        companionID: companion.id,
        totalExperience: (currentRecord?.totalExperience ?? 0) + gainedExperience,
        storedPotentialExperience: max(storedPotential - potentialSpend, 0),
        feedCount: (currentRecord?.feedCount ?? 0) + 1,
        assignedRunIDs: (currentRecord?.assignedRunIDs ?? []) + [run.id],
        lastFedAt: run.endedAt
    )
    let afterProgress = RunimalCompanionGrowthEngine.evolutionProgress(
        for: updated,
        species: companion.pet.species
    )
    let outputLabels = stageLock.bonusLabels +
        interactionBonus.labels +
        lateGrowthBonus.labels +
        retainedGrowthLabels +
        (potentialSpend > 0 ? ["동행 잠재 사용 +\(potentialSpend)"] : [])

    let result = GrowthSimulationResult(
        scenarioID: scenarioID,
        baseExperience: run.reward.experience,
        resonanceBonus: resonanceBonus,
        forgeBonus: 0,
        buildBonus: 0,
        interactionBonus: interactionBonus.bonusExperience,
        dataBonus: dataProfile.bonusExperience,
        potentialGenerated: generatedPotential.storedPotentialExperience,
        potentialSpent: potentialSpend,
        stageLockBonus: stageLock.bonusExperience,
        totalGainedExperience: gainedExperience,
        levelBefore: levelBefore,
        levelAfter: RunimalBalanceConfig.companionLevel(forExperience: updated.totalExperience),
        stageBefore: beforeProgress.stageLabel,
        stageAfter: afterProgress.stageLabel,
        interactionLabels: interactionBonus.labels,
        outputLabels: outputLabels
    )

    return GrowthStepResult(
        result: result,
        updatedRecord: updated,
        run: run
    )
}

func simulateRunsToAdult(for species: PetSpecies, profile: AdulthoodProfile) -> AdulthoodSimulationResult {
    let season = makeSeason(
        title: "\(profile.title) 시즌",
        focusSpecies: profile.seasonAffinity ? species : alternateSpecies(for: species),
        focusVariant: nil
    )
    let companion = makeCompanion(
        id: "adult-\(profile.id)-\(species.rawValue)",
        pet: templatePet(for: species),
        level: 1,
        bond: profile.companionBond,
        headline: "\(profile.title) 성장선"
    )

    var growthRecord: CompanionGrowthRecord?
    var latestAssignedRun: CompletedRunRecord?
    var gains: [Int] = []
    var runCount = 0

    while runCount < 80 {
        let effectiveRecord: CompanionGrowthRecord?
        if profile.livePotentialEnabled {
            let liveReward = makeRewardAligned(
                to: species,
                reward: RunimalGameEngine.evaluateReward(for: profile.summary)
            )
            let liveRun = makeCompletedRun(
                id: "live-pre-\(profile.id)-\(species.rawValue)-\(runCount)",
                summary: profile.summary,
                averageHeartRate: profile.averageHeartRate,
                routePointCount: profile.routePointCount,
                source: profile.source,
                sourceLabel: profile.sourceLabel,
                reward: liveReward,
                environmentCondition: profile.environmentCondition,
                rareEventCompleted: profile.rareEventCompleted,
                liveCompanionID: companion.id,
                liveCompanionName: companion.pet.species.displayName,
                mutationAxisCount: profile.mutationAxisCount,
                worldImpact: nil
            )
            let gainedPotential = RunimalRunCoreGrowthBalanceEngine.livePotential(for: liveRun).storedPotentialExperience
            let currentLevel = RunimalBalanceConfig.companionLevel(forExperience: growthRecord?.totalExperience ?? 0)
            effectiveRecord = CompanionGrowthRecord(
                companionID: companion.id,
                totalExperience: growthRecord?.totalExperience ?? 0,
                storedPotentialExperience: min(
                    (growthRecord?.storedPotentialExperience ?? 0) + gainedPotential,
                    RunimalRunCoreGrowthBalanceEngine.storedPotentialCap(forLevel: currentLevel)
                ),
                feedCount: growthRecord?.feedCount ?? 0,
                assignedRunIDs: growthRecord?.assignedRunIDs ?? [],
                lastFedAt: growthRecord?.lastFedAt
            )
        } else {
            effectiveRecord = growthRecord
        }

        let step = simulateGrowthStep(
            scenarioID: "adult-\(profile.id)-\(species.rawValue)-\(runCount)",
            companion: companion,
            currentRecord: effectiveRecord,
            latestAssignedRun: latestAssignedRun,
            profile: profile,
            season: season
        )
        growthRecord = step.updatedRecord
        latestAssignedRun = step.run
        gains.append(step.result.totalGainedExperience)
        runCount += 1

        if step.result.stageAfter == RunimalBalanceConfig.finalStageLabel {
            break
        }
    }

    let finalXP = growthRecord?.totalExperience ?? 0
    return AdulthoodSimulationResult(
        profileID: profile.id,
        profileTitle: profile.title,
        species: species,
        runsToAdult: runCount,
        totalExperienceAtAdult: finalXP,
        adultLevel: RunimalBalanceConfig.companionLevel(forExperience: finalXP),
        firstGain: gains.first ?? 0,
        averageGain: gains.isEmpty ? 0 : Int((Double(gains.reduce(0, +)) / Double(gains.count)).rounded()),
        finalGain: gains.last ?? 0
    )
}

func simulateRunsToLevelCap(for species: PetSpecies, profile: AdulthoodProfile) -> MaxLevelSimulationResult {
    let season = makeSeason(
        title: "\(profile.title) 시즌",
        focusSpecies: profile.seasonAffinity ? species : alternateSpecies(for: species),
        focusVariant: nil
    )
    let companion = makeCompanion(
        id: "cap-\(profile.id)-\(species.rawValue)",
        pet: templatePet(for: species),
        level: 1,
        bond: profile.companionBond,
        headline: "\(profile.title) 레벨 캡"
    )

    var growthRecord: CompanionGrowthRecord?
    var latestAssignedRun: CompletedRunRecord?
    var gains: [Int] = []
    var postAdultGains: [Int] = []
    var runCount = 0
    var runsToAdult: Int?

    while runCount < 320 {
        let effectiveRecord: CompanionGrowthRecord?
        if profile.livePotentialEnabled {
            let liveReward = makeRewardAligned(
                to: species,
                reward: RunimalGameEngine.evaluateReward(for: profile.summary)
            )
            let liveRun = makeCompletedRun(
                id: "live-cap-\(profile.id)-\(species.rawValue)-\(runCount)",
                summary: profile.summary,
                averageHeartRate: profile.averageHeartRate,
                routePointCount: profile.routePointCount,
                source: profile.source,
                sourceLabel: profile.sourceLabel,
                reward: liveReward,
                environmentCondition: profile.environmentCondition,
                rareEventCompleted: profile.rareEventCompleted,
                liveCompanionID: companion.id,
                liveCompanionName: companion.pet.species.displayName,
                mutationAxisCount: profile.mutationAxisCount,
                worldImpact: nil
            )
            let gainedPotential = RunimalRunCoreGrowthBalanceEngine.livePotential(for: liveRun).storedPotentialExperience
            let currentLevel = RunimalBalanceConfig.companionLevel(forExperience: growthRecord?.totalExperience ?? 0)
            effectiveRecord = CompanionGrowthRecord(
                companionID: companion.id,
                totalExperience: growthRecord?.totalExperience ?? 0,
                storedPotentialExperience: min(
                    (growthRecord?.storedPotentialExperience ?? 0) + gainedPotential,
                    RunimalRunCoreGrowthBalanceEngine.storedPotentialCap(forLevel: currentLevel)
                ),
                feedCount: growthRecord?.feedCount ?? 0,
                assignedRunIDs: growthRecord?.assignedRunIDs ?? [],
                lastFedAt: growthRecord?.lastFedAt
            )
        } else {
            effectiveRecord = growthRecord
        }

        let beforeProgress = RunimalCompanionGrowthEngine.evolutionProgress(
            for: effectiveRecord,
            species: species
        )
        let step = simulateGrowthStep(
            scenarioID: "cap-\(profile.id)-\(species.rawValue)-\(runCount)",
            companion: companion,
            currentRecord: effectiveRecord,
            latestAssignedRun: latestAssignedRun,
            profile: profile,
            season: season
        )
        growthRecord = step.updatedRecord
        latestAssignedRun = step.run
        gains.append(step.result.totalGainedExperience)
        runCount += 1

        if beforeProgress.stageLabel == RunimalBalanceConfig.finalStageLabel {
            postAdultGains.append(step.result.totalGainedExperience)
        } else if step.result.stageAfter == RunimalBalanceConfig.finalStageLabel, runsToAdult == nil {
            runsToAdult = runCount
        }

        if RunimalBalanceConfig.companionLevel(forExperience: step.updatedRecord.totalExperience) >= RunimalBalanceConfig.companionLevelCap {
            break
        }
    }

    let finalXP = growthRecord?.totalExperience ?? 0
    return MaxLevelSimulationResult(
        profileID: profile.id,
        profileTitle: profile.title,
        species: species,
        runsToAdult: runsToAdult ?? runCount,
        runsToLevelCap: runCount,
        postAdultRuns: max(runCount - (runsToAdult ?? runCount), 0),
        totalExperienceAtCap: finalXP,
        firstGain: gains.first ?? 0,
        averageGain: gains.isEmpty ? 0 : Int((Double(gains.reduce(0, +)) / Double(gains.count)).rounded()),
        postAdultAverageGain: postAdultGains.isEmpty ? 0 : Int((Double(postAdultGains.reduce(0, +)) / Double(postAdultGains.count)).rounded()),
        finalGain: gains.last ?? 0
    )
}

func companionPet(for scenario: GrowthScenario, reward: RunRewardSummary) -> GeneratedPet {
    if scenario.id == "world_unlock_peak" {
        return makePet(species: .shadebit, rareVariant: .eclipseMark, reward: reward)
    }

    return reward.pet
}

func templatePet(for species: PetSpecies) -> GeneratedPet {
    let templateReward = RunimalGameEngine.evaluateReward(
        for: RunSummary(
            distanceKm: 5.0,
            averagePaceSeconds: 330,
            cadence: 168,
            elevationGainM: 18,
            variability: 0.08,
            aura: .day,
            shape: .freeform,
            environmentCondition: .clear,
            rareEventCompleted: false
        )
    )
    return makePet(species: species, rareVariant: nil, reward: templateReward)
}

func makePet(species: PetSpecies, rareVariant: RareVariant?, reward: RunRewardSummary) -> GeneratedPet {
    GeneratedPet(
        species: species,
        element: reward.pet.element,
        palette: reward.pet.palette,
        rareVariant: rareVariant,
        explanation: reward.pet.explanation,
        stats: reward.pet.stats
    )
}

func makeRewardAligned(to species: PetSpecies, reward: RunRewardSummary) -> RunRewardSummary {
    RunRewardSummary(
        pet: makePet(species: species, rareVariant: nil, reward: reward),
        coreLabel: reward.coreLabel,
        experience: reward.experience,
        completedQuestCount: reward.completedQuestCount,
        flavorText: reward.flavorText,
        bonusLabels: reward.bonusLabels
    )
}

func alternateSpecies(for species: PetSpecies) -> PetSpecies {
    PetSpecies.allCases.first(where: { $0 != species }) ?? .windrunner
}

func makeCompanion(
    id: String,
    pet: GeneratedPet,
    level: Int,
    bond: Int,
    headline: String
) -> PetCollectionEntry {
    PetCollectionEntry(
        id: id,
        pet: pet,
        level: level,
        bond: bond,
        totalDistanceKm: Double(level * 6),
        headline: headline
    )
}

func makeCompletedRun(
    id: String,
    summary: RunSummary,
    averageHeartRate: Double?,
    routePointCount: Int,
    source: String,
    sourceLabel: String?,
    reward: RunRewardSummary,
    environmentCondition: EnvironmentCondition,
    rareEventCompleted: Bool,
    liveCompanionID: String?,
    liveCompanionName: String?,
    mutationAxisCount: Int,
    worldImpact: WorldRunImpact?
) -> CompletedRunRecord {
    let route = makeRoute(count: routePointCount)
    let mutationContribution = makeMutationContribution(
        species: reward.pet.species,
        axisCount: mutationAxisCount
    )

    let baseRun = CompletedRunRecord(
        id: id,
        startedAt: fixedStartDate(for: summary.aura),
        endedAt: fixedStartDate(for: summary.aura).addingTimeInterval(TimeInterval(summary.durationSeconds)),
        distanceMeters: summary.distanceKm * 1_000,
        durationSeconds: summary.durationSeconds,
        averageHeartRate: averageHeartRate,
        averagePaceSeconds: summary.averagePaceSeconds,
        cadence: summary.cadence,
        elevationGainM: summary.elevationGainM,
        reward: reward,
        route: route,
        source: source,
        sourceLabel: sourceLabel,
        environmentCondition: environmentCondition,
        rareEventCompleted: rareEventCompleted,
        liveCompanionID: liveCompanionID,
        liveCompanionName: liveCompanionName,
        livePotentialProfile: nil,
        mutationForm: mutationContribution == nil ? nil : MutationFormSnapshot(
            speciesID: canonicalProgressionSpeciesID(for: reward.pet.species),
            formID: "sim-\(canonicalProgressionSpeciesID(for: reward.pet.species))",
            shortLabel: "시뮬레이션 폼",
            bodyBranchID: "body-sim",
            ecologyBranchID: "eco-sim",
            rhythmBranchID: "rhythm-sim",
            confidence: 0.82
        ),
        mutationContribution: mutationContribution,
        worldImpact: worldImpact
    )

    let livePotentialProfile = liveCompanionID == nil ? nil : RunimalRunCoreGrowthBalanceEngine.livePotential(for: baseRun)

    return CompletedRunRecord(
        id: baseRun.id,
        startedAt: baseRun.startedAt,
        endedAt: baseRun.endedAt,
        distanceMeters: baseRun.distanceMeters,
        durationSeconds: baseRun.durationSeconds,
        averageHeartRate: baseRun.averageHeartRate,
        averagePaceSeconds: baseRun.averagePaceSeconds,
        cadence: baseRun.cadence,
        elevationGainM: baseRun.elevationGainM,
        reward: baseRun.reward,
        route: baseRun.route,
        source: baseRun.source,
        sourceLabel: baseRun.sourceLabel,
        raidContribution: baseRun.raidContribution,
        environmentCondition: baseRun.environmentCondition,
        rareEventCompleted: baseRun.rareEventCompleted,
        liveCompanionID: baseRun.liveCompanionID,
        liveCompanionName: baseRun.liveCompanionName,
        livePotentialProfile: livePotentialProfile,
        mutationForm: baseRun.mutationForm,
        mutationContribution: baseRun.mutationContribution,
        worldImpact: baseRun.worldImpact
    )
}

func makeRoute(count: Int) -> [RoutePoint] {
    guard count > 0 else { return [] }
    let start = fixedStartDate(for: .day)
    var points: [RoutePoint] = []
    points.reserveCapacity(count)
    for index in 0..<count {
        let latitude = 37.55 + (Double(index) * 0.0012)
        let longitude = 126.97 + (Double(index) * 0.0011)
        let altitude = 18 + (Double(index) * 1.6)
        let timestamp = start.addingTimeInterval(Double(index * 120))
        points.append(
            RoutePoint(
                latitude: latitude,
                longitude: longitude,
                altitude: altitude,
                timestamp: timestamp
            )
        )
    }
    return points
}

func makeMutationContribution(species: PetSpecies, axisCount: Int) -> MutationRunContributionSnapshot? {
    guard axisCount > 0 else { return nil }
    let canonicalSpecies = canonicalProgressionSpeciesID(for: species)
    let axes = Array(SpeciesLineageAxis.allCases.prefix(axisCount)).enumerated().map { index, axis in
        MutationAxisContributionSnapshot(
            axis: axis,
            branchID: "\(axis.rawValue)-\(index + 1)",
            branchTitle: "\(axis.rawValue)-signal-\(index + 1)",
            score: 12 + (index * 3),
            progress: min(0.34 + (Double(index) * 0.14), 0.92)
        )
    }
    return MutationRunContributionSnapshot(speciesID: canonicalSpecies, axes: axes)
}

func makeSeason(title: String, focusSpecies: PetSpecies, focusVariant: RareVariant?) -> WeeklySeason {
    WeeklySeason(
        title: title,
        subtitle: "시뮬레이션 시즌",
        bonus: "시뮬레이션용 성장 보정",
        rewardTitle: "시뮬레이션 보상",
        evolutionTitle: "시뮬레이션 진화",
        focusSpecies: focusSpecies,
        focusVariant: focusVariant
    )
}

func canonicalProgressionSpeciesID(for species: PetSpecies) -> String {
    switch species {
    case .shadebit:
        return PetSpecies.sparkfang.rawValue
    default:
        return species.rawValue
    }
}

func fixedStartDate(for aura: RunTimeAura) -> Date {
    var components = DateComponents()
    components.calendar = Calendar(identifier: .gregorian)
    components.year = 2026
    components.month = 4
    components.day = 2
    switch aura {
    case .dawn:
        components.hour = 6
        components.minute = 10
    case .day:
        components.hour = 9
        components.minute = 0
    case .dusk:
        components.hour = 19
        components.minute = 10
    case .night:
        components.hour = 21
        components.minute = 5
    }
    return components.date ?? Date(timeIntervalSince1970: 0)
}

private extension RunSummary {
    var durationSeconds: Int {
        Int((distanceKm * Double(averagePaceSeconds)).rounded())
    }
}

printScenarioTable()
printThresholdSimulations()
printGrowthSimulationTable()
printAdulthoodSimulationTable()
printMaxLevelSimulationTable()
