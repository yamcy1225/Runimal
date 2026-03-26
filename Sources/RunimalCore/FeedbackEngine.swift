import Foundation

public struct LiveRunFeedback: Codable, Equatable, Sendable {
    public let label: String
    public let headline: String
    public let detail: String
    public let intensity: Double

    public init(label: String, headline: String, detail: String, intensity: Double) {
        self.label = label
        self.headline = headline
        self.detail = detail
        self.intensity = intensity
    }
}

public struct HatchInsight: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let emphasis: String

    public init(id: String, title: String, detail: String, emphasis: String) {
        self.id = id
        self.title = title
        self.detail = detail
        self.emphasis = emphasis
    }
}

public struct EvolutionTarget: Codable, Equatable, Sendable {
    public let title: String
    public let detail: String
    public let status: String

    public init(title: String, detail: String, status: String) {
        self.title = title
        self.detail = detail
        self.status = status
    }
}

public extension RunimalGameEngine {
    static func evaluateLiveFeedback(for snapshot: LiveRunSnapshot) -> LiveRunFeedback {
        let pace = snapshot.averagePaceSeconds ?? 360
        let cadence = snapshot.cadence ?? 166
        let heartRate = snapshot.currentHeartRate ?? 148

        if pace <= RunimalBalanceConfig.surgePaceSeconds && cadence >= RunimalBalanceConfig.surgeCadence {
            return LiveRunFeedback(
                label: "Surge",
                headline: "희귀 변이 페이스에 접근 중",
                detail: "고케이던스와 빠른 리듬이 tempo 계열 변이를 자극하고 있습니다.",
                intensity: 0.92
            )
        }

        if pace <= RunimalBalanceConfig.steadyPaceSeconds && cadence >= RunimalBalanceConfig.steadyCadence {
            return LiveRunFeedback(
                label: "Stable",
                headline: "지금 리듬이 가장 좋습니다",
                detail: "안정적인 페이스입니다. 이 구간을 유지하면 집중형 성장치가 올라갑니다.",
                intensity: 0.72
            )
        }

        if heartRate >= Double(RunimalBalanceConfig.recoveryHeartRate) {
            return LiveRunFeedback(
                label: "Recover",
                headline: "조금만 정리하면 더 좋습니다",
                detail: "심박이 높습니다. 호흡을 안정시키면 성장 효율이 다시 올라갑니다.",
                intensity: 0.48
            )
        }

        return LiveRunFeedback(
            label: "Warm",
            headline: "펫이 러닝 흔적을 읽는 중",
            detail: "조금 더 달리면 외형과 속성 변화가 분명해집니다.",
            intensity: 0.35
        )
    }

    static func hatchInsights(for run: CompletedRunRecord) -> [HatchInsight] {
        let paceText = formattedPace(seconds: run.averagePaceSeconds)
        let distanceText = String(format: "%.2fkm", run.distanceMeters / 1000)
        let cadenceText = run.cadence.map(String.init) ?? "--"
        let variantText = run.reward.pet.rareVariant.map { RareVariantMeta.labels[$0] ?? $0.rawValue } ?? "Standard"

        return [
            HatchInsight(
                id: "distance",
                title: "Distance Trace",
                detail: "\(distanceText) 흔적으로 체력 계열이 강화됐습니다.",
                emphasis: distanceText
            ),
            HatchInsight(
                id: "pace",
                title: "Pace Signature",
                detail: "\(paceText) 리듬이 현재 종족과 오라를 결정했습니다.",
                emphasis: paceText
            ),
            HatchInsight(
                id: "cadence",
                title: "Mutation Trigger",
                detail: "케이던스 \(cadenceText) spm 기준으로 \(variantText) 트랙을 판정했습니다.",
                emphasis: variantText
            ),
        ]
    }

    static func evolutionTarget(for progress: EvolutionProgress, recentRun: CompletedRunRecord?) -> EvolutionTarget {
        if progress.progressRatio >= 0.92 {
            return EvolutionTarget(
                title: "진화 임계점 접근",
                detail: "다음 한 번의 강한 러닝으로 진화 연출을 열 수 있습니다.",
                status: "almost there"
            )
        }

        if let recentRun, recentRun.reward.pet.rareVariant != nil {
            return EvolutionTarget(
                title: "희귀 변이 유지",
                detail: "다음 러닝도 비슷한 리듬을 유지하면 상위 트랙으로 연결될 가능성이 높습니다.",
                status: "variant chain"
            )
        }

        return EvolutionTarget(
            title: "안정 페이스 누적",
            detail: "5km 이상 안정적으로 유지하는 러닝을 반복하면 상위 성장 단계가 빨라집니다.",
            status: "\(progress.totalExperience) XP"
        )
    }

    private static func formattedPace(seconds: Int?) -> String {
        guard let seconds, seconds > 0 else { return "--" }
        let minutes = seconds / 60
        return "\(minutes):\(String(format: "%02d", seconds % 60))/km"
    }
}
