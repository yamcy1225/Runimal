import Foundation
import RunimalCore

struct RewardScenario {
    let id: String
    let summary: RunSummary
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

func baselineExperience(for summary: RunSummary) -> Int {
    let completedQuestCount = RunimalGameEngine.evaluateRunQuests(for: summary).filter(\.completed).count
    return max(40, Int(summary.distanceKm * 14) + completedQuestCount * 18)
}

func printScenarioTable() {
    print("=== Reward Pulse Simulation ===")
    for scenario in scenarios {
        let baseline = baselineExperience(for: scenario.summary)
        let tuned = RunimalGameEngine.evaluateReward(for: scenario.summary)
        print("\n[\(scenario.id)]")
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
        environmentCondition: .clear,
    )

    let stageProgress = EvolutionProgress(
        stageLabel: "Stage 1",
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

    print("\n=== Threshold Assist Simulation ===")
    print("stage_lock_bonus=\(stageLock.bonusExperience) labels=\(stageLock.bonusLabels.joined(separator: ", "))")
    print("decode_lock_bonus=\(hatchLock.bonusExperience) labels=\(hatchLock.bonusLabels.joined(separator: ", "))")
}

printScenarioTable()
printThresholdSimulations()
