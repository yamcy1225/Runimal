import Foundation

public struct MutationAxisEvidenceSnapshot: Equatable, Identifiable, Sendable {
    public let axis: SpeciesLineageAxis
    public let branchID: String
    public let branchTitle: String
    public let aggregateReason: String
    public let recentReason: String?

    public var id: SpeciesLineageAxis { axis }
}

public struct MutationEvidenceSnapshot: Equatable, Sendable {
    public let speciesID: String
    public let axes: [MutationAxisEvidenceSnapshot]

    public func evidence(for axis: SpeciesLineageAxis) -> MutationAxisEvidenceSnapshot? {
        axes.first(where: { $0.axis == axis })
    }
}

public enum SpeciesMutationEvidenceEngine {
    public static func evidence(
        for runs: [CompletedRunRecord],
        preferredSpecies: PetSpecies? = nil,
        blueprints: [SpeciesExpansionBlueprint] = DefaultSpeciesExpansionBlueprints.baseSpeciesBlueprints
    ) -> MutationEvidenceSnapshot? {
        let sortedRuns = runs.sorted { $0.endedAt < $1.endedAt }
        guard sortedRuns.isEmpty == false,
              let history = SpeciesMutationHistoryEngine.history(
                for: sortedRuns,
                preferredSpecies: preferredSpecies,
                blueprints: blueprints
              ),
              let profile = SpeciesMutationUnlockEngine.buildProfile(from: sortedRuns) else {
            return nil
        }

        let latestRun = sortedRuns.last
        let axes = history.axes.map { axis in
            let rationale = SpeciesMutationUnlockEngine.score(
                branchID: axis.currentBranchID,
                speciesID: history.speciesID,
                profile: profile
            ).rationale

            return MutationAxisEvidenceSnapshot(
                axis: axis.axis,
                branchID: axis.currentBranchID,
                branchTitle: axis.currentTitle,
                aggregateReason: rationale,
                recentReason: latestRun.map { recentReason(for: axis.axis, run: $0) }
            )
        }

        return MutationEvidenceSnapshot(speciesID: history.speciesID, axes: axes)
    }

    private static func recentReason(for axis: SpeciesLineageAxis, run: CompletedRunRecord) -> String {
        switch axis {
        case .body:
            if run.elevationGainM >= 100 { return "최근 언덕/고도 세션이 체형을 강하게 밀었습니다." }
            if let pace = run.averagePaceSeconds, pace < 340 { return "최근 빠른 세션이 전면 실루엣 변이를 밀었습니다." }
            if run.distanceMeters >= 8_000 { return "최근 장거리 세션이 체형 안정성을 밀었습니다." }
            return "최근 러닝의 체형 자극은 중간 수준이었습니다."
        case .ecology:
            if run.environmentCondition == .rain { return "최근 비 러닝이 생태 문양을 강하게 남겼습니다." }
            if run.environmentCondition == .wind || run.environmentCondition == .cold { return "최근 거친 환경이 외곽 표식을 강하게 밀었습니다." }
            if runtimeAura(for: run) == .night || runtimeAura(for: run) == .dusk { return "최근 황혼 시간대가 생태 표식을 어둡게 밀었습니다." }
            return "최근 코스 환경이 생태 적응 흔적을 남겼습니다."
        case .rhythm:
            if let cadence = run.cadence, cadence >= 174 { return "최근 높은 케이던스가 리듬 파츠를 강하게 밀었습니다." }
            if routeShape(for: run.route) == .loop { return "최근 반복 루프가 꼬리 파동 패턴을 강화했습니다." }
            if let pace = run.averagePaceSeconds, pace < 360 { return "최근 빠른 템포가 추진 잔상을 강하게 남겼습니다." }
            return "최근 보폭 패턴이 리듬 축을 조금씩 밀었습니다."
        }
    }

    private static func runtimeAura(for run: CompletedRunRecord) -> RunTimeAura {
        let hour = Calendar.current.component(.hour, from: run.startedAt)
        switch hour {
        case 5..<8: return .dawn
        case 8..<17: return .day
        case 17..<20: return .dusk
        default: return .night
        }
    }

    private static func routeShape(for route: [RoutePoint]) -> RouteShape {
        guard route.count >= 3,
              let first = route.first,
              let last = route.last else { return .freeform }

        let latitudeDelta = abs(first.latitude - last.latitude)
        let longitudeDelta = abs(first.longitude - last.longitude)
        if latitudeDelta < 0.0008 && longitudeDelta < 0.0008 { return .loop }
        if route.count < 12 { return .outAndBack }
        return .freeform
    }
}
