import Foundation

public struct MutationRuntimeReactionSnapshot: Equatable, Sendable {
    public enum Axis: String, Equatable, Sendable {
        case body
        case ecology
        case rhythm
    }

    public let id: String
    public let axis: Axis
    public let stage: Int
    public let title: String
    public let detail: String
    public let transitionStageTitle: String?
    public let transitionPartLabel: String?

    public init(
        id: String,
        axis: Axis,
        stage: Int,
        title: String,
        detail: String,
        transitionStageTitle: String? = nil,
        transitionPartLabel: String? = nil
    ) {
        self.id = id
        self.axis = axis
        self.stage = stage
        self.title = title
        self.detail = detail
        self.transitionStageTitle = transitionStageTitle
        self.transitionPartLabel = transitionPartLabel
    }
}

public enum MutationRuntimeReactionEngine {
    public static func reaction(
        for visualState: MutationVisualState,
        snapshot: LiveRunSnapshot,
        gpsAccuracyMeters: Double?,
        isGPSFresh: Bool,
        bridgeSnapshots: [MutationRuntimeReactionSnapshot.Axis: MutationBranchBridgeSnapshot] = [:]
    ) -> MutationRuntimeReactionSnapshot? {
        let candidates = [
            bodyCandidate(for: visualState, snapshot: snapshot, bridge: bridgeSnapshots[.body]),
            ecologyCandidate(
                for: visualState,
                snapshot: snapshot,
                gpsAccuracyMeters: gpsAccuracyMeters,
                isGPSFresh: isGPSFresh,
                bridge: bridgeSnapshots[.ecology]
            ),
            rhythmCandidate(for: visualState, snapshot: snapshot, bridge: bridgeSnapshots[.rhythm]),
        ]
        .compactMap { $0 }

        return candidates.max(by: isLowerPriority)
    }

    private static func isLowerPriority(
        _ lhs: MutationRuntimeReactionSnapshot,
        _ rhs: MutationRuntimeReactionSnapshot
    ) -> Bool {
        if lhs.stage != rhs.stage {
            return lhs.stage < rhs.stage
        }
        return axisPriority(lhs.axis) < axisPriority(rhs.axis)
    }

    private static func axisPriority(_ axis: MutationRuntimeReactionSnapshot.Axis) -> Int {
        switch axis {
        case .rhythm:
            return 3
        case .body:
            return 2
        case .ecology:
            return 1
        }
    }

    private static func bodyCandidate(
        for visualState: MutationVisualState,
        snapshot: LiveRunSnapshot,
        bridge: MutationBranchBridgeSnapshot?
    ) -> MutationRuntimeReactionSnapshot? {
        let stage = visualState.bodyStage
        guard stage > 0 else { return nil }

        let climbedEnough = snapshot.elevationGainM >= (stage >= 3 ? 18 : 28)
        let heartEnough = (snapshot.currentHeartRate ?? 0) >= (stage >= 2 ? 148 : 155)
        guard climbedEnough || heartEnough else { return nil }

        return MutationRuntimeReactionSnapshot(
            id: "body-stage-\(stage)-\(bridge?.branchID ?? "core")",
            axis: .body,
            stage: stage,
            title: bridge.map { "\($0.startStageTitle) 체형 반응" } ?? (stage >= 3 ? "실루엣 각성" : "실루엣 반응"),
            detail: bridgeDetail(
                bridge,
                fallback: "오르막과 심박 상승으로 체형 흔적이 굳어집니다."
            ),
            transitionStageTitle: bridge?.startStageTitle,
            transitionPartLabel: compactPartLabel(for: bridge)
        )
    }

    private static func ecologyCandidate(
        for visualState: MutationVisualState,
        snapshot: LiveRunSnapshot,
        gpsAccuracyMeters: Double?,
        isGPSFresh: Bool,
        bridge: MutationBranchBridgeSnapshot?
    ) -> MutationRuntimeReactionSnapshot? {
        let stage = visualState.ecologyStage
        guard stage > 0 else { return nil }

        let gpsStable = isGPSFresh && (gpsAccuracyMeters ?? 99) <= (stage >= 3 ? 16 : 12)
        let routeEnough = snapshot.distanceMeters >= (stage >= 2 ? 500 : 800)
        guard gpsStable && routeEnough else { return nil }

        return MutationRuntimeReactionSnapshot(
            id: "ecology-stage-\(stage)-\(bridge?.branchID ?? "core")",
            axis: .ecology,
            stage: stage,
            title: bridge.map { "\($0.startStageTitle) 서식 반응" } ?? (stage >= 3 ? "서식 공명" : "경로 반응"),
            detail: bridgeDetail(
                bridge,
                fallback: "안정된 경로 감지로 서식 무늬가 선명해집니다."
            ),
            transitionStageTitle: bridge?.startStageTitle,
            transitionPartLabel: compactPartLabel(for: bridge)
        )
    }

    private static func rhythmCandidate(
        for visualState: MutationVisualState,
        snapshot: LiveRunSnapshot,
        bridge: MutationBranchBridgeSnapshot?
    ) -> MutationRuntimeReactionSnapshot? {
        let stage = visualState.rhythmStage
        guard stage > 0 else { return nil }

        let cadenceTarget = stage >= 3 ? 166 : 170
        let paceTarget = stage >= 2 ? 345 : 330
        let cadenceReady = (snapshot.cadence ?? 0) >= cadenceTarget
        let paceReady = (snapshot.averagePaceSeconds ?? Int.max) <= paceTarget
        guard cadenceReady || paceReady else { return nil }

        return MutationRuntimeReactionSnapshot(
            id: "rhythm-stage-\(stage)-\(bridge?.branchID ?? "core")",
            axis: .rhythm,
            stage: stage,
            title: bridge.map { "\($0.startStageTitle) 리듬 반응" } ?? (stage >= 3 ? "박동 각성" : "리듬 반응"),
            detail: bridgeDetail(
                bridge,
                fallback: "페이스와 케이던스가 맞아 박동 문양이 살아납니다."
            ),
            transitionStageTitle: bridge?.startStageTitle,
            transitionPartLabel: compactPartLabel(for: bridge)
        )
    }

    private static func bridgeDetail(
        _ bridge: MutationBranchBridgeSnapshot?,
        fallback: String
    ) -> String {
        guard let bridge else { return fallback }
        let partLabel = compactPartLabel(for: bridge) ?? "파츠"
        return "\(partLabel)가 \(bridge.branchTitle) 갈래로 반응합니다."
    }

    private static func compactPartLabel(for bridge: MutationBranchBridgeSnapshot?) -> String? {
        guard let bridge else { return nil }
        let parts = bridge.redirectedParts.isEmpty == false ? bridge.redirectedParts : bridge.inheritedParts
        return parts.first?.title
    }
}
