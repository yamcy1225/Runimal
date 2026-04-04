import Foundation
import Testing
@testable import RunimalCore

struct CompanionProgressionBalanceTests {
    @Test
    func levelThresholdsGrowMonotonically() {
        var previous = 0

        for level in 1..<RunimalBalanceConfig.companionLevelCap {
            let requirement = RunimalBalanceConfig.companionExperienceRequirement(forNextLevel: level)
            #expect(requirement > previous)
            previous = requirement
        }
    }

    @Test
    func cumulativeThresholdsResolveExpectedLevels() {
        #expect(RunimalBalanceConfig.companionLevel(forExperience: 0) == 1)
        #expect(RunimalBalanceConfig.companionLevel(forExperience: RunimalBalanceConfig.companionExperienceTotal(forLevel: 2)) == 2)
        #expect(RunimalBalanceConfig.companionLevel(forExperience: RunimalBalanceConfig.companionExperienceTotal(forLevel: 10)) == 10)
        #expect(RunimalBalanceConfig.companionLevel(forExperience: RunimalBalanceConfig.companionExperienceTotal(forLevel: 50)) == 50)
        #expect(RunimalBalanceConfig.companionLevel(forExperience: 999_999) == 50)
    }

    @Test
    func interactionBonusUsesCapAndUniqueEvents() {
        let bonus = RunimalCompanionProgressionEngine.interactionBonus(
            baseExperience: 100,
            events: [
                .matchingSpecies,
                .matchingSpecies,
                .episodeUnlock,
                .seasonUnlock,
                .regionUnlock
            ],
            stageIndex: 1
        )

        #expect(bonus.bonusExperience == 40)
        #expect(bonus.capped)
        #expect(bonus.labels.contains("잘 맞는 종류"))
        #expect(bonus.labels.contains("에피소드 개방"))
    }

    @Test
    func companionStageUnlocksStayAlignedWithStageLabels() {
        #expect(RunimalBalanceConfig.companionStageUnlocks.count == RunimalBalanceConfig.evolutionStageLabels.count)
        #expect(RunimalBalanceConfig.companionStageUnlock(at: 1)?.stageLabel == "유아기")
        #expect(RunimalBalanceConfig.companionStageUnlock(at: 4)?.stageLabel == "성년기")
        #expect(RunimalBalanceConfig.companionLateGrowthMilestones.first?.requiredLevel == 31)
        #expect(RunimalBalanceConfig.companionLateGrowthMilestones.last?.requiredLevel == 50)
    }

    @Test
    func speciesEvolutionProfilesStayMonotonic() {
        for species in PetSpecies.allCases {
            let milestones = RunimalBalanceConfig.evolutionLevelMilestones(for: species)
            #expect(milestones.count == RunimalBalanceConfig.evolutionStageLabels.count)
            #expect(milestones.first == 1)
            #expect(milestones == milestones.sorted())
            #expect((milestones.last ?? 0) >= 24)
        }
    }

    @Test
    func stageUnlockWindowShowsCurrentAndNextStage() {
        let progress = EvolutionProgress(
            stageLabel: "유년기",
            totalExperience: 360,
            nextThreshold: 580,
            progressRatio: 0.1,
            headline: "다음 단계까지 남았습니다."
        )

        let window = RunimalCompanionGrowthEngine.stageUnlockWindow(for: progress)

        #expect(window.map(\.stageLabel) == ["유년기", "청소년기"])
    }

    @Test
    func progressionSnapshotCentralizesMilestonesAndLateGrowthState() {
        let totalExperience = RunimalBalanceConfig.companionExperienceTotal(forLevel: 36)
        let growthRecord = CompanionGrowthRecord(
            companionID: "snapshot",
            totalExperience: totalExperience,
            storedPotentialExperience: 18,
            feedCount: 12,
            assignedRunIDs: [],
            lastFedAt: nil
        )

        let snapshot = RunimalCompanionGrowthEngine.progressionSnapshot(for: growthRecord, species: .windrunner)

        #expect(snapshot.level == 36)
        #expect(snapshot.progress.stageLabel == "성년기")
        #expect(snapshot.stageUnlockWindow.map(\.stageLabel) == ["성년기"])
        #expect(snapshot.nextEvolutionMilestone == nil)
        #expect(snapshot.lateGrowthWindow.map(\.requiredLevel) == [35, 40])
        #expect(snapshot.lateGrowthFeatures.storedPotentialCap == 80)
        #expect(snapshot.evolutionMilestones.last?.requiredLevel == 27)
        #expect(snapshot.evolutionSummary?.isEmpty == false)
    }

    @Test
    func speciesSpecificEvolutionThresholdsDifferentiateGrowthTiming() {
        let sharedExperience = RunimalBalanceConfig.companionExperienceTotal(forLevel: 11)
        let record = CompanionGrowthRecord(
            companionID: "companion",
            totalExperience: sharedExperience,
            feedCount: 1,
            assignedRunIDs: [],
            lastFedAt: nil
        )

        let seedleProgress = RunimalCompanionGrowthEngine.evolutionProgress(for: record, species: .seedle)
        let stonebackProgress = RunimalCompanionGrowthEngine.evolutionProgress(for: record, species: .stoneback)

        #expect(seedleProgress.stageLabel == "유년기")
        #expect(stonebackProgress.stageLabel == "유아기")
    }

    @Test
    func ownedCompanionNeverDisplaysEggStage() {
        let record = CompanionGrowthRecord(
            companionID: "hatched",
            totalExperience: 12,
            feedCount: 0,
            assignedRunIDs: [],
            lastFedAt: nil
        )

        let progress = RunimalCompanionGrowthEngine.evolutionProgress(for: record, species: .windrunner)

        #expect(progress.stageLabel == "유아기")
    }

    @Test
    func stageInteractionPolicyUnlocksAdvancedEventsGradually() {
        let earlyPolicy = RunimalCompanionProgressionEngine.interactionPolicy(for: 1)
        let youthPolicy = RunimalCompanionProgressionEngine.interactionPolicy(for: 2)
        let teenPolicy = RunimalCompanionProgressionEngine.interactionPolicy(for: 3)

        #expect(earlyPolicy.unlockedEvents.contains(.seasonAffinity) == false)
        #expect(youthPolicy.unlockedEvents.contains(.seasonAffinity))
        #expect(teenPolicy.unlockedEvents.contains(.matchingVariant))
        #expect(teenPolicy.capBonus == 4)
    }

    @Test
    func matureStageAddsSeasonAffinityBoost() {
        let bonus = RunimalCompanionProgressionEngine.interactionBonus(
            baseExperience: 100,
            events: [.seasonAffinity, .matchingSpecies],
            stageIndex: 4
        )

        #expect(bonus.bonusExperience == 28)
        #expect(bonus.labels.contains("완성 호흡"))
    }

    @Test
    func lateGrowthWindowShowsCurrentAndNextMilestone() {
        let window = RunimalBalanceConfig.lateGrowthWindow(forLevel: 36)

        #expect(window.map(\.requiredLevel) == [35, 40])
    }

    @Test
    func lateGrowthFeaturesUnlockActualCaps() {
        let early = RunimalBalanceConfig.lateGrowthFeatures(forLevel: 24)
        let mid = RunimalBalanceConfig.lateGrowthFeatures(forLevel: 35)
        let final = RunimalBalanceConfig.lateGrowthFeatures(forLevel: 50)

        #expect(early.insightLabelLimit == 2)
        #expect(early.storedPotentialCap == 60)
        #expect(mid.insightLabelLimit == 4)
        #expect(mid.storedPotentialCap == 80)
        #expect(mid.potentialSpendCapBonus == 4)
        #expect(final.insightLabelLimit == 5)
        #expect(final.storedPotentialCap == 90)
        #expect(final.potentialSpendCapBonus == 6)
        #expect(final.completedRecordMark)
    }

    @Test
    func lateGrowthPotentialCapsRaiseStoredAndSpendLimits() {
        #expect(RunimalRunCoreGrowthBalanceEngine.storedPotentialCap(forLevel: 1) == 60)
        #expect(RunimalRunCoreGrowthBalanceEngine.storedPotentialCap(forLevel: 35) == 80)
        #expect(RunimalRunCoreGrowthBalanceEngine.storedPotentialCap(forLevel: 50) == 90)
        #expect(RunimalRunCoreGrowthBalanceEngine.potentialSpendCap(baseExperience: 120, level: 1) == 20)
        #expect(RunimalRunCoreGrowthBalanceEngine.potentialSpendCap(baseExperience: 120, level: 35) == 24)
        #expect(RunimalRunCoreGrowthBalanceEngine.potentialSpendCap(baseExperience: 120, level: 50) == 26)
    }

    @Test
    func lateGrowthBonusRequiresUnlockedBands() {
        let lowBonus = RunimalCompanionProgressionEngine.lateGrowthBonus(
            level: 30,
            dataProfile: RunCoreDataProfile(informationScore: 8, bonusExperience: 12, labels: []),
            potentialSpend: 12,
            seasonAligned: true,
            worldImpact: WorldRunImpact(
                regionID: "region",
                regionTitle: "구역",
                seasonID: "season",
                seasonTitle: "시즌",
                episodeID: "episode",
                episodeTitle: "에피소드",
                unlockedRegion: true,
                unlockedSeason: false,
                unlockedEpisode: false,
                distanceKmDelta: 4,
                elevationGainDelta: 12,
                nightRunDelta: 0,
                cadencePeakDelta: 170
            )
        )
        let highBonus = RunimalCompanionProgressionEngine.lateGrowthBonus(
            level: 45,
            dataProfile: RunCoreDataProfile(informationScore: 8, bonusExperience: 12, labels: []),
            potentialSpend: 12,
            seasonAligned: true,
            worldImpact: WorldRunImpact(
                regionID: "region",
                regionTitle: "구역",
                seasonID: "season",
                seasonTitle: "시즌",
                episodeID: "episode",
                episodeTitle: "에피소드",
                unlockedRegion: true,
                unlockedSeason: true,
                unlockedEpisode: true,
                distanceKmDelta: 4,
                elevationGainDelta: 12,
                nightRunDelta: 0,
                cadencePeakDelta: 170
            )
        )

        #expect(lowBonus.bonusExperience == 0)
        #expect(highBonus.bonusExperience == 18)
        #expect(highBonus.labels.contains("기록 해석"))
        #expect(highBonus.labels.contains("잠재 응축"))
        #expect(highBonus.labels.contains("시즌 숙련"))
    }

    @Test
    func lateGrowthRetentionLabelsPreserveMoreSignalsAtHighLevel() {
        let startedAt = runtimeDate(hour: 21)
        let run = CompletedRunRecord(
            id: "retained",
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(2_200),
            distanceMeters: 6_200,
            durationSeconds: 2_200,
            averageHeartRate: 155,
            averagePaceSeconds: 325,
            cadence: 174,
            elevationGainM: 44,
            reward: sampleReward(),
            route: [
                RoutePoint(latitude: 37.0, longitude: 127.0, altitude: 0, timestamp: startedAt),
                RoutePoint(latitude: 37.001, longitude: 127.001, altitude: 12, timestamp: startedAt.addingTimeInterval(60)),
                RoutePoint(latitude: 37.002, longitude: 127.002, altitude: 20, timestamp: startedAt.addingTimeInterval(120)),
                RoutePoint(latitude: 37.003, longitude: 127.003, altitude: 26, timestamp: startedAt.addingTimeInterval(180)),
                RoutePoint(latitude: 37.004, longitude: 127.004, altitude: 32, timestamp: startedAt.addingTimeInterval(240)),
                RoutePoint(latitude: 37.005, longitude: 127.005, altitude: 38, timestamp: startedAt.addingTimeInterval(300)),
                RoutePoint(latitude: 37.006, longitude: 127.006, altitude: 43, timestamp: startedAt.addingTimeInterval(360)),
                RoutePoint(latitude: 37.007, longitude: 127.007, altitude: 44, timestamp: startedAt.addingTimeInterval(420)),
            ],
            source: "test",
            environmentCondition: .rain,
            rareEventCompleted: true,
            mutationContribution: MutationRunContributionSnapshot(
                speciesID: "windrunner",
                axes: [
                    MutationAxisContributionSnapshot(axis: .body, branchID: "a", branchTitle: "A", score: 6, progress: 0.6),
                    MutationAxisContributionSnapshot(axis: .ecology, branchID: "b", branchTitle: "B", score: 6, progress: 0.6),
                ]
            ),
            worldImpact: WorldRunImpact(
                regionID: "moonlight-alley",
                regionTitle: "달빛 골목",
                seasonID: "hollow-dusk",
                seasonTitle: "황혼권",
                episodeID: "episode-moonmark",
                episodeTitle: "문양 각성",
                unlockedRegion: true,
                unlockedSeason: true,
                unlockedEpisode: true,
                distanceKmDelta: 6.2,
                elevationGainDelta: 44,
                nightRunDelta: 1,
                cadencePeakDelta: 174
            )
        )
        let dataProfile = RunimalRunCoreGrowthBalanceEngine.dataProfile(for: run)

        let level31 = RunimalCompanionProgressionEngine.lateGrowthRetentionLabels(
            level: 31,
            run: run,
            dataProfile: dataProfile,
            seasonTitle: "황혼권",
            seasonAligned: true
        )
        let level45 = RunimalCompanionProgressionEngine.lateGrowthRetentionLabels(
            level: 45,
            run: run,
            dataProfile: dataProfile,
            seasonTitle: "황혼권",
            seasonAligned: true
        )
        let level50 = RunimalCompanionProgressionEngine.lateGrowthRetentionLabels(
            level: 50,
            run: run,
            dataProfile: dataProfile,
            seasonTitle: "황혼권",
            seasonAligned: true
        )

        #expect(level31.count >= 4)
        #expect(level45.contains("황혼권 기록 보관"))
        #expect(level45.contains("달빛 골목 정착"))
        #expect(level45.contains("문양 각성 기록"))
        #expect(level50.contains("완성 기록 보관"))
    }

    @Test
    func richerRunDataProducesFeedBonus() {
        let sparseRun = CompletedRunRecord(
            id: "sparse",
            startedAt: .now,
            endedAt: .now,
            distanceMeters: 4_000,
            durationSeconds: 1_400,
            averageHeartRate: nil,
            averagePaceSeconds: nil,
            cadence: nil,
            elevationGainM: 0,
            reward: sampleReward(),
            route: [],
            source: "test"
        )
        let richRun = CompletedRunRecord(
            id: "rich",
            startedAt: .now,
            endedAt: .now,
            distanceMeters: 8_000,
            durationSeconds: 2_800,
            averageHeartRate: 152,
            averagePaceSeconds: 330,
            cadence: 172,
            elevationGainM: 80,
            reward: sampleReward(),
            route: [
                RoutePoint(latitude: 37.0, longitude: 127.0, altitude: 0, timestamp: .now),
                RoutePoint(latitude: 37.001, longitude: 127.001, altitude: 10, timestamp: .now.addingTimeInterval(60)),
                RoutePoint(latitude: 37.002, longitude: 127.002, altitude: 20, timestamp: .now.addingTimeInterval(120)),
                RoutePoint(latitude: 37.003, longitude: 127.003, altitude: 25, timestamp: .now.addingTimeInterval(180)),
                RoutePoint(latitude: 37.004, longitude: 127.004, altitude: 30, timestamp: .now.addingTimeInterval(240)),
                RoutePoint(latitude: 37.005, longitude: 127.005, altitude: 35, timestamp: .now.addingTimeInterval(300)),
                RoutePoint(latitude: 37.006, longitude: 127.006, altitude: 40, timestamp: .now.addingTimeInterval(360)),
                RoutePoint(latitude: 37.007, longitude: 127.007, altitude: 45, timestamp: .now.addingTimeInterval(420)),
            ],
            source: "test",
            environmentCondition: .rain,
            rareEventCompleted: true,
            mutationContribution: MutationRunContributionSnapshot(
                speciesID: "windrunner",
                axes: [
                    MutationAxisContributionSnapshot(axis: .body, branchID: "a", branchTitle: "A", score: 5, progress: 0.5),
                    MutationAxisContributionSnapshot(axis: .rhythm, branchID: "b", branchTitle: "B", score: 5, progress: 0.5),
                ]
            )
        )

        let sparseProfile = RunimalRunCoreGrowthBalanceEngine.dataProfile(for: sparseRun)
        let richProfile = RunimalRunCoreGrowthBalanceEngine.dataProfile(for: richRun)

        #expect(sparseProfile.bonusExperience == 0)
        #expect(richProfile.bonusExperience >= 16)
    }

    @Test
    func liveRuntimeSignalsProduceStoredPotential() {
        let startedAt = runtimeDate(hour: 21)
        let run = CompletedRunRecord(
            id: "live",
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(2_200),
            distanceMeters: 6_200,
            durationSeconds: 2_200,
            averageHeartRate: 155,
            averagePaceSeconds: 325,
            cadence: 174,
            elevationGainM: 44,
            reward: sampleReward(),
            route: [
                RoutePoint(latitude: 37.0, longitude: 127.0, altitude: 0, timestamp: startedAt),
                RoutePoint(latitude: 37.001, longitude: 127.001, altitude: 12, timestamp: startedAt.addingTimeInterval(60)),
                RoutePoint(latitude: 37.002, longitude: 127.002, altitude: 20, timestamp: startedAt.addingTimeInterval(120)),
                RoutePoint(latitude: 37.003, longitude: 127.003, altitude: 26, timestamp: startedAt.addingTimeInterval(180)),
                RoutePoint(latitude: 37.004, longitude: 127.004, altitude: 32, timestamp: startedAt.addingTimeInterval(240)),
                RoutePoint(latitude: 37.005, longitude: 127.005, altitude: 38, timestamp: startedAt.addingTimeInterval(300)),
                RoutePoint(latitude: 37.006, longitude: 127.006, altitude: 43, timestamp: startedAt.addingTimeInterval(360)),
                RoutePoint(latitude: 37.007, longitude: 127.007, altitude: 44, timestamp: startedAt.addingTimeInterval(420)),
            ],
            source: "test",
            environmentCondition: .rain,
            rareEventCompleted: true,
            mutationContribution: MutationRunContributionSnapshot(
                speciesID: "windrunner",
                axes: [MutationAxisContributionSnapshot(axis: .ecology, branchID: "a", branchTitle: "A", score: 6, progress: 0.6)]
            ),
            worldImpact: WorldRunImpact(
                regionID: "moonlight-alley",
                regionTitle: "달빛 골목",
                seasonID: "hollow-dusk",
                seasonTitle: "황혼권",
                episodeID: "episode-moonmark",
                episodeTitle: "문양 각성",
                unlockedRegion: false,
                unlockedSeason: false,
                unlockedEpisode: true,
                distanceKmDelta: 6.2,
                elevationGainDelta: 44,
                nightRunDelta: 1,
                cadencePeakDelta: 174
            )
        )

        let profile = RunimalRunCoreGrowthBalanceEngine.livePotential(for: run)

        #expect(profile.storedPotentialExperience == 18)
        #expect(profile.eventScore >= 10)
        #expect(profile.labels.contains("페이스 유지"))
        #expect(profile.labels.contains("고케이던스"))
        #expect(profile.labels.contains("경로 안정"))
        #expect(profile.labels.contains("오르막 반응"))
        #expect(profile.labels.contains("비길 적응"))
        #expect(profile.labels.contains("야간 감응"))
        #expect(profile.labels.contains("현장 이벤트"))
        #expect(profile.labels.contains("에피소드 감지"))
    }

    @Test
    func calmShortRunDoesNotStorePotential() {
        let startedAt = runtimeDate(hour: 10)
        let run = CompletedRunRecord(
            id: "calm",
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(1_000),
            distanceMeters: 2_400,
            durationSeconds: 1_000,
            averageHeartRate: 128,
            averagePaceSeconds: 430,
            cadence: 160,
            elevationGainM: 8,
            reward: sampleReward(),
            route: [
                RoutePoint(latitude: 37.0, longitude: 127.0, altitude: 0, timestamp: startedAt),
                RoutePoint(latitude: 37.001, longitude: 127.001, altitude: 5, timestamp: startedAt.addingTimeInterval(120)),
            ],
            source: "test",
            environmentCondition: .clear
        )

        let profile = RunimalRunCoreGrowthBalanceEngine.livePotential(for: run)

        #expect(profile.eventScore == 0)
        #expect(profile.storedPotentialExperience == 0)
        #expect(profile.labels.isEmpty)
    }

    @Test
    func liveInteractionPreviewSurfacesConcreteRealtimeCues() {
        let preview = RunimalRunCoreGrowthBalanceEngine.liveInteractionPreview(
            snapshot: LiveRunSnapshot(
                elapsedSeconds: 2_100,
                distanceMeters: 6_500,
                currentHeartRate: 156,
                cadence: 174,
                elevationGainM: 38,
                averagePaceSeconds: 328
            ),
            routePointCount: 12,
            gpsAccuracyMeters: 8,
            isGPSFresh: true,
            environmentCondition: .rain,
            rareEventCompleted: true,
            isNightWindow: true,
            mutationReaction: MutationRuntimeReactionSnapshot(
                id: "body-rise",
                axis: .body,
                stage: 2,
                title: "몸 반응",
                detail: "상체 리듬이 안정적으로 붙었습니다."
            ),
            objective: LiveCompanionObjectiveSnapshot(
                title: "돌발 목표",
                detail: "170spm 유지 중",
                progress: 0.75
            )
        )

        #expect(preview.projectedPotentialExperience == 18)
        #expect(preview.projectedEventScore >= 10)
        #expect(preview.cues.contains(where: { $0.category == .objective && $0.title == "돌발 목표" }))
        #expect(preview.cues.contains(where: { $0.category == .reaction && $0.title == "몸 반응" }))
        #expect(preview.cues.contains(where: { $0.title == "고케이던스" && $0.isActive }))
        #expect(preview.cues.contains(where: { $0.title == "현장 이벤트" && $0.isActive }))
    }

    @Test
    func liveInteractionPreviewStaysQuietWhenRunIsNotReady() {
        let preview = RunimalRunCoreGrowthBalanceEngine.liveInteractionPreview(
            snapshot: LiveRunSnapshot(
                elapsedSeconds: 240,
                distanceMeters: 900,
                currentHeartRate: 122,
                cadence: 150,
                elevationGainM: 4,
                averagePaceSeconds: 430
            ),
            routePointCount: 2,
            gpsAccuracyMeters: 42,
            isGPSFresh: false,
            environmentCondition: .unknown,
            rareEventCompleted: false,
            isNightWindow: false
        )

        #expect(preview.projectedPotentialExperience == 0)
        #expect(preview.projectedEventScore == 0)
        #expect(preview.headline == "반응 모으는 중")
        #expect(preview.cues.contains(where: { $0.title == "고케이던스" && $0.isActive == false }))
        #expect(preview.cues.contains(where: { $0.title == "경로 안정" && $0.statusLabel != "활성" }))
    }

    private func sampleReward() -> RunRewardSummary {
        RunRewardSummary(
            pet: GeneratedPet(
                species: .windrunner,
                element: .light,
                palette: "default",
                rareVariant: nil,
                explanation: [],
                stats: PetStats(vitality: 8, agility: 8, dexterity: 8, focus: 8, defense: 8)
            ),
            coreLabel: "기록",
            experience: 120,
            completedQuestCount: 2,
            flavorText: "sample"
        )
    }

    private func runtimeDate(hour: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current

        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = .current
        components.year = 2026
        components.month = 4
        components.day = 2
        components.hour = hour
        components.minute = 0

        return calendar.date(from: components) ?? .now
    }
}
