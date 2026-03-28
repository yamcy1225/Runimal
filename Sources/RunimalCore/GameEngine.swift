import Foundation

public enum RunimalGameEngine {
    public static func generatePet(from summary: RunSummary, claimedRewardIDs: Set<String> = []) -> GeneratedPet {
        let species = determineSpecies(from: summary)
        let element = determineElement(from: summary)
        let rareVariant = determineRareVariant(from: summary, claimedRewardIDs: claimedRewardIDs)
        let stats = determineStats(from: summary)
        let palette = determinePalette(element: element, rareVariant: rareVariant)

        var explanation = [
            String(format: "%.1fkm 러닝으로 체력 성향이 반영되었습니다.", summary.distanceKm),
            "평균 케이던스 \(summary.cadence)가 민첩 계열 성장에 영향을 줬습니다.",
            "\(summary.aura.rawValue) 시간대 러닝으로 \(element.rawValue) 속성이 부여되었습니다.",
        ]

        if summary.environmentCondition != .unknown {
            explanation.append("\(environmentLabel(summary.environmentCondition)) 환경 신호가 디코딩 결과에 섞였습니다.")
        }

        if summary.rareEventCompleted {
            explanation.append("러닝 중 돌발 목표를 달성해 희귀 변이 공명이 상승했습니다.")
        }

        if let rareVariant {
            explanation.append(describe(rareVariant: rareVariant))
        }

        if claimedRewardIDs.contains("weekly-core-cache") && rareVariant != nil {
            explanation.append("주간 Rare Core Cache가 변이 판정을 보조했습니다.")
        }

        return GeneratedPet(
            species: species,
            element: element,
            palette: palette,
            rareVariant: rareVariant,
            explanation: explanation,
            stats: stats
        )
    }

    public static func evaluateRunQuests(for summary: RunSummary, claimedRewardIDs: Set<String> = []) -> [RunQuestStatus] {
        let pet = generatePet(from: summary, claimedRewardIDs: claimedRewardIDs)

        return [
            RunQuestStatus(label: "Steady 5K", reward: "focus shard", completed: summary.distanceKm >= 5 && summary.variability <= 0.12, detail: "5km 이상 + 안정적인 페이스"),
            RunQuestStatus(label: "Tempo Check", reward: "tempo shard", completed: summary.cadence >= 170, detail: "케이던스 170 이상"),
            RunQuestStatus(label: "Climb Signal", reward: "stone sigil", completed: summary.elevationGainM >= 60, detail: "고도 상승 60m 이상"),
            RunQuestStatus(label: "Mutation Spark", reward: "rare core", completed: pet.rareVariant != nil, detail: "희귀 변이 생성"),
        ]
    }

    public static func generatePet(from snapshot: LiveRunSnapshot, claimedRewardIDs: Set<String> = []) -> GeneratedPet {
        generatePet(from: summarize(snapshot: snapshot), claimedRewardIDs: claimedRewardIDs)
    }

    public static func summarize(snapshot: LiveRunSnapshot, preservingRecordedMetrics: Bool = false) -> RunSummary {
        let distanceKm = snapshot.distanceMeters / 1000
        let paceSeconds = snapshot.averagePaceSeconds ?? inferredPaceSeconds(from: snapshot)
        let normalizedDistanceKm = preservingRecordedMetrics ? max(distanceKm, 0.01) : max(distanceKm, 0.2)
        let normalizedPaceSeconds = preservingRecordedMetrics ? max(paceSeconds, 1) : max(paceSeconds, 260)
        let normalizedCadence = preservingRecordedMetrics ? max(snapshot.cadence ?? 0, 0) : max(snapshot.cadence ?? 170, 120)

        return RunSummary(
            distanceKm: normalizedDistanceKm,
            averagePaceSeconds: normalizedPaceSeconds,
            cadence: normalizedCadence,
            elevationGainM: max(snapshot.elevationGainM, 0),
            variability: distanceKm >= 3 ? 0.12 : 0.22,
            aura: .day,
            shape: .freeform,
            environmentCondition: .unknown,
            rareEventCompleted: false
        )
    }

    public static func suggestWorkoutPlan(for pet: GeneratedPet) -> WorkoutPlanSuggestion {
        let distance: Double
        let paceBand: String

        switch pet.species {
        case .windrunner:
            distance = 8
            paceBand = "5:10-5:35/km"
        case .stoneback:
            distance = 6
            paceBand = "5:50-6:20/km"
        case .sparkfang:
            distance = 4
            paceBand = "4:45-5:10/km"
        case .mosshop:
            distance = 5
            paceBand = "5:30-5:55/km"
        case .shadebit:
            distance = 7
            paceBand = "5:40-6:05/km"
        case .seedle:
            distance = 3
            paceBand = "6:00-6:40/km"
        }

        return WorkoutPlanSuggestion(
            title: "\(pet.species.rawValue) focus run",
            summary: "\(pet.element.rawValue) 속성 펫에 맞춘 추천 러닝입니다.",
            scheduledDistanceKm: distance,
            targetPaceBand: paceBand
        )
    }

    public static func buildCollection(from summaries: [RunSummary]) -> [PetCollectionEntry] {
        summaries.enumerated().map { index, summary in
            let pet = generatePet(from: summary)
            let level = max(1, min(50, Int((summary.distanceKm * 1.2).rounded()) + index + 2))
            let bond = max(20, min(99, Int(summary.cadence / 2) - index))
            let headline = [
                String(format: "%.1fkm", summary.distanceKm),
                "pace \(paceLabel(seconds: summary.averagePaceSeconds))",
                "cadence \(summary.cadence)",
            ].joined(separator: " · ")

            return PetCollectionEntry(
                id: "pet-\(index)-\(pet.species.rawValue)-\(pet.element.rawValue)",
                pet: pet,
                level: level,
                bond: bond,
                totalDistanceKm: summary.distanceKm,
                headline: headline
            )
        }
    }

    public static func buildVariantCodex(from collection: [PetCollectionEntry]) -> [VariantCodexEntry] {
        let discovered = Set(collection.compactMap(\.pet.rareVariant))

        return RareVariant.allCases.map { variant in
            VariantCodexEntry(
                variant: variant,
                label: RareVariantMeta.labels[variant] ?? variant.rawValue,
                passive: RareVariantMeta.passives[variant] ?? "",
                detail: describe(rareVariant: variant),
                discovered: discovered.contains(variant)
            )
        }
    }

    public static func evaluateReward(for summary: RunSummary, claimedRewardIDs: Set<String> = []) -> RunRewardSummary {
        let pet = generatePet(from: summary, claimedRewardIDs: claimedRewardIDs)
        let completedQuestCount = evaluateRunQuests(for: summary, claimedRewardIDs: claimedRewardIDs).filter(\.completed).count
        let baseExperience = max(40, Int(summary.distanceKm * 14) + completedQuestCount * 18)
        let pulse = RunimalRewardPulseEngine.runPulse(for: summary, completedQuestCount: completedQuestCount)
        let experience = modifiedExperience(
            baseExperience: baseExperience + pulse.bonusExperience,
            claimedRewardIDs: claimedRewardIDs
        )
        let flavorText = rewardFlavorText(for: pet, completedQuestCount: completedQuestCount, claimedRewardIDs: claimedRewardIDs)
        let enrichedFlavorText = ([flavorText] + pulse.flavorFragments).joined(separator: " ")

        return RunRewardSummary(
            pet: pet,
            coreLabel: rewardCoreLabel(for: pet),
            experience: experience,
            completedQuestCount: completedQuestCount,
            flavorText: enrichedFlavorText,
            bonusLabels: pulse.bonusLabels
        )
    }

    public static func evaluateReward(for snapshot: LiveRunSnapshot, claimedRewardIDs: Set<String> = []) -> RunRewardSummary {
        evaluateReward(for: summarize(snapshot: snapshot), claimedRewardIDs: claimedRewardIDs)
    }

    public static func evaluateImportedWorkoutReward(
        for snapshot: LiveRunSnapshot,
        claimedRewardIDs: Set<String> = []
    ) -> RunRewardSummary {
        evaluateReward(
            for: summarize(snapshot: snapshot, preservingRecordedMetrics: true),
            claimedRewardIDs: claimedRewardIDs
        )
    }

    public static func applyWeeklyRewardModifiers(
        to reward: RunRewardSummary,
        claimedRewardIDs: Set<String>
    ) -> RunRewardSummary {
        guard claimedRewardIDs.isEmpty == false else { return reward }

        return RunRewardSummary(
            pet: reward.pet,
            coreLabel: reward.coreLabel,
            experience: modifiedExperience(baseExperience: reward.experience, claimedRewardIDs: claimedRewardIDs),
            completedQuestCount: reward.completedQuestCount,
            flavorText: reward.flavorText,
            bonusLabels: reward.bonusLabels
        )
    }

    public static func activeWeeklyEffects(from claimedRewardIDs: Set<String>) -> [WeeklyRewardEffect] {
        var effects: [WeeklyRewardEffect] = []

        if claimedRewardIDs.contains("weekly-badge") {
            effects.append(
                WeeklyRewardEffect(
                    id: "weekly-badge",
                    title: "Badge Momentum",
                    detail: "이후 러닝 보상 XP가 15% 증가합니다."
                )
            )
        }

        if claimedRewardIDs.contains("weekly-core-cache") {
            effects.append(
                WeeklyRewardEffect(
                    id: "weekly-core-cache",
                    title: "Core Bias",
                    detail: "희귀 변이 판정이 완화되어 근접한 러닝도 변이로 연결될 수 있습니다."
                )
            )
        }

        if claimedRewardIDs.contains("weekly-evo-boost") {
            effects.append(
                WeeklyRewardEffect(
                    id: "weekly-evo-boost",
                    title: "Evolution Fuel",
                    detail: "이후 러닝마다 추가 28 XP가 더해져 진화 속도가 빨라집니다."
                )
            )
        }

        return effects
    }

    public static func makeJournalEntry(
        reward: RunRewardSummary,
        distanceKm: Double,
        cadence: Int,
        createdAt: Date = Date()
    ) -> RunJournalEntry {
        RunJournalEntry(
            id: "journal-\(createdAt.timeIntervalSince1970)",
            createdAt: createdAt,
            reward: reward,
            distanceKm: distanceKm,
            cadence: cadence
        )
    }

    public static func evolutionProgress(for journal: [RunJournalEntry]) -> EvolutionProgress {
        let totalExperience = journal.reduce(0) { $0 + $1.reward.experience }
        let thresholds = RunimalBalanceConfig.evolutionThresholds
        let stageLabels = RunimalBalanceConfig.evolutionStageLabels

        var currentStage = 0

        for index in thresholds.indices where totalExperience >= thresholds[index] {
            currentStage = index
        }

        let nextIndex = min(currentStage + 1, thresholds.count - 1)
        let currentThreshold = thresholds[currentStage]
        let nextThreshold = thresholds[nextIndex]
        let ratio: Double

        if currentStage == thresholds.count - 1 {
            ratio = 1
        } else {
            ratio = min(
                max(Double(totalExperience - currentThreshold) / Double(nextThreshold - currentThreshold), 0),
                1
            )
        }

        let headline: String

        if currentStage == thresholds.count - 1 {
            headline = "최종 단계에 도달했습니다. 이제 희귀 변이와 고급 루프를 노릴 시점입니다."
        } else {
            headline = "다음 진화까지 \(nextThreshold - totalExperience) XP 남았습니다."
        }

        return EvolutionProgress(
            stageLabel: stageLabels[currentStage],
            totalExperience: totalExperience,
            nextThreshold: nextThreshold,
            progressRatio: ratio,
            headline: headline
        )
    }

    public static func makeCompletedRunRecord(
        reward: RunRewardSummary,
        snapshot: LiveRunSnapshot,
        startedAt: Date,
        endedAt: Date,
        averageHeartRate: Double?,
        route: [RoutePoint],
        source: String,
        sourceLabel: String? = nil,
        environmentCondition: EnvironmentCondition = .unknown,
        rareEventCompleted: Bool = false,
        id: String = UUID().uuidString
    ) -> CompletedRunRecord {
        let raidContribution = max((reward.experience / 12) + reward.completedQuestCount, 1)
        return CompletedRunRecord(
            id: id,
            startedAt: startedAt,
            endedAt: endedAt,
            distanceMeters: snapshot.distanceMeters,
            durationSeconds: snapshot.elapsedSeconds,
            averageHeartRate: averageHeartRate,
            averagePaceSeconds: snapshot.averagePaceSeconds,
            cadence: snapshot.cadence,
            elevationGainM: snapshot.elevationGainM,
            reward: reward,
            route: route,
            source: source,
            sourceLabel: sourceLabel,
            raidContribution: raidContribution,
            environmentCondition: environmentCondition,
            rareEventCompleted: rareEventCompleted
        )
    }

    private static func determineSpecies(from summary: RunSummary) -> PetSpecies {
        if summary.distanceKm >= 8 && summary.variability <= 1.6 {
            return .windrunner
        }

        if summary.distanceKm >= 6 && summary.elevationGainM >= 90 {
            return .stoneback
        }

        if summary.distanceKm < 4 && summary.averagePaceSeconds < 310 {
            return .sparkfang
        }

        if summary.variability > 2.4 && summary.aura == .night {
            return .shadebit
        }

        if summary.distanceKm >= 4 && summary.variability <= 2.0 {
            return .mosshop
        }

        return .seedle
    }

    private static func determineElement(from summary: RunSummary) -> PetElement {
        if summary.elevationGainM >= 120 {
            return .earth
        }

        switch summary.environmentCondition {
        case .rain:
            return .leaf
        case .snow:
            return .lunar
        case .heat:
            return .flame
        default:
            break
        }

        switch summary.aura {
        case .dawn: return .light
        case .day: return .flame
        case .dusk: return .leaf
        case .night: return .lunar
        }
    }

    private static func determineRareVariant(from summary: RunSummary, claimedRewardIDs: Set<String>) -> RareVariant? {
        if summary.rareEventCompleted {
            if summary.averagePaceSeconds <= 330 || summary.cadence >= 170 {
                return .tempoSurge
            }

            if summary.distanceKm >= 6 {
                return .loopSigil
            }
        }

        if summary.elevationGainM >= 120 {
            return .summitHeart
        }

        if summary.aura == .night && summary.shape == .maze {
            return .eclipseMark
        }

        if summary.distanceKm >= 10 && summary.variability <= 0.08 {
            return .zenBloom
        }

        if summary.environmentCondition == .rain && summary.distanceKm >= 5 {
            return .zenBloom
        }

        if summary.averagePaceSeconds <= 315 && summary.cadence >= 172 {
            return .tempoSurge
        }

        if summary.shape == .loop && summary.variability <= 0.12 {
            return .loopSigil
        }

        guard claimedRewardIDs.contains("weekly-core-cache") else {
            return nil
        }

        if summary.elevationGainM >= 100 {
            return .summitHeart
        }

        if summary.distanceKm >= 8.5 && summary.variability <= 0.10 {
            return .zenBloom
        }

        if summary.averagePaceSeconds <= 325 && summary.cadence >= 170 {
            return .tempoSurge
        }

        if summary.shape == .loop && summary.variability <= 0.15 {
            return .loopSigil
        }

        return nil
    }

    private static func determinePalette(element: PetElement, rareVariant: RareVariant?) -> String {
        let base: String

        switch element {
        case .light: base = "Sunseed"
        case .flame: base = "Ember Dash"
        case .leaf: base = "Moss Echo"
        case .lunar: base = "Moon Current"
        case .earth: base = "Crag Bark"
        }

        guard let rareVariant else {
            return base
        }

        switch rareVariant {
        case .summitHeart: return "\(base) Prime"
        case .eclipseMark: return "\(base) Eclipse"
        case .zenBloom: return "\(base) Zen"
        case .tempoSurge: return "\(base) Rush"
        case .loopSigil: return "\(base) Sigil"
        }
    }

    private static func determineStats(from summary: RunSummary) -> PetStats {
        PetStats(
            vitality: clamp(summary.distanceKm * 0.75),
            agility: clamp(8 - Double(summary.averagePaceSeconds - 260) / 25),
            dexterity: clamp(Double(summary.cadence - 145) / 5),
            focus: clamp(8 - summary.variability * 1.8),
            defense: clamp(Double(summary.elevationGainM) / 18)
        )
    }

    private static func describe(rareVariant: RareVariant) -> String {
        switch rareVariant {
        case .summitHeart:
            return "높은 고도 상승이 감지되어 summit-heart 희귀 변이가 깨어났습니다."
        case .eclipseMark:
            return "야간 미로형 경로가 겹치며 eclipse-mark 희귀 변이가 생성되었습니다."
        case .zenBloom:
            return "장거리와 극도로 안정적인 페이스가 zen-bloom 희귀 변이를 만들었습니다."
        case .tempoSurge:
            return "빠른 페이스와 높은 케이던스가 tempo-surge 희귀 변이를 열었습니다."
        case .loopSigil:
            return "안정적인 루프 경로가 loop-sigil 희귀 변이를 남겼습니다."
        }
    }

    private static func environmentLabel(_ condition: EnvironmentCondition) -> String {
        switch condition {
        case .clear: return "맑은"
        case .rain: return "비"
        case .snow: return "눈"
        case .wind: return "강풍"
        case .heat: return "고온"
        case .cold: return "저온"
        case .overcast: return "흐린"
        case .unknown: return "미확인"
        }
    }

    private static func clamp(_ value: Double) -> Int {
        Int(max(1, min(9, value.rounded())))
    }

    private static func paceLabel(seconds: Int) -> String {
        let minutes = seconds / 60
        let remaining = seconds % 60
        return String(format: "%d:%02d/km", minutes, remaining)
    }

    private static func rewardCoreLabel(for pet: GeneratedPet) -> String {
        if let rareVariant = pet.rareVariant {
            return "\(RareVariantMeta.labels[rareVariant] ?? "Rare") Core"
        }

        return "\(pet.element.rawValue.capitalized) Core"
    }

    private static func rewardFlavorText(for pet: GeneratedPet, completedQuestCount: Int, claimedRewardIDs: Set<String>) -> String {
        let speciesLabel = pet.species.rawValue.replacingOccurrences(of: "-", with: " ").capitalized
        let baseText: String

        if completedQuestCount >= 3 {
            baseText = "\(speciesLabel)이 강하게 깨어났습니다. 이번 러닝은 진화에 가까운 흔적을 남겼습니다."
        } else {
            baseText = "\(speciesLabel)이 러닝 흔적을 흡수해 안정적으로 성장했습니다."
        }

        if claimedRewardIDs.contains("weekly-evo-boost") {
            return "\(baseText) Evolution Boost가 추가 경험치를 밀어 넣었습니다."
        }

        if claimedRewardIDs.contains("weekly-badge") {
            return "\(baseText) 주간 배지 보정으로 경험치가 증폭되었습니다."
        }

        return baseText
    }

    private static func modifiedExperience(baseExperience: Int, claimedRewardIDs: Set<String>) -> Int {
        var result = Double(baseExperience)

        if claimedRewardIDs.contains("weekly-badge") {
            result *= 1.15
        }

        if claimedRewardIDs.contains("weekly-evo-boost") {
            result += 28
        }

        return Int(result.rounded())
    }

    private static func inferredPaceSeconds(from snapshot: LiveRunSnapshot) -> Int {
        guard snapshot.distanceMeters > 10, snapshot.elapsedSeconds > 0 else {
            return 360
        }

        return Int((Double(snapshot.elapsedSeconds) / snapshot.distanceMeters) * 1000)
    }
}
