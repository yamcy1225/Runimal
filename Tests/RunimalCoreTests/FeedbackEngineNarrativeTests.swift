import Foundation
import Testing
@testable import RunimalCore

struct FeedbackEngineNarrativeTests {
    private let defaultSeason = WeeklySeason(
        title: "봄 숨결",
        subtitle: "안정 구간 주간",
        bonus: "안정 러닝 보너스",
        rewardTitle: "시즌 보상",
        evolutionTitle: "성장 가속",
        focusSpecies: .seedle,
        focusVariant: nil
    )

    @Test
    func hatchMomentNarrativeUsesLivePotentialAndCompanionContext() {
        let pet = GeneratedPet(
            species: .seedle,
            element: .leaf,
            palette: "leaf",
            rareVariant: nil,
            explanation: [],
            stats: PetStats(vitality: 12, agility: 11, dexterity: 13, focus: 10, defense: 9)
        )
        let companion = PetCollectionEntry(
            id: "hatched-egg-run",
            pet: pet,
            level: 1,
            bond: 18,
            totalDistanceKm: 6.2,
            headline: "숨겨진 알에서 깨어난 동행"
        )
        let egg = EggInventoryEntry(
            id: "egg-run",
            shell: .gale,
            title: "바람 알",
            createdAt: .distantPast,
            sourceRunID: "run-1",
            storedExperience: 120,
            hatchThreshold: 120,
            incubationRunIDs: ["run-2"],
            unlockedAchievementIDs: [],
            starterBoosted: false
        )
        let sourceRun = CompletedRunRecord(
            id: "run-1",
            startedAt: .distantPast,
            endedAt: .distantPast,
            distanceMeters: 6200,
            durationSeconds: 1800,
            averageHeartRate: 152,
            averagePaceSeconds: 290,
            cadence: 176,
            elevationGainM: 48,
            reward: RunRewardSummary(
                pet: pet,
                coreLabel: "바람결 기록",
                experience: 130,
                completedQuestCount: 1,
                flavorText: "테스트"
            ),
            route: [],
            source: "watch-healthkit",
            liveCompanionID: "live-companion",
            liveCompanionName: "에이라리스",
            livePotentialProfile: LiveCompanionPotentialProfile(
                eventScore: 7,
                storedPotentialExperience: 10,
                labels: ["동행 잠재 +10"]
            )
        )

        let narrative = RunimalGameEngine.hatchMomentNarrative(
            egg: egg,
            pet: companion,
            sourceRun: sourceRun
        )

        #expect(narrative.title == "함께 달린 반응이 생명으로 굳음")
        #expect(narrative.detail.contains("에이라리스"))
        #expect(narrative.badges.contains("잠재 +10"))
    }

    @Test
    func growthMomentNarrativeHighlightsStageAdvanceWhenDataAndPotentialAlign() {
        let pet = GeneratedPet(
            species: .sparkfang,
            element: .flame,
            palette: "ember",
            rareVariant: nil,
            explanation: [],
            stats: PetStats(vitality: 14, agility: 14, dexterity: 15, focus: 11, defense: 10)
        )
        let beforeProgress = EvolutionProgress(
            stageLabel: "유년기",
            totalExperience: 900,
            nextThreshold: 1100,
            progressRatio: 0.84,
            headline: "다음 진화까지 200 XP 남았습니다."
        )
        let afterProgress = EvolutionProgress(
            stageLabel: "청소년기",
            totalExperience: 1180,
            nextThreshold: 1800,
            progressRatio: 0.05,
            headline: "다음 진화까지 620 XP 남았습니다."
        )
        let beforeSnapshot = CompanionProgressionSnapshot(
            level: 11,
            stageIndex: 2,
            progress: beforeProgress,
            evolutionMilestones: [],
            nextEvolutionMilestone: nil,
            stageUnlockWindow: [],
            lateGrowthWindow: [],
            lateGrowthFeatures: RunimalBalanceConfig.lateGrowthFeatures(forLevel: 11),
            evolutionSummary: nil
        )
        let afterSnapshot = CompanionProgressionSnapshot(
            level: 12,
            stageIndex: 3,
            progress: afterProgress,
            evolutionMilestones: [],
            nextEvolutionMilestone: nil,
            stageUnlockWindow: [],
            lateGrowthWindow: [],
            lateGrowthFeatures: RunimalBalanceConfig.lateGrowthFeatures(forLevel: 12),
            evolutionSummary: nil
        )
        let outcome = CompanionFeedOutcome(
            runID: "run-2",
            coreLabel: "고밀도 기록",
            gainedExperience: 280,
            baseExperience: 120,
            supportBonusExperience: 40,
            dataBonusExperience: 16,
            storedPotentialExperienceBefore: 14,
            potentialExperienceSpent: 12,
            remainingStoredPotentialExperience: 2,
            bonusLabels: ["기록 밀도 +16", "동행 잠재 사용 +12"],
            beforeSnapshot: beforeSnapshot,
            afterSnapshot: afterSnapshot,
            beforeProgress: beforeProgress,
            afterProgress: afterProgress,
            stageAdvanced: true
        )

        let narrative = RunimalGameEngine.growthMomentNarrative(pet: pet, outcome: outcome)

        #expect(narrative.title == "기록과 잠재가 함께 터짐")
        #expect(narrative.detail.contains("청소년기"))
        #expect(narrative.badges.contains("기록 밀도 +16"))
        #expect(narrative.badges.contains("잠재 +12"))
    }

    @Test
    func evolutionTargetProvidesConcreteTemplateNearThreshold() {
        let progress = EvolutionProgress(
            stageLabel: "청소년기",
            totalExperience: 1780,
            nextThreshold: 1800,
            progressRatio: 0.96,
            headline: "다음 진화까지 20 XP 남았습니다."
        )
        let snapshot = CompanionProgressionSnapshot(
            level: 23,
            stageIndex: 3,
            progress: progress,
            evolutionMilestones: [],
            nextEvolutionMilestone: nil,
            stageUnlockWindow: [],
            lateGrowthWindow: [],
            lateGrowthFeatures: RunimalBalanceConfig.lateGrowthFeatures(forLevel: 23),
            evolutionSummary: nil
        )
        let pet = GeneratedPet(
            species: .windrunner,
            element: .light,
            palette: "aura",
            rareVariant: nil,
            explanation: [],
            stats: PetStats(vitality: 11, agility: 15, dexterity: 14, focus: 12, defense: 10)
        )

        let target = RunimalGameEngine.evolutionTarget(
            for: snapshot,
            pet: pet,
            recentRun: nil,
            season: defaultSeason
        )

        #expect(target.title == "진화 임계점 접근")
        #expect(target.focusTitle == "지금 상태")
        #expect(target.actionTitle == "바로 할 행동")
        #expect(target.checkpointTitle == "확인 기준")
        #expect(target.badges.contains("임계 96%"))
    }

    @Test
    func evolutionTargetProvidesConcreteTemplateForMatureStage() {
        let progress = EvolutionProgress(
            stageLabel: "성년기",
            totalExperience: 9050,
            nextThreshold: 9050,
            progressRatio: 1,
            headline: "최종 단계에 도달했습니다."
        )
        let snapshot = CompanionProgressionSnapshot(
            level: 36,
            stageIndex: 4,
            progress: progress,
            evolutionMilestones: [],
            nextEvolutionMilestone: nil,
            stageUnlockWindow: [],
            lateGrowthWindow: RunimalBalanceConfig.lateGrowthWindow(forLevel: 36),
            lateGrowthFeatures: RunimalBalanceConfig.lateGrowthFeatures(forLevel: 36),
            evolutionSummary: nil
        )
        let pet = GeneratedPet(
            species: .mosshop,
            element: .leaf,
            palette: "grove",
            rareVariant: nil,
            explanation: [],
            stats: PetStats(vitality: 14, agility: 10, dexterity: 10, focus: 13, defense: 12)
        )

        let target = RunimalGameEngine.evolutionTarget(
            for: snapshot,
            pet: pet,
            recentRun: nil,
            season: defaultSeason
        )

        #expect(target.title == "성년기 운영 시작")
        #expect(target.actionDetail.contains("저장 잠재"))
        #expect(target.checkpointDetail.contains("Lv.40"))
        #expect(target.badges.contains("성년기"))
    }

    @Test
    func postGrowthTargetProvidesFollowUpForStageAdvance() {
        let pet = GeneratedPet(
            species: .sparkfang,
            element: .flame,
            palette: "ember",
            rareVariant: nil,
            explanation: [],
            stats: PetStats(vitality: 14, agility: 14, dexterity: 15, focus: 11, defense: 10)
        )
        let beforeProgress = EvolutionProgress(
            stageLabel: "유년기",
            totalExperience: 1700,
            nextThreshold: 1800,
            progressRatio: 0.84,
            headline: "다음 진화까지 100 XP 남았습니다."
        )
        let afterProgress = EvolutionProgress(
            stageLabel: "청소년기",
            totalExperience: 1820,
            nextThreshold: 4576,
            progressRatio: 0.01,
            headline: "다음 진화까지 2756 XP 남았습니다."
        )
        let beforeSnapshot = CompanionProgressionSnapshot(
            level: 19,
            stageIndex: 2,
            progress: beforeProgress,
            evolutionMilestones: RunimalBalanceConfig.evolutionMilestones(for: .sparkfang),
            nextEvolutionMilestone: RunimalBalanceConfig.evolutionMilestones(for: .sparkfang).last,
            stageUnlockWindow: RunimalCompanionGrowthEngine.stageUnlockWindow(for: beforeProgress),
            lateGrowthWindow: RunimalBalanceConfig.lateGrowthWindow(forLevel: 19),
            lateGrowthFeatures: RunimalBalanceConfig.lateGrowthFeatures(forLevel: 19),
            evolutionSummary: nil
        )
        let afterSnapshot = CompanionProgressionSnapshot(
            level: 20,
            stageIndex: 3,
            progress: afterProgress,
            evolutionMilestones: RunimalBalanceConfig.evolutionMilestones(for: .sparkfang),
            nextEvolutionMilestone: RunimalBalanceConfig.evolutionMilestones(for: .sparkfang).last,
            stageUnlockWindow: RunimalCompanionGrowthEngine.stageUnlockWindow(for: afterProgress),
            lateGrowthWindow: RunimalBalanceConfig.lateGrowthWindow(forLevel: 20),
            lateGrowthFeatures: RunimalBalanceConfig.lateGrowthFeatures(forLevel: 20),
            evolutionSummary: nil
        )
        let outcome = CompanionFeedOutcome(
            runID: "run-stage-follow-up",
            coreLabel: "밀도 높은 기록",
            gainedExperience: 120,
            beforeSnapshot: beforeSnapshot,
            afterSnapshot: afterSnapshot,
            beforeProgress: beforeProgress,
            afterProgress: afterProgress,
            stageAdvanced: true
        )

        let target = RunimalGameEngine.postGrowthTarget(
            pet: pet,
            outcome: outcome,
            season: defaultSeason
        )

        #expect(target.title == "청소년기 운영 시작")
        #expect(target.focusDetail.contains("변이"))
        #expect(target.actionDetail.contains("성년기"))
        #expect(target.checkpointDetail.contains("Lv.25"))
        #expect(target.badges.contains("단계 상승"))
    }

    @Test
    func postGrowthTargetProvidesFollowUpForMatureAdvance() {
        let pet = GeneratedPet(
            species: .mosshop,
            element: .leaf,
            palette: "grove",
            rareVariant: nil,
            explanation: [],
            stats: PetStats(vitality: 14, agility: 10, dexterity: 10, focus: 13, defense: 12)
        )
        let beforeProgress = EvolutionProgress(
            stageLabel: "청소년기",
            totalExperience: 8950,
            nextThreshold: 9020,
            progressRatio: 0.96,
            headline: "다음 진화까지 70 XP 남았습니다."
        )
        let afterProgress = EvolutionProgress(
            stageLabel: "성년기",
            totalExperience: 9050,
            nextThreshold: 9050,
            progressRatio: 1,
            headline: "최종 단계에 도달했습니다."
        )
        let beforeSnapshot = CompanionProgressionSnapshot(
            level: 27,
            stageIndex: 3,
            progress: beforeProgress,
            evolutionMilestones: RunimalBalanceConfig.evolutionMilestones(for: .mosshop),
            nextEvolutionMilestone: RunimalBalanceConfig.evolutionMilestones(for: .mosshop).last,
            stageUnlockWindow: RunimalCompanionGrowthEngine.stageUnlockWindow(for: beforeProgress),
            lateGrowthWindow: RunimalBalanceConfig.lateGrowthWindow(forLevel: 27),
            lateGrowthFeatures: RunimalBalanceConfig.lateGrowthFeatures(forLevel: 27),
            evolutionSummary: nil
        )
        let afterSnapshot = CompanionProgressionSnapshot(
            level: 28,
            stageIndex: 4,
            progress: afterProgress,
            evolutionMilestones: RunimalBalanceConfig.evolutionMilestones(for: .mosshop),
            nextEvolutionMilestone: nil,
            stageUnlockWindow: RunimalCompanionGrowthEngine.stageUnlockWindow(for: afterProgress),
            lateGrowthWindow: RunimalBalanceConfig.lateGrowthWindow(forLevel: 28),
            lateGrowthFeatures: RunimalBalanceConfig.lateGrowthFeatures(forLevel: 28),
            evolutionSummary: nil
        )
        let outcome = CompanionFeedOutcome(
            runID: "run-mature-follow-up",
            coreLabel: "완성 직전 기록",
            gainedExperience: 100,
            beforeSnapshot: beforeSnapshot,
            afterSnapshot: afterSnapshot,
            beforeProgress: beforeProgress,
            afterProgress: afterProgress,
            stageAdvanced: true
        )

        let target = RunimalGameEngine.postGrowthTarget(
            pet: pet,
            outcome: outcome,
            season: defaultSeason
        )

        #expect(target.title == "성년기 운영 시작")
        #expect(target.actionDetail.contains("잠재"))
        #expect(target.checkpointDetail.contains("Lv.31"))
        #expect(target.badges.contains("성년기"))
    }

    @Test
    func shareMilestoneTargetGuidesLockedMythicProgress() {
        let progress = EvolutionProgress(
            stageLabel: "청소년기",
            totalExperience: 4576,
            nextThreshold: 9020,
            progressRatio: 0.42,
            headline: "다음 진화까지 4444 XP 남았습니다."
        )
        let snapshot = CompanionProgressionSnapshot(
            level: 20,
            stageIndex: 3,
            progress: progress,
            evolutionMilestones: RunimalBalanceConfig.evolutionMilestones(for: .windrunner),
            nextEvolutionMilestone: RunimalBalanceConfig.evolutionMilestones(for: .windrunner).last,
            stageUnlockWindow: RunimalCompanionGrowthEngine.stageUnlockWindow(for: progress),
            lateGrowthWindow: RunimalBalanceConfig.lateGrowthWindow(forLevel: 20),
            lateGrowthFeatures: RunimalBalanceConfig.lateGrowthFeatures(forLevel: 20),
            evolutionSummary: nil
        )
        let pet = GeneratedPet(
            species: .windrunner,
            element: .light,
            palette: "aura",
            rareVariant: nil,
            explanation: [],
            stats: PetStats(vitality: 11, agility: 15, dexterity: 14, focus: 12, defense: 10)
        )

        let target = RunimalGameEngine.shareMilestoneTarget(
            kind: .mythic,
            unlocked: false,
            snapshot: snapshot,
            pet: pet,
            season: defaultSeason,
            collectionCount: 3
        )

        #expect(target.title == "성년기 카드 준비")
        #expect(target.focusDetail.contains("청소년기"))
        #expect(target.actionDetail.contains("Lv.27"))
        #expect(target.checkpointDetail.contains("성년기"))
    }

    @Test
    func shareMilestoneTargetGuidesUnlockedRareVariant() {
        let progress = EvolutionProgress(
            stageLabel: "유년기",
            totalExperience: 900,
            nextThreshold: 1800,
            progressRatio: 0.35,
            headline: "다음 진화까지 900 XP 남았습니다."
        )
        let snapshot = CompanionProgressionSnapshot(
            level: 12,
            stageIndex: 2,
            progress: progress,
            evolutionMilestones: RunimalBalanceConfig.evolutionMilestones(for: .sparkfang),
            nextEvolutionMilestone: RunimalBalanceConfig.evolutionMilestones(for: .sparkfang)[3],
            stageUnlockWindow: RunimalCompanionGrowthEngine.stageUnlockWindow(for: progress),
            lateGrowthWindow: RunimalBalanceConfig.lateGrowthWindow(forLevel: 12),
            lateGrowthFeatures: RunimalBalanceConfig.lateGrowthFeatures(forLevel: 12),
            evolutionSummary: nil
        )
        let pet = GeneratedPet(
            species: .sparkfang,
            element: .flame,
            palette: "ember",
            rareVariant: .tempoSurge,
            explanation: [],
            stats: PetStats(vitality: 14, agility: 14, dexterity: 15, focus: 11, defense: 10)
        )

        let target = RunimalGameEngine.shareMilestoneTarget(
            kind: .rareVariant,
            unlocked: true,
            snapshot: snapshot,
            pet: pet,
            season: defaultSeason,
            collectionCount: 5
        )

        #expect(target.title == "희귀 경로 확보")
        #expect(target.actionDetail.contains("페이스"))
        #expect(target.checkpointDetail.contains("희귀"))
        #expect(target.badges.contains(defaultSeason.title))
    }

    @Test
    func shareMilestoneProgressUsesLeadingEggProgressForFirstHatch() {
        let progress = EvolutionProgress(
            stageLabel: "유아기",
            totalExperience: 120,
            nextThreshold: 513,
            progressRatio: 0.24,
            headline: "다음 진화까지 393 XP 남았습니다."
        )
        let snapshot = CompanionProgressionSnapshot(
            level: 4,
            stageIndex: 1,
            progress: progress,
            evolutionMilestones: RunimalBalanceConfig.evolutionMilestones(for: .seedle),
            nextEvolutionMilestone: RunimalBalanceConfig.evolutionMilestones(for: .seedle).first,
            stageUnlockWindow: RunimalCompanionGrowthEngine.stageUnlockWindow(for: progress),
            lateGrowthWindow: RunimalBalanceConfig.lateGrowthWindow(forLevel: 4),
            lateGrowthFeatures: RunimalBalanceConfig.lateGrowthFeatures(forLevel: 4),
            evolutionSummary: nil
        )
        let pet = GeneratedPet(
            species: .seedle,
            element: .leaf,
            palette: "leaf",
            rareVariant: nil,
            explanation: [],
            stats: PetStats(vitality: 12, agility: 11, dexterity: 13, focus: 10, defense: 9)
        )
        let eggs = [
            EggInventoryEntry(
                id: "egg-a",
                shell: .gale,
                title: "바람 알",
                createdAt: .distantPast,
                sourceRunID: "run-a",
                storedExperience: 60,
                hatchThreshold: 120,
                incubationRunIDs: [],
                unlockedAchievementIDs: []
            ),
            EggInventoryEntry(
                id: "egg-b",
                shell: .moss,
                title: "숲 알",
                createdAt: .distantPast,
                sourceRunID: "run-b",
                storedExperience: 96,
                hatchThreshold: 120,
                incubationRunIDs: [],
                unlockedAchievementIDs: []
            )
        ]

        let milestoneProgress = RunimalGameEngine.shareMilestoneProgress(
            kind: .firstHatch,
            unlocked: false,
            snapshot: snapshot,
            pet: pet,
            season: defaultSeason,
            collectionCount: 0,
            eggInventory: eggs
        )

        #expect(milestoneProgress.progress == 0.8)
        #expect(milestoneProgress.label == "알 준비 80%")
        #expect(milestoneProgress.detail.contains("숲 알"))
    }

    @Test
    func shareMilestoneProgressUsesRareReadinessAfterFirstHatchUnlock() {
        let progress = EvolutionProgress(
            stageLabel: "유년기",
            totalExperience: 900,
            nextThreshold: 1800,
            progressRatio: 0.35,
            headline: "다음 진화까지 900 XP 남았습니다."
        )
        let snapshot = CompanionProgressionSnapshot(
            level: 12,
            stageIndex: 2,
            progress: progress,
            evolutionMilestones: RunimalBalanceConfig.evolutionMilestones(for: .seedle),
            nextEvolutionMilestone: RunimalBalanceConfig.evolutionMilestones(for: .seedle)[2],
            stageUnlockWindow: RunimalCompanionGrowthEngine.stageUnlockWindow(for: progress),
            lateGrowthWindow: RunimalBalanceConfig.lateGrowthWindow(forLevel: 12),
            lateGrowthFeatures: RunimalBalanceConfig.lateGrowthFeatures(forLevel: 12),
            evolutionSummary: nil
        )
        let pet = GeneratedPet(
            species: .seedle,
            element: .leaf,
            palette: "leaf",
            rareVariant: nil,
            explanation: [],
            stats: PetStats(vitality: 12, agility: 11, dexterity: 13, focus: 10, defense: 9)
        )

        let milestoneProgress = RunimalGameEngine.shareMilestoneProgress(
            kind: .firstHatch,
            unlocked: true,
            snapshot: snapshot,
            pet: pet,
            season: defaultSeason,
            collectionCount: 3,
            eggInventory: []
        )

        #expect(milestoneProgress.label.contains("다음 희귀 준비도"))
        #expect(milestoneProgress.detail.contains("현재 유년기"))
        #expect(milestoneProgress.progress > 0.5)
    }

    @Test
    func shareMilestoneProgressUsesFinalEvolutionThresholdForMythic() {
        let milestones = RunimalBalanceConfig.evolutionMilestones(for: .windrunner)
        let progress = EvolutionProgress(
            stageLabel: "청소년기",
            totalExperience: 4576,
            nextThreshold: 9020,
            progressRatio: 0.42,
            headline: "다음 진화까지 4444 XP 남았습니다."
        )
        let snapshot = CompanionProgressionSnapshot(
            level: 20,
            stageIndex: 3,
            progress: progress,
            evolutionMilestones: milestones,
            nextEvolutionMilestone: milestones.last,
            stageUnlockWindow: RunimalCompanionGrowthEngine.stageUnlockWindow(for: progress),
            lateGrowthWindow: RunimalBalanceConfig.lateGrowthWindow(forLevel: 20),
            lateGrowthFeatures: RunimalBalanceConfig.lateGrowthFeatures(forLevel: 20),
            evolutionSummary: nil
        )
        let pet = GeneratedPet(
            species: .windrunner,
            element: .light,
            palette: "aura",
            rareVariant: nil,
            explanation: [],
            stats: PetStats(vitality: 11, agility: 15, dexterity: 14, focus: 12, defense: 10)
        )

        let milestoneProgress = RunimalGameEngine.shareMilestoneProgress(
            kind: .mythic,
            unlocked: false,
            snapshot: snapshot,
            pet: pet,
            season: defaultSeason,
            collectionCount: 3,
            eggInventory: []
        )

        #expect(milestoneProgress.progress == 4576.0 / 9020.0)
        #expect(milestoneProgress.label == "성년기까지 4444 XP")
        #expect(milestoneProgress.detail.contains("목표 Lv.27"))
    }

    @Test
    func shareMilestoneProgressUsesLateGrowthTargetAfterMythicUnlock() {
        let progress = EvolutionProgress(
            stageLabel: "성년기",
            totalExperience: 8000,
            nextThreshold: 8000,
            progressRatio: 1,
            headline: "최종 단계에 도달했습니다."
        )
        let snapshot = CompanionProgressionSnapshot(
            level: 36,
            stageIndex: 4,
            progress: progress,
            evolutionMilestones: RunimalBalanceConfig.evolutionMilestones(for: .mosshop),
            nextEvolutionMilestone: nil,
            stageUnlockWindow: RunimalCompanionGrowthEngine.stageUnlockWindow(for: progress),
            lateGrowthWindow: RunimalBalanceConfig.lateGrowthWindow(forLevel: 36),
            lateGrowthFeatures: RunimalBalanceConfig.lateGrowthFeatures(forLevel: 36),
            evolutionSummary: nil
        )
        let pet = GeneratedPet(
            species: .mosshop,
            element: .leaf,
            palette: "grove",
            rareVariant: nil,
            explanation: [],
            stats: PetStats(vitality: 14, agility: 10, dexterity: 10, focus: 13, defense: 12)
        )

        let milestoneProgress = RunimalGameEngine.shareMilestoneProgress(
            kind: .mythic,
            unlocked: true,
            snapshot: snapshot,
            pet: pet,
            season: defaultSeason,
            collectionCount: 4,
            eggInventory: []
        )

        #expect(milestoneProgress.label.contains("다음 후반 해금까지"))
        #expect(milestoneProgress.detail.contains("목표 Lv.40"))
        #expect(milestoneProgress.progress > 0)
        #expect(milestoneProgress.progress < 1)
    }
}
