import Foundation

public enum RunimalBalanceConfig {
    public static let evolutionThresholds = [0, 160, 340, 580, 860]
    public static let evolutionStageLabels = ["Trace Egg", "Stage 1", "Stage 2", "Ascended", "Mythic"]

    public static let surgePaceSeconds = 310
    public static let steadyPaceSeconds = 340
    public static let surgeCadence = 172
    public static let steadyCadence = 168
    public static let recoveryHeartRate = 172
}

public struct EvolutionTreeNode: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let status: String
    public let unlocked: Bool
    public let current: Bool

    public init(id: String, title: String, detail: String, status: String, unlocked: Bool, current: Bool) {
        self.id = id
        self.title = title
        self.detail = detail
        self.status = status
        self.unlocked = unlocked
        self.current = current
    }
}

public extension RunimalGameEngine {
    static func evolutionTree(
        for pet: GeneratedPet,
        progress: EvolutionProgress,
        season: WeeklySeason? = nil
    ) -> [EvolutionTreeNode] {
        let titles = evolutionTitles(for: pet, season: season)
        let currentIndex = max(
            0,
            RunimalBalanceConfig.evolutionStageLabels.firstIndex(of: progress.stageLabel) ?? 0
        )

        return titles.enumerated().map { index, title in
            let status: String

            if index < currentIndex {
                status = "cleared"
            } else if index == currentIndex {
                status = "current"
            } else {
                status = "locked"
            }

            return EvolutionTreeNode(
                id: "stage-\(index)-\(title)",
                title: title,
                detail: evolutionDetail(for: pet, stageIndex: index, season: season),
                status: status,
                unlocked: index <= currentIndex,
                current: index == currentIndex
            )
        }
    }

    static func seasonAffinity(for pet: GeneratedPet, season: WeeklySeason) -> Bool {
        pet.species == season.focusSpecies || pet.rareVariant == season.focusVariant
    }

    static func balanceTuningNotes(for pet: GeneratedPet) -> [String] {
        let thresholdText = RunimalBalanceConfig.evolutionThresholds.map(String.init).joined(separator: " / ")
        let passiveText = pet.rareVariant.flatMap { RareVariantMeta.passives[$0] } ?? "none"

        var notes = [
            "기본 진화 임계치: \(thresholdText) XP",
            "스프린트 판정: \(RunimalBalanceConfig.surgePaceSeconds)s 이하 + 케이던스 \(RunimalBalanceConfig.surgeCadence)+",
        ]

        if pet.rareVariant != nil {
            notes.append("현재 변이 패시브: \(passiveText)")
        } else {
            notes.append("표준 개체: 다음 러닝에서 페이스/경로 패턴으로 변이 분기 가능")
        }

        return notes
    }

    private static func evolutionTitles(for pet: GeneratedPet, season: WeeklySeason?) -> [String] {
        let apexTitle: String

        if let season, seasonAffinity(for: pet, season: season) {
            apexTitle = season.evolutionTitle
        } else {
            switch pet.rareVariant {
            case .tempoSurge:
                apexTitle = "Velocity Crown"
            case .zenBloom:
                apexTitle = "Halo Current"
            case .summitHeart:
                apexTitle = "Summit Forge"
            case .eclipseMark:
                apexTitle = "Night Relay"
            case .loopSigil:
                apexTitle = "Sigil Orbit"
            case nil:
                apexTitle = "\(pet.displayBaseName) Prime"
            }
        }

        return [
            "Trace Egg",
            "\(pet.displayBaseName) Cub",
            "\(pet.displayBaseName) Scout",
            "\(pet.displayBaseName) Vanguard",
            apexTitle,
        ]
    }

    private static func evolutionDetail(for pet: GeneratedPet, stageIndex: Int, season: WeeklySeason?) -> String {
        switch stageIndex {
        case 0:
            return "첫 러닝 흔적을 흡수하는 준비 단계입니다."
        case 1:
            return "거리와 케이던스가 종족 기반 스탯을 고정합니다."
        case 2:
            return "희귀 변이와 시간대 속성이 외형 분기를 만듭니다."
        case 3:
            return "누적 XP와 반복 패턴이 전투 역할을 굳힙니다."
        default:
            let variantLabel = pet.rareVariant.map { RareVariantMeta.labels[$0] ?? $0.rawValue } ?? "Standard"
            let elementLabel = elementLabel(for: pet.element)
            if let season, seasonAffinity(for: pet, season: season) {
                return "\(elementLabel) • \(variantLabel) 최종 형태입니다. 이번 시즌 전용 진화명 \(season.evolutionTitle)로 승격됩니다."
            }
            return "\(elementLabel) • \(variantLabel) 최종 형태입니다. 장기 루프용 보너스가 붙습니다."
        }
    }

    private static func elementLabel(for element: PetElement) -> String {
        switch element {
        case .light: return "Light"
        case .flame: return "Flame"
        case .leaf: return "Leaf"
        case .lunar: return "Lunar"
        case .earth: return "Earth"
        }
    }
}

private extension GeneratedPet {
    var displayBaseName: String {
        switch species {
        case .windrunner: return "Windrunner"
        case .stoneback: return "Stoneback"
        case .sparkfang: return "Sparkfang"
        case .mosshop: return "Mosshop"
        case .shadebit: return "Shadebit"
        case .seedle: return "Seedle"
        }
    }
}
