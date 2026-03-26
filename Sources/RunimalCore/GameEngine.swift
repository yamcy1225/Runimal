import Foundation

public enum RunimalGameEngine {
    public static func generatePet(from summary: RunSummary) -> GeneratedPet {
        let species = determineSpecies(from: summary)
        let element = determineElement(from: summary)
        let rareVariant = determineRareVariant(from: summary)
        let stats = determineStats(from: summary)
        let palette = determinePalette(element: element, rareVariant: rareVariant)

        var explanation = [
            String(format: "%.1fkm 러닝으로 체력 성향이 반영되었습니다.", summary.distanceKm),
            "평균 케이던스 \(summary.cadence)가 민첩 계열 성장에 영향을 줬습니다.",
            "\(summary.aura.rawValue) 시간대 러닝으로 \(element.rawValue) 속성이 부여되었습니다.",
        ]

        if let rareVariant {
            explanation.append(describe(rareVariant: rareVariant))
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

    public static func evaluateRunQuests(for summary: RunSummary) -> [RunQuestStatus] {
        let pet = generatePet(from: summary)

        return [
            RunQuestStatus(label: "Steady 5K", reward: "focus shard", completed: summary.distanceKm >= 5 && summary.variability <= 0.12, detail: "5km 이상 + 안정적인 페이스"),
            RunQuestStatus(label: "Tempo Check", reward: "tempo shard", completed: summary.cadence >= 170, detail: "케이던스 170 이상"),
            RunQuestStatus(label: "Climb Signal", reward: "stone sigil", completed: summary.elevationGainM >= 60, detail: "고도 상승 60m 이상"),
            RunQuestStatus(label: "Mutation Spark", reward: "rare core", completed: pet.rareVariant != nil, detail: "희귀 변이 생성"),
        ]
    }

    public static func generatePet(from snapshot: LiveRunSnapshot) -> GeneratedPet {
        generatePet(from: summarize(snapshot: snapshot))
    }

    public static func summarize(snapshot: LiveRunSnapshot) -> RunSummary {
        let distanceKm = snapshot.distanceMeters / 1000
        let paceSeconds = snapshot.averagePaceSeconds ?? inferredPaceSeconds(from: snapshot)

        return RunSummary(
            distanceKm: max(distanceKm, 0.2),
            averagePaceSeconds: max(paceSeconds, 260),
            cadence: max(snapshot.cadence ?? 170, 120),
            elevationGainM: max(snapshot.elevationGainM, 0),
            variability: distanceKm >= 3 ? 0.12 : 0.22,
            aura: .day,
            shape: .freeform
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

        switch summary.aura {
        case .dawn: return .light
        case .day: return .flame
        case .dusk: return .leaf
        case .night: return .lunar
        }
    }

    private static func determineRareVariant(from summary: RunSummary) -> RareVariant? {
        if summary.elevationGainM >= 120 {
            return .summitHeart
        }

        if summary.aura == .night && summary.shape == .maze {
            return .eclipseMark
        }

        if summary.distanceKm >= 10 && summary.variability <= 0.08 {
            return .zenBloom
        }

        if summary.averagePaceSeconds <= 315 && summary.cadence >= 172 {
            return .tempoSurge
        }

        if summary.shape == .loop && summary.variability <= 0.12 {
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

    private static func clamp(_ value: Double) -> Int {
        Int(max(1, min(9, value.rounded())))
    }

    private static func paceLabel(seconds: Int) -> String {
        let minutes = seconds / 60
        let remaining = seconds % 60
        return String(format: "%d:%02d/km", minutes, remaining)
    }

    private static func inferredPaceSeconds(from snapshot: LiveRunSnapshot) -> Int {
        guard snapshot.distanceMeters > 10, snapshot.elapsedSeconds > 0 else {
            return 360
        }

        return Int((Double(snapshot.elapsedSeconds) / snapshot.distanceMeters) * 1000)
    }
}
