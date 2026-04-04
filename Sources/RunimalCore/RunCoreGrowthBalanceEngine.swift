import Foundation

public struct RunCoreDataProfile: Codable, Equatable, Sendable {
    public let informationScore: Int
    public let bonusExperience: Int
    public let labels: [String]

    public init(informationScore: Int, bonusExperience: Int, labels: [String]) {
        self.informationScore = informationScore
        self.bonusExperience = bonusExperience
        self.labels = labels
    }
}

public struct LiveCompanionPotentialProfile: Codable, Equatable, Sendable {
    public let eventScore: Int
    public let storedPotentialExperience: Int
    public let labels: [String]

    public init(eventScore: Int, storedPotentialExperience: Int, labels: [String]) {
        self.eventScore = eventScore
        self.storedPotentialExperience = storedPotentialExperience
        self.labels = labels
    }
}

public struct LiveCompanionObjectiveSnapshot: Codable, Equatable, Sendable {
    public let title: String
    public let detail: String
    public let progress: Double

    public init(title: String, detail: String, progress: Double) {
        self.title = title
        self.detail = detail
        self.progress = progress
    }
}

public struct LiveCompanionInteractionCue: Codable, Equatable, Identifiable, Sendable {
    public enum Category: String, Codable, Equatable, Sendable {
        case objective
        case reaction
        case potential
    }

    public let id: String
    public let title: String
    public let detail: String
    public let progress: Double
    public let statusLabel: String
    public let isActive: Bool
    public let category: Category

    public init(
        id: String,
        title: String,
        detail: String,
        progress: Double,
        statusLabel: String,
        isActive: Bool,
        category: Category
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.progress = progress
        self.statusLabel = statusLabel
        self.isActive = isActive
        self.category = category
    }
}

public struct LiveCompanionInteractionPreview: Codable, Equatable, Sendable {
    public let headline: String
    public let detail: String
    public let projectedPotentialExperience: Int
    public let projectedEventScore: Int
    public let cues: [LiveCompanionInteractionCue]

    public init(
        headline: String,
        detail: String,
        projectedPotentialExperience: Int,
        projectedEventScore: Int,
        cues: [LiveCompanionInteractionCue]
    ) {
        self.headline = headline
        self.detail = detail
        self.projectedPotentialExperience = projectedPotentialExperience
        self.projectedEventScore = projectedEventScore
        self.cues = cues
    }

    public static let empty = LiveCompanionInteractionPreview(
        headline: "반응 대기",
        detail: "러닝을 시작하면 실시간 상호작용이 여기 쌓입니다.",
        projectedPotentialExperience: 0,
        projectedEventScore: 0,
        cues: []
    )
}

public enum RunimalRunCoreGrowthBalanceEngine {
    private struct LivePotentialEvent: Equatable, Sendable {
        let label: String
        let score: Int
    }

    public static func dataProfile(for run: CompletedRunRecord) -> RunCoreDataProfile {
        var score = 1
        let labels = dataSignalLabels(for: run, score: &score)

        let bonusExperience: Int
        switch score {
        case ..<4:
            bonusExperience = 0
        case 4...5:
            bonusExperience = 4
        case 6...7:
            bonusExperience = 8
        case 8...9:
            bonusExperience = 12
        case 10...11:
            bonusExperience = 16
        default:
            bonusExperience = 20
        }

        var compactLabels = Array(labels.prefix(2))
        if bonusExperience > 0 {
            compactLabels.insert("기록 밀도 +\(bonusExperience)", at: 0)
        }

        return RunCoreDataProfile(
            informationScore: score,
            bonusExperience: bonusExperience,
            labels: compactLabels
        )
    }

    public static func retainedDataLabels(for run: CompletedRunRecord, limit: Int) -> [String] {
        Array(dataSignalLabels(for: run).prefix(max(limit, 0)))
    }

    public static func livePotential(for run: CompletedRunRecord) -> LiveCompanionPotentialProfile {
        let events = livePotentialEvents(for: run)
        let score = events.reduce(into: 0) { partialResult, event in
            partialResult += event.score
        }

        let storedPotentialExperience = potentialExperience(forEventScore: score)

        var compactLabels = events.map(\.label)
        if storedPotentialExperience > 0 {
            compactLabels.insert("동행 잠재 +\(storedPotentialExperience)", at: 0)
        }

        return LiveCompanionPotentialProfile(
            eventScore: score,
            storedPotentialExperience: storedPotentialExperience,
            labels: compactLabels
        )
    }

    public static func liveInteractionPreview(
        snapshot: LiveRunSnapshot,
        routePointCount: Int,
        gpsAccuracyMeters: Double?,
        isGPSFresh: Bool,
        environmentCondition: EnvironmentCondition,
        rareEventCompleted: Bool,
        isNightWindow: Bool,
        mutationReaction: MutationRuntimeReactionSnapshot? = nil,
        objective: LiveCompanionObjectiveSnapshot? = nil
    ) -> LiveCompanionInteractionPreview {
        let potentialCues = livePotentialCues(
            snapshot: snapshot,
            routePointCount: routePointCount,
            gpsAccuracyMeters: gpsAccuracyMeters,
            isGPSFresh: isGPSFresh,
            environmentCondition: environmentCondition,
            rareEventCompleted: rareEventCompleted,
            isNightWindow: isNightWindow
        )
        let score = potentialCues
            .filter(\.isActive)
            .reduce(into: 0) { partialResult, cue in
                partialResult += cue.score
            }
        let projectedPotentialExperience = potentialExperience(forEventScore: score)

        var cues: [LiveCompanionInteractionCue] = []

        if let objective {
            let clampedProgress = min(max(objective.progress, 0), 1)
            cues.append(
                LiveCompanionInteractionCue(
                    id: "objective-\(objective.title)",
                    title: objective.title,
                    detail: objective.detail,
                    progress: clampedProgress,
                    statusLabel: clampedProgress >= 1 ? "확보" : "\(Int((clampedProgress * 100).rounded()))%",
                    isActive: clampedProgress >= 1,
                    category: .objective
                )
            )
        }

        if let mutationReaction {
            cues.append(
                LiveCompanionInteractionCue(
                    id: mutationReaction.id,
                    title: mutationReaction.title,
                    detail: mutationReaction.detail,
                    progress: 1,
                    statusLabel: "반응 중",
                    isActive: true,
                    category: .reaction
                )
            )
        }

        let sortedPotentialCues = potentialCues
            .sorted { lhs, rhs in
                if lhs.isActive != rhs.isActive {
                    return lhs.isActive && !rhs.isActive
                }
                if lhs.score != rhs.score {
                    return lhs.score > rhs.score
                }
                return lhs.progress > rhs.progress
            }
            .prefix(5)
            .map(\.cue)
        cues.append(contentsOf: sortedPotentialCues)

        let headline: String
        switch projectedPotentialExperience {
        case 18...:
            headline = "잠재 최고점"
        case 14...:
            headline = "잠재 강한 반응"
        case 10...:
            headline = "잠재 안정 구간"
        case 6...:
            headline = "잠재 형성 중"
        default:
            headline = "반응 모으는 중"
        }

        let activePotentialCount = potentialCues.filter(\.isActive).count
        let detail = projectedPotentialExperience > 0
            ? "현재 반응 \(activePotentialCount)건으로 종료 시 잠재 +\(projectedPotentialExperience) XP가 예상됩니다."
            : "아직 저장 잠재는 열리지 않았습니다. 리듬과 유지 구간을 더 맞추면 반응이 쌓입니다."

        return LiveCompanionInteractionPreview(
            headline: headline,
            detail: detail,
            projectedPotentialExperience: projectedPotentialExperience,
            projectedEventScore: score,
            cues: cues
        )
    }

    public static func storedPotentialCap(forLevel level: Int) -> Int {
        RunimalBalanceConfig.lateGrowthFeatures(forLevel: level).storedPotentialCap
    }

    public static func potentialSpendCap(baseExperience: Int, level: Int = 1) -> Int {
        let baseCap = min(20, max(8, Int((Double(max(baseExperience, 1)) * 0.18).rounded())))
        let bonus = RunimalBalanceConfig.lateGrowthFeatures(forLevel: level).potentialSpendCapBonus
        return min(26, baseCap + bonus)
    }

    public static func potentialExperience(forEventScore score: Int) -> Int {
        switch score {
        case ..<3:
            return 0
        case 3...4:
            return 6
        case 5...6:
            return 10
        case 7...8:
            return 14
        default:
            return 18
        }
    }

    @discardableResult
    private static func dataSignalLabels(for run: CompletedRunRecord, score: inout Int) -> [String] {
        dataSignalLabels(for: run) { score += $0 }
    }

    private static func dataSignalLabels(for run: CompletedRunRecord) -> [String] {
        dataSignalLabels(for: run) { _ in }
    }

    private static func dataSignalLabels(for run: CompletedRunRecord, scoreUpdater: (Int) -> Void) -> [String] {
        var labels: [String] = []

        if run.averageHeartRate != nil {
            scoreUpdater(1)
            labels.append("심박 포함")
        }
        if run.cadence != nil {
            scoreUpdater(1)
            labels.append("케이던스 포함")
        }
        if run.averagePaceSeconds != nil {
            scoreUpdater(1)
            labels.append("페이스 포함")
        }
        if run.route.count >= 2 {
            scoreUpdater(2)
            labels.append("경로 기록")
        }
        if run.route.count >= 8 {
            scoreUpdater(1)
            labels.append("지도 밀도")
        }
        if run.elevationGainM >= 20 {
            scoreUpdater(1)
            labels.append("고도 정보")
        }
        if run.environmentCondition != .unknown {
            scoreUpdater(1)
            labels.append("환경 정보")
        }
        if run.rareEventCompleted {
            scoreUpdater(1)
            labels.append("특별 이벤트")
        }
        if (run.mutationContribution?.axes.count ?? 0) >= 2 {
            scoreUpdater(1)
            labels.append("변이 흔적")
        }
        if run.worldImpact != nil {
            scoreUpdater(1)
            labels.append("월드 신호")
        }

        return labels
    }

    private static func livePotentialEvents(for run: CompletedRunRecord) -> [LivePotentialEvent] {
        var events: [LivePotentialEvent] = []

        if let heartRate = run.averageHeartRate,
           heartRate >= 145, heartRate <= 178 {
            events.append(LivePotentialEvent(label: "심박 공명", score: 1))
        }

        if let pace = run.averagePaceSeconds,
           run.durationSeconds >= 900,
           pace >= 280, pace <= 390 {
            events.append(LivePotentialEvent(label: "페이스 유지", score: 1))
        }

        if let cadence = run.cadence, cadence >= 168 {
            events.append(LivePotentialEvent(label: "고케이던스", score: 1))
        }

        if run.route.count >= 8 {
            events.append(LivePotentialEvent(label: "경로 안정", score: 1))
        }

        if run.distanceMeters >= 6_000, run.durationSeconds >= 1_800 {
            events.append(LivePotentialEvent(label: "지속 주행", score: 1))
        }

        if run.elevationGainM >= 30 {
            events.append(LivePotentialEvent(label: "오르막 반응", score: 1))
        }

        if let environmentLabel = liveEnvironmentLabel(for: run.environmentCondition) {
            events.append(LivePotentialEvent(label: environmentLabel, score: 1))
        }

        if isDuskOrNightRun(run) {
            events.append(LivePotentialEvent(label: "야간 감응", score: 1))
        }

        if run.rareEventCompleted {
            events.append(LivePotentialEvent(label: "현장 이벤트", score: 2))
        }

        if (run.mutationContribution?.axes.isEmpty == false) {
            events.append(LivePotentialEvent(label: "변이 공명", score: 1))
        }

        if let worldLabel = liveWorldSignalLabel(for: run.worldImpact) {
            events.append(LivePotentialEvent(label: worldLabel, score: 1))
        }

        return events
    }

    private static func livePotentialCues(
        snapshot: LiveRunSnapshot,
        routePointCount: Int,
        gpsAccuracyMeters: Double?,
        isGPSFresh: Bool,
        environmentCondition: EnvironmentCondition,
        rareEventCompleted: Bool,
        isNightWindow: Bool
    ) -> [(cue: LiveCompanionInteractionCue, score: Int, progress: Double, isActive: Bool)] {
        var cues: [(cue: LiveCompanionInteractionCue, score: Int, progress: Double, isActive: Bool)] = []

        let heartRate = snapshot.currentHeartRate ?? 0
        let heartProgress = heartRate > 0 ? min(max((heartRate - 120) / 25, 0), 1) : 0
        let heartActive = heartRate >= 145 && heartRate <= 178
        cues.append(
            makePotentialCue(
                id: "heart",
                title: "심박 공명",
                detail: heartActive ? "심박이 공명 구간에 들어왔습니다." : "145~178bpm 구간에 들어오면 열립니다.",
                progress: heartActive ? 1 : heartProgress,
                score: 1,
                isActive: heartActive
            )
        )

        let durationProgress = min(Double(snapshot.elapsedSeconds) / 900.0, 1)
        let pace = snapshot.averagePaceSeconds ?? 999
        let paceCloseness = max(0, 1 - (Double(abs(pace - 335)) / 130.0))
        let paceActive = snapshot.elapsedSeconds >= 900 && pace >= 280 && pace <= 390
        cues.append(
            makePotentialCue(
                id: "pace",
                title: "페이스 유지",
                detail: paceActive ? "안정 구간을 유지해 동행이 리듬을 읽고 있습니다." : "15분 이상 안정 페이스를 유지하면 열립니다.",
                progress: paceActive ? 1 : (durationProgress * 0.6) + (paceCloseness * 0.4),
                score: 1,
                isActive: paceActive
            )
        )

        let cadence = snapshot.cadence ?? 0
        let cadenceActive = cadence >= 168
        cues.append(
            makePotentialCue(
                id: "cadence",
                title: "고케이던스",
                detail: cadenceActive ? "지금 리듬이 동행 반응을 강하게 밀어줍니다." : "케이던스 168 이상을 유지하면 열립니다.",
                progress: cadenceActive ? 1 : min(Double(cadence) / 168.0, 1),
                score: 1,
                isActive: cadenceActive
            )
        )

        let routeProgress = min(Double(routePointCount) / 8.0, 1) * (isGPSFresh ? 1 : 0.55)
        let routeActive = routePointCount >= 8
        let routeDetail = isGPSFresh
            ? (routeActive ? "경로가 안정적으로 쌓여 길 반응이 열렸습니다." : "경로 포인트를 더 쌓으면 길 반응이 열립니다.")
            : "GPS가 잠시 흐립니다. 경로가 더 안정되면 길 반응이 열립니다."
        cues.append(
            makePotentialCue(
                id: "route",
                title: "경로 안정",
                detail: routeDetail,
                progress: routeActive ? 1 : routeProgress,
                score: 1,
                isActive: routeActive
            )
        )

        let enduranceProgress = min((min(snapshot.distanceMeters / 6_000.0, Double(snapshot.elapsedSeconds) / 1_800.0)), 1)
        let enduranceActive = snapshot.distanceMeters >= 6_000 && snapshot.elapsedSeconds >= 1_800
        cues.append(
            makePotentialCue(
                id: "endurance",
                title: "지속 주행",
                detail: enduranceActive ? "오래 끌고 가는 호흡이 잠재로 전환되고 있습니다." : "6km와 30분 구간을 같이 넘기면 열립니다.",
                progress: enduranceActive ? 1 : enduranceProgress,
                score: 1,
                isActive: enduranceActive
            )
        )

        let climbProgress = min(Double(snapshot.elevationGainM) / 30.0, 1)
        let climbActive = snapshot.elevationGainM >= 30
        cues.append(
            makePotentialCue(
                id: "climb",
                title: "오르막 반응",
                detail: climbActive ? "상승 구간이 몸 반응을 밀어 올립니다." : "상승 고도 30m를 넘기면 열립니다.",
                progress: climbActive ? 1 : climbProgress,
                score: 1,
                isActive: climbActive
            )
        )

        if environmentCondition != .unknown {
            cues.append(
                makePotentialCue(
                    id: "environment",
                    title: liveEnvironmentLabel(for: environmentCondition) ?? "환경 반응",
                    detail: "현재 환경 조건이 동행 반응에 직접 반영되고 있습니다.",
                    progress: 1,
                    score: 1,
                    isActive: true
                )
            )
        }

        cues.append(
            makePotentialCue(
                id: "night",
                title: "야간 감응",
                detail: isNightWindow ? "지금 시간대는 야간 감응이 열리는 구간입니다." : "황혼이나 야간 러닝에서 열립니다.",
                progress: isNightWindow ? 1 : 0.18,
                score: 1,
                isActive: isNightWindow
            )
        )

        let rareProgress = rareEventCompleted ? 1.0 : 0.0
        cues.append(
            makePotentialCue(
                id: "rare",
                title: "현장 이벤트",
                detail: rareEventCompleted ? "돌발 목표를 확보해 강한 현장 반응이 남습니다." : "돌발 목표를 완수하면 강한 현장 반응이 남습니다.",
                progress: rareProgress,
                score: 2,
                isActive: rareEventCompleted
            )
        )

        return cues
    }

    private static func makePotentialCue(
        id: String,
        title: String,
        detail: String,
        progress: Double,
        score: Int,
        isActive: Bool
    ) -> (cue: LiveCompanionInteractionCue, score: Int, progress: Double, isActive: Bool) {
        let clampedProgress = min(max(progress, 0), 1)
        let cue = LiveCompanionInteractionCue(
            id: id,
            title: title,
            detail: detail,
            progress: clampedProgress,
            statusLabel: isActive ? "활성" : "\(Int((clampedProgress * 100).rounded()))%",
            isActive: isActive,
            category: .potential
        )
        return (cue: cue, score: score, progress: clampedProgress, isActive: isActive)
    }

    private static func liveEnvironmentLabel(for condition: EnvironmentCondition) -> String? {
        switch condition {
        case .rain:
            return "비길 적응"
        case .snow:
            return "눈길 적응"
        case .wind:
            return "바람 대응"
        case .heat:
            return "더위 적응"
        case .cold:
            return "한기 적응"
        case .clear, .overcast, .unknown:
            return nil
        }
    }

    private static func liveWorldSignalLabel(for impact: WorldRunImpact?) -> String? {
        guard let impact else { return nil }
        if impact.unlockedEpisode {
            return "에피소드 감지"
        }
        if impact.unlockedRegion {
            return "새 구역 감지"
        }
        if impact.unlockedSeason {
            return "시즌 공명"
        }
        if impact.episodeID != nil {
            return "이야기 신호"
        }
        return nil
    }

    private static func isDuskOrNightRun(_ run: CompletedRunRecord) -> Bool {
        let midpoint = run.startedAt.addingTimeInterval(run.endedAt.timeIntervalSince(run.startedAt) / 2)
        let hour = Calendar.current.component(.hour, from: midpoint)
        return (5...6).contains(hour) || (18...23).contains(hour) || (0...4).contains(hour)
    }
}
