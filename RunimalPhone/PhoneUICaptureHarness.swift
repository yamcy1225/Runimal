import Foundation
import RunimalCore
import SwiftUI

enum PhoneUICaptureScenario: String, CaseIterable {
    case homeDashboard = "home-dashboard"
    case workoutRecord = "workout-record"
    case eggCreation = "egg-creation"
    case hatch = "hatch"
    case firstStageUp = "first-stage-up"
    case rareMutation = "rare-mutation"
    case showcaseShare = "showcase-share"
    case inventory = "inventory"

    static var current: PhoneUICaptureScenario? {
        ProcessInfo.processInfo.environment["RUNIMAL_UI_CAPTURE_SCENARIO"].flatMap(Self.init(rawValue:))
    }

    var title: String {
        switch self {
        case .homeDashboard: return "Home Dashboard"
        case .workoutRecord: return "Workout Record"
        case .eggCreation: return "Egg Creation"
        case .hatch: return "Hatch"
        case .firstStageUp: return "First Stage-Up"
        case .rareMutation: return "Rare Mutation"
        case .showcaseShare: return "Showcase Share"
        case .inventory: return "Inventory"
        }
    }
}

struct PhoneUICaptureHarnessRoot: View {
    let scenario: PhoneUICaptureScenario
    @State private var store: PhoneDashboardStore

    init(scenario: PhoneUICaptureScenario) {
        self.scenario = scenario
        _store = State(initialValue: PhoneDashboardStore(captureScenario: scenario))
    }

    var body: some View {
        NavigationStack {
            PhoneUICaptureHarnessView(store: store, scenario: scenario)
                .navigationTitle(scenario.title)
                .navigationBarTitleDisplayMode(.inline)
        }
        .background(
            ZStack {
                LinearGradient(
                    colors: [GameBoyPalette.mediumLight, GameBoyPalette.lightest, GameBoyPalette.mediumLight.opacity(0.88)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                GameBoyLCDOverlay()
                    .opacity(0.7)
            }
            .ignoresSafeArea()
        )
    }
}

private struct PhoneUICaptureHarnessView: View {
    let store: PhoneDashboardStore
    let scenario: PhoneUICaptureScenario

    var body: some View {
        switch scenario {
        case .homeDashboard:
            PhoneHomeView(store: store)

        case .workoutRecord:
            if let runID = store.completedRuns.first?.id {
                PhoneRunRecordDetailSheet(store: store, runID: runID)
            } else {
                Text("No workout record fixture")
            }

        case .inventory:
            PhoneInventoryView(store: store)

        case .eggCreation:
            captureScroll {
                let egg = PhoneUICaptureFixtures.forgeEgg
                GameSurface(title: "첫 러닝이 알이 됩니다", accent: egg.shell.accentColor, eyebrow: "FTUE") {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .center, spacing: 18) {
                            PhoneEggForgeEffectView(egg: egg)
                            VStack(alignment: .leading, spacing: 10) {
                                Text("첫 성공 러닝은 바로 숨겨진 ??? 알로 고정됩니다.")
                                    .font(.headline.monospaced().weight(.black))
                                    .foregroundStyle(.white)
                                Text("실시간 동행과 운동 기록은 분리됩니다. 러닝이 끝나면 기록은 알 생성이나 성장 재료로 남고, 지금 이 화면은 그 첫 생성 순간을 바로 보여 줍니다.")
                                    .font(.footnote)
                                    .foregroundStyle(.white.opacity(0.76))
                                HStack(spacing: 8) {
                                    TraitChip(label: egg.shell.displayLabel, accent: egg.shell.accentColor)
                                    TraitChip(label: "첫 러닝 고정 보상", accent: .mint.opacity(0.28))
                                }
                            }
                        }
                    }
                }
            }

        case .hatch:
            let egg = PhoneUICaptureFixtures.hatchReadyEgg
            let companion = PhoneUICaptureFixtures.hatchCompanion
            let renderState = PhoneUICaptureFixtures.renderState(for: companion)
            HatchCinematicView(
                egg: egg,
                pet: companion,
                sourceRun: PhoneUICaptureFixtures.hatchSourceRun,
                renderState: renderState,
                onDismiss: {}
            )

        case .firstStageUp:
            captureScroll {
                PhoneFeedCinematicPanel(
                    pet: PhoneUICaptureFixtures.starterCompanion.pet,
                    outcome: PhoneUICaptureFixtures.firstStageUpOutcome,
                    season: store.weeklyBoard.season,
                    renderState: PhoneUICaptureFixtures.firstStageUpRenderState,
                    onDismiss: {}
                )
            }

        case .rareMutation:
            captureScroll {
                let rareCompanion = PhoneUICaptureFixtures.rareCompanion
                let renderState = PhoneUICaptureFixtures.renderState(for: rareCompanion)
                GameSurface(title: "희귀 변이 신호 고정", accent: rareCompanion.pet.accentColor, eyebrow: "RARE") {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 18) {
                            ZStack {
                                Circle()
                                    .fill(rareCompanion.pet.accentColor.opacity(0.22))
                                    .frame(width: 132, height: 132)
                                    .blur(radius: 18)
                                PixelPetView(
                                    pet: rareCompanion.pet,
                                    pixelSize: 10,
                                    growthStageIndex: renderState.growthStageIndex,
                                    mutationForm: renderState.mutationForm,
                                    mutationHistory: renderState.mutationHistory,
                                    mutationVisualState: renderState.mutationVisualState
                                )
                            }
                            VStack(alignment: .leading, spacing: 10) {
                                Text("밤의 흔적 획득")
                                    .font(.title3.monospaced().weight(.black))
                                    .foregroundStyle(GameBoyPalette.darkest)
                                Text("희귀 변이는 숫자 보너스가 아니라, 한눈에 다른 존재처럼 보여야 합니다. 이 화면은 배너, 오라, 픽셀 외형을 한 번에 확인하는 QA 고정 상태입니다.")
                                    .font(.footnote)
                                    .foregroundStyle(GameBoyPalette.mediumDark)
                                HStack(spacing: 8) {
                                    TraitChip(label: RareVariantMeta.labels[.eclipseMark] ?? "희귀 변이", accent: rareCompanion.pet.accentColor)
                                    TraitChip(label: "한눈에 달라야 함", accent: .orange.opacity(0.28))
                                }
                            }
                        }
                        PhoneRareVariantShowcasePanel(activeVariant: .eclipseMark)
                    }
                }
            }

        case .showcaseShare:
            captureScroll {
                PhoneMilestoneSharePanel(
                    featuredCompanion: PhoneUICaptureFixtures.showcaseCompanion,
                    collection: PhoneUICaptureFixtures.showcaseCollection,
                    eggInventory: [],
                    progress: PhoneUICaptureFixtures.showcaseProgress,
                    season: PhoneUICaptureFixtures.showcaseSeason,
                    onOpenFirstHatchFlow: {},
                    onOpenRareVariantFlow: {},
                    onOpenMythicFlow: {}
                )
            }
        }
    }

    private func captureScroll<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                content()
            }
            .padding(18)
        }
    }
}

@MainActor
extension PhoneDashboardStore {
    convenience init(captureScenario: PhoneUICaptureScenario) {
        self.init()
        progress.completedRuns = PhoneUICaptureFixtures.baseRuns
        progress.journal = PhoneUICaptureFixtures.baseJournal
        progress.ownedCompanions = PhoneUICaptureFixtures.baseCompanions
        progress.eggInventory = [PhoneUICaptureFixtures.forgeEgg]
        progress.growthRecords = PhoneUICaptureFixtures.baseGrowthRecords
        progress.workoutArchives = [PhoneUICaptureFixtures.workoutArchive]
        progress.claimedWeeklyRewards = ["weekly-badge"]
        progress.activeCompanionID = PhoneUICaptureFixtures.starterCompanion.id
        progress.mainCompanionSelection = MainCompanionSelection(kind: .pet, targetID: PhoneUICaptureFixtures.starterCompanion.id)
        progress.watchCompanionSelection = progress.mainCompanionSelection
        progress.worldProgressSnapshot = RunimalWorldProgressEngine.rebuild(from: progress.completedRuns)
        activeWorldPackIDs = contentCatalog.worldContentPackSummaries().prefix(1).map(\.packID)

        switch captureScenario {
        case .eggCreation:
            progress.mainCompanionSelection = MainCompanionSelection(kind: .egg, targetID: PhoneUICaptureFixtures.forgeEgg.id)
            progress.activeCompanionID = nil
        case .rareMutation:
            progress.activeCompanionID = PhoneUICaptureFixtures.rareCompanion.id
            progress.mainCompanionSelection = MainCompanionSelection(kind: .pet, targetID: PhoneUICaptureFixtures.rareCompanion.id)
            progress.watchCompanionSelection = progress.mainCompanionSelection
        case .firstStageUp:
            latestFeedOutcome = PhoneUICaptureFixtures.firstStageUpOutcome
        default:
            break
        }
    }
}

private enum PhoneUICaptureFixtures {
    static let starterCompanionID = "capture-starter"
    static let rareCompanionID = "capture-rare"

    static let starterCompanion = PetCollectionEntry(
        id: starterCompanionID,
        pet: GeneratedPet(
            species: .seedle,
            element: .leaf,
            palette: PetSpecies.seedle.basePaletteName,
            rareVariant: nil,
            explanation: ["first hatch"],
            stats: PetStats(vitality: 9, agility: 8, dexterity: 7, focus: 10, defense: 6)
        ),
        level: 1,
        bond: 32,
        totalDistanceKm: 7.8,
        headline: "둘째 러닝에서 깨어난 첫 동행"
    )

    static let rareCompanion = PetCollectionEntry(
        id: rareCompanionID,
        pet: GeneratedPet(
            species: .shadebit,
            element: .lunar,
            palette: PetSpecies.shadebit.paletteName(rareVariant: .eclipseMark),
            rareVariant: .eclipseMark,
            explanation: ["rare showcase"],
            stats: PetStats(vitality: 11, agility: 15, dexterity: 12, focus: 16, defense: 8)
        ),
        level: 19,
        bond: 68,
        totalDistanceKm: 28.4,
        headline: "희귀 변이 배너와 오라를 확인하는 고정 개체"
    )

    static let forgeEgg = EggInventoryEntry(
        id: "capture-egg",
        shell: .moss,
        title: "???",
        createdAt: date(dayOffset: -2, hour: 7),
        sourceRunID: starterRun.id,
        storedExperience: 18,
        hatchThreshold: 44,
        incubationRunIDs: [],
        unlockedAchievementIDs: [],
        starterBoosted: true
    )

    static let hatchReadyEgg = EggInventoryEntry(
        id: "capture-hatch-ready",
        shell: .dusk,
        title: "???",
        createdAt: date(dayOffset: -1, hour: 21),
        sourceRunID: hatchSourceRun.id,
        storedExperience: 52,
        hatchThreshold: 52,
        incubationRunIDs: ["capture-incubation"],
        unlockedAchievementIDs: ["night-run"],
        starterBoosted: false
    )

    static let hatchCompanion = PetCollectionEntry(
        id: "capture-hatch-result",
        pet: GeneratedPet(
            species: .shadebit,
            element: .lunar,
            palette: PetSpecies.shadebit.paletteName(rareVariant: .eclipseMark),
            rareVariant: .eclipseMark,
            explanation: ["hatch cinematic"],
            stats: PetStats(vitality: 10, agility: 13, dexterity: 11, focus: 15, defense: 8)
        ),
        level: 1,
        bond: 24,
        totalDistanceKm: 9.1,
        headline: "희귀 부화 순간 QA용 고정 결과"
    )

    static let hatchSourceRun = makeRun(
        id: "capture-hatch-run",
        dayOffset: -1,
        hour: 21,
        summary: RunSummary(
            distanceKm: 5.1,
            averagePaceSeconds: 322,
            cadence: 173,
            elevationGainM: 18,
            variability: 0.09,
            aura: .night,
            shape: .maze,
            environmentCondition: .overcast,
            rareEventCompleted: true
        ),
        source: "watch-demo"
    )

    static let starterRun = makeRun(
        id: "capture-starter-run",
        dayOffset: -4,
        hour: 7,
        summary: RunSummary(
            distanceKm: 3.2,
            averagePaceSeconds: 360,
            cadence: 164,
            elevationGainM: 10,
            variability: 0.12,
            aura: .day,
            shape: .freeform,
            environmentCondition: .clear,
            rareEventCompleted: false
        ),
        source: "watch-demo"
    )

    static let secondRun = makeRun(
        id: "capture-second-run",
        dayOffset: -3,
        hour: 7,
        summary: RunSummary(
            distanceKm: 4.6,
            averagePaceSeconds: 344,
            cadence: 168,
            elevationGainM: 18,
            variability: 0.08,
            aura: .dawn,
            shape: .loop,
            environmentCondition: .clear,
            rareEventCompleted: false
        ),
        source: "watch-demo"
    )

    static let stageUpRun = makeRun(
        id: "capture-stage-up-run",
        dayOffset: -2,
        hour: 7,
        summary: RunSummary(
            distanceKm: 6.4,
            averagePaceSeconds: 318,
            cadence: 174,
            elevationGainM: 26,
            variability: 0.07,
            aura: .dusk,
            shape: .loop,
            environmentCondition: .wind,
            rareEventCompleted: false
        ),
        source: "watch-demo"
    )

    static let recordRun = makeRun(
        id: "capture-record-run",
        dayOffset: -1,
        hour: 6,
        summary: RunSummary(
            distanceKm: 7.1,
            averagePaceSeconds: 329,
            cadence: 171,
            elevationGainM: 34,
            variability: 0.08,
            aura: .day,
            shape: .outAndBack,
            environmentCondition: .rain,
            rareEventCompleted: false
        ),
        source: "healthkit:import"
    )

    static let baseRuns = [recordRun, stageUpRun, secondRun, starterRun]

    static let baseJournal = baseRuns.map { run in
        RunimalGameEngine.makeJournalEntry(
            reward: run.reward,
            distanceKm: run.distanceMeters / 1000,
            cadence: run.cadence ?? 0,
            createdAt: run.endedAt
        )
    }

    static let baseCompanions = [starterCompanion, rareCompanion]

    static let baseGrowthRecords = [
        CompanionGrowthRecord(
            companionID: starterCompanionID,
            totalExperience: 12,
            storedPotentialExperience: 10,
            feedCount: 0,
            assignedRunIDs: [starterRun.id, secondRun.id],
            lastFedAt: secondRun.endedAt
        ),
        CompanionGrowthRecord(
            companionID: rareCompanionID,
            totalExperience: RunimalBalanceConfig.companionExperienceTotal(forLevel: 19),
            storedPotentialExperience: 24,
            feedCount: 7,
            assignedRunIDs: [starterRun.id, secondRun.id, stageUpRun.id, recordRun.id],
            lastFedAt: recordRun.endedAt
        ),
    ]

    static let firstStageUpBeforeRecord = CompanionGrowthRecord(
        companionID: starterCompanionID,
        totalExperience: 12,
        storedPotentialExperience: 10,
        feedCount: 0,
        assignedRunIDs: [starterRun.id, secondRun.id],
        lastFedAt: secondRun.endedAt
    )

    static let firstStageUpAfterRecord = CompanionGrowthRecord(
        companionID: starterCompanionID,
        totalExperience: RunimalStarterLoopEngine.guaranteedFirstVisibleStageTotalExperience(for: .seedle),
        storedPotentialExperience: 0,
        feedCount: 1,
        assignedRunIDs: [starterRun.id, secondRun.id, stageUpRun.id],
        lastFedAt: stageUpRun.endedAt
    )

    static let firstStageUpBeforeSnapshot = RunimalCompanionGrowthEngine.progressionSnapshot(
        for: firstStageUpBeforeRecord,
        species: starterCompanion.pet.species
    )

    static let firstStageUpAfterSnapshot = RunimalCompanionGrowthEngine.progressionSnapshot(
        for: firstStageUpAfterRecord,
        species: starterCompanion.pet.species
    )

    static let firstStageUpOutcome = CompanionFeedOutcome(
        runID: stageUpRun.id,
        coreLabel: stageUpRun.reward.coreLabel,
        gainedExperience: firstStageUpAfterRecord.totalExperience - firstStageUpBeforeRecord.totalExperience,
        baseExperience: stageUpRun.reward.experience,
        supportBonusExperience: 24,
        dataBonusExperience: 12,
        storedPotentialExperienceBefore: 10,
        potentialExperienceSpent: 10,
        remainingStoredPotentialExperience: 0,
        bonusLabels: ["첫 성장 고정", "동행 잠재 사용 +10"],
        beforeSnapshot: firstStageUpBeforeSnapshot,
        afterSnapshot: firstStageUpAfterSnapshot,
        beforeProgress: firstStageUpBeforeSnapshot.progress,
        afterProgress: firstStageUpAfterSnapshot.progress,
        stageAdvanced: true
    )

    static let firstStageUpRenderState: CompanionPixelRenderState = {
        let stageIndex = RunimalCompanionGrowthEngine.stageIndex(for: firstStageUpAfterSnapshot.progress)
        let visualState = MutationVisualEvolutionEngine.visibleState(for: .none, growthStageIndex: stageIndex)
        return CompanionPixelRenderState(
            growthStageIndex: stageIndex,
            mutationForm: nil,
            mutationHistory: nil,
            mutationVisualState: visualState
        )
    }()

    static let workoutArchive = WorkoutSessionArchive(
        runID: recordRun.id,
        startedAt: recordRun.startedAt,
        endedAt: recordRun.endedAt,
        elapsedTimeSeconds: recordRun.durationSeconds,
        timerTimeSeconds: recordRun.durationSeconds,
        movingTimeSeconds: recordRun.durationSeconds - 12,
        distanceMeters: recordRun.distanceMeters,
        averageHeartRate: recordRun.averageHeartRate,
        averageCadence: recordRun.cadence,
        averagePaceSeconds: recordRun.averagePaceSeconds,
        elevationGainM: recordRun.elevationGainM,
        source: recordRun.source,
        trackPoints: [
            WorkoutTrackPoint(
                timestamp: recordRun.startedAt,
                latitude: 37.5208,
                longitude: 127.042,
                altitude: 12,
                horizontalAccuracy: 7,
                speedMetersPerSecond: 3.1,
                heartRate: 149,
                cadence: 170,
                gpsPoor: false,
                paused: false
            ),
            WorkoutTrackPoint(
                timestamp: recordRun.startedAt.addingTimeInterval(420),
                latitude: 37.5252,
                longitude: 127.0476,
                altitude: 18,
                horizontalAccuracy: 9,
                speedMetersPerSecond: 3.4,
                heartRate: 153,
                cadence: 172,
                gpsPoor: false,
                paused: false
            )
        ],
        laps: [],
        events: [
            WorkoutSessionEvent(kind: .start, timestamp: recordRun.startedAt),
            WorkoutSessionEvent(kind: .end, timestamp: recordRun.endedAt)
        ]
    )

    static let showcaseCompanion = PetCollectionEntry(
        id: "capture-showcase",
        pet: GeneratedPet(
            species: .windrunner,
            element: .light,
            palette: PetSpecies.windrunner.paletteName(rareVariant: .loopSigil),
            rareVariant: .loopSigil,
            explanation: ["share card"],
            stats: PetStats(vitality: 14, agility: 16, dexterity: 13, focus: 15, defense: 10)
        ),
        level: 27,
        bond: 88,
        totalDistanceKm: 64.2,
        headline: "공유 카드에 바로 올리는 성년기 후보"
    )

    static let showcaseProgress = RunimalCompanionGrowthEngine.evolutionProgress(
        for: CompanionGrowthRecord(
            companionID: "capture-showcase",
            totalExperience: RunimalBalanceConfig.companionExperienceTotal(forLevel: 27),
            storedPotentialExperience: 28,
            feedCount: 9,
            assignedRunIDs: [starterRun.id, secondRun.id, stageUpRun.id, recordRun.id],
            lastFedAt: recordRun.endedAt
        ),
        species: showcaseCompanion.pet.species
    )

    static let showcaseCollection = [showcaseCompanion, rareCompanion, hatchCompanion]
    static let showcaseSeason = WeeklySeason(
        title: "Quiet Signal",
        subtitle: "첫 교감과 부화 순간에 집중",
        bonus: "첫 세 번의 러닝 보상이 또렷하게 읽히도록 정리",
        rewardTitle: "Starter Relay",
        evolutionTitle: "First Life Arc",
        focusSpecies: .seedle,
        focusVariant: .loopSigil
    )

    static func renderState(for companion: PetCollectionEntry) -> CompanionPixelRenderState {
        let progress = RunimalCompanionGrowthEngine.evolutionProgress(
            for: CompanionGrowthRecord(
                companionID: companion.id,
                totalExperience: companion.id == showcaseCompanion.id
                    ? RunimalBalanceConfig.companionExperienceTotal(forLevel: 27)
                    : RunimalBalanceConfig.companionExperienceTotal(forLevel: max(companion.level, 2)),
                storedPotentialExperience: 0,
                feedCount: 3,
                assignedRunIDs: [],
                lastFedAt: nil
            ),
            species: companion.pet.species
        )
        let stageIndex = RunimalCompanionGrowthEngine.stageIndex(for: progress)
        let visualState = MutationVisualEvolutionEngine.visibleState(for: .none, growthStageIndex: stageIndex)
        return CompanionPixelRenderState(
            growthStageIndex: stageIndex,
            mutationForm: nil,
            mutationHistory: nil,
            mutationVisualState: visualState
        )
    }

    private static func makeRun(id: String, dayOffset: Int, hour: Int, summary: RunSummary, source: String) -> CompletedRunRecord {
        let reward = RunimalGameEngine.evaluateReward(for: summary)
        let startedAt = date(dayOffset: dayOffset, hour: hour)
        let endedAt = startedAt.addingTimeInterval(TimeInterval(Int(summary.distanceKm * Double(summary.averagePaceSeconds))))
        return CompletedRunRecord(
            id: id,
            startedAt: startedAt,
            endedAt: endedAt,
            distanceMeters: summary.distanceKm * 1000,
            durationSeconds: Int(endedAt.timeIntervalSince(startedAt)),
            averageHeartRate: 148,
            averagePaceSeconds: summary.averagePaceSeconds,
            cadence: summary.cadence,
            elevationGainM: summary.elevationGainM,
            reward: reward,
            route: [
                RoutePoint(latitude: 37.5208, longitude: 127.042, altitude: 12, timestamp: startedAt),
                RoutePoint(latitude: 37.5252, longitude: 127.0476, altitude: 18, timestamp: endedAt)
            ],
            source: source,
            sourceLabel: source.hasPrefix("healthkit") ? "Imported workout" : "Watch sync",
            environmentCondition: summary.environmentCondition,
            rareEventCompleted: summary.rareEventCompleted
        )
    }

    private static func date(dayOffset: Int, hour: Int) -> Date {
        Calendar(identifier: .gregorian).date(
            from: DateComponents(year: 2026, month: 4, day: 4 + dayOffset, hour: hour, minute: 0)
        ) ?? Date(timeIntervalSince1970: 0)
    }
}
