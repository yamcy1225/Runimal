import Foundation

public struct MutationUnlockProfile: Equatable, Sendable {
    public let runCount: Int
    public let totalDistanceKm: Double
    public let longestDistanceKm: Double
    public let averageDistanceKm: Double
    public let averagePaceSeconds: Int
    public let averageCadence: Int
    public let averageElevationGainM: Int
    public let averageVariability: Double
    public let rareEventCount: Int
    public let dominantAura: RunTimeAura
    public let dominantShape: RouteShape
    public let dominantEnvironment: EnvironmentCondition
    public let auraRatios: [RunTimeAura: Double]
    public let shapeRatios: [RouteShape: Double]
    public let environmentRatios: [EnvironmentCondition: Double]

    public var nightRatio: Double { auraRatios[.night, default: 0] }
    public var duskNightRatio: Double { auraRatios[.dusk, default: 0] + auraRatios[.night, default: 0] }
    public var loopRatio: Double { shapeRatios[.loop, default: 0] }
    public var outAndBackRatio: Double { shapeRatios[.outAndBack, default: 0] }
    public var mazeRatio: Double { shapeRatios[.maze, default: 0] }
    public var freeformRatio: Double { shapeRatios[.freeform, default: 0] }
    public var rainRatio: Double { environmentRatios[.rain, default: 0] }
    public var windRatio: Double { environmentRatios[.wind, default: 0] }
    public var coldRatio: Double { environmentRatios[.cold, default: 0] }
    public var heatRatio: Double { environmentRatios[.heat, default: 0] }

    public var averageDistanceBand: MutationDistanceBand {
        MutationDistanceBand(distanceKm: averageDistanceKm)
    }

    public var paceBand: MutationPaceBand {
        MutationPaceBand(secondsPerKm: averagePaceSeconds)
    }

    public var cadenceBand: MutationCadenceBand {
        MutationCadenceBand(cadence: averageCadence)
    }

    public var elevationBand: MutationElevationBand {
        MutationElevationBand(elevationGainM: averageElevationGainM)
    }
}

public struct MutationUnlockResult: Equatable, Sendable {
    public let speciesID: String
    public let bodyBranchID: String
    public let ecologyBranchID: String
    public let rhythmBranchID: String
    public let form: SpeciesFormBlueprint
    public let confidence: Double
    public let rationale: [SpeciesLineageAxis: String]

    public var snapshot: MutationFormSnapshot {
        MutationFormSnapshot(
            speciesID: speciesID,
            formID: form.formID,
            shortLabel: form.shortLabel,
            bodyBranchID: bodyBranchID,
            ecologyBranchID: ecologyBranchID,
            rhythmBranchID: rhythmBranchID,
            confidence: confidence
        )
    }
}

public enum SpeciesMutationUnlockEngine {
    public static func buildProfile(from runs: [CompletedRunRecord]) -> MutationUnlockProfile? {
        guard runs.isEmpty == false else { return nil }

        let summaries = runs.map { RunimalSpeciesRuleEngine.summarize(run: $0) }
        let runCount = summaries.count
        let totalDistance = summaries.map(\.distanceKm).reduce(0, +)
        let longestDistance = summaries.map(\.distanceKm).max() ?? 0
        let averageDistance = totalDistance / Double(runCount)
        let averagePace = summaries.map(\.averagePaceSeconds).reduce(0, +) / runCount
        let averageCadence = summaries.map(\.cadence).reduce(0, +) / runCount
        let averageElevation = summaries.map(\.elevationGainM).reduce(0, +) / runCount
        let averageVariability = summaries.map(\.variability).reduce(0, +) / Double(runCount)
        let rareEventCount = summaries.filter(\.rareEventCompleted).count

        return MutationUnlockProfile(
            runCount: runCount,
            totalDistanceKm: totalDistance,
            longestDistanceKm: longestDistance,
            averageDistanceKm: averageDistance,
            averagePaceSeconds: averagePace,
            averageCadence: averageCadence,
            averageElevationGainM: averageElevation,
            averageVariability: averageVariability,
            rareEventCount: rareEventCount,
            dominantAura: dominantKey(in: summaries.map(\.aura), fallback: .day),
            dominantShape: dominantKey(in: summaries.map(\.shape), fallback: .freeform),
            dominantEnvironment: dominantKey(in: summaries.map(\.environmentCondition), fallback: .unknown),
            auraRatios: ratios(in: summaries.map(\.aura), allCases: RunTimeAura.allCases),
            shapeRatios: ratios(in: summaries.map(\.shape), allCases: RouteShape.allCases),
            environmentRatios: ratios(in: summaries.map(\.environmentCondition), allCases: EnvironmentCondition.allCases)
        )
    }

    public static func resolveForm(
        for runs: [CompletedRunRecord],
        preferredSpecies: PetSpecies? = nil,
        blueprints: [SpeciesExpansionBlueprint] = DefaultSpeciesExpansionBlueprints.baseSpeciesBlueprints
    ) -> MutationUnlockResult? {
        guard let profile = buildProfile(from: runs) else { return nil }
        let summary = RunimalSpeciesRuleEngine.summarize(runs: runs, fallbackShell: .gale)
        let chosenSpecies = canonicalSpeciesID(for: preferredSpecies ?? RunimalSpeciesRuleEngine.dominantSpecies(for: summary))
        return resolveForm(speciesID: chosenSpecies, profile: profile, blueprints: blueprints)
    }

    public static func resolveForm(
        speciesID: String,
        profile: MutationUnlockProfile,
        blueprints: [SpeciesExpansionBlueprint] = DefaultSpeciesExpansionBlueprints.baseSpeciesBlueprints
    ) -> MutationUnlockResult? {
        guard let blueprint = blueprints.first(where: { $0.speciesID == speciesID }) else {
            return nil
        }

        let body = chooseBranch(from: blueprint.bodyBranches, speciesID: speciesID, profile: profile)
        let ecology = chooseBranch(from: blueprint.ecologyBranches, speciesID: speciesID, profile: profile)
        let rhythm = chooseBranch(from: blueprint.rhythmBranches, speciesID: speciesID, profile: profile)

        let formID = [speciesID, body.branch.id, ecology.branch.id, rhythm.branch.id].joined(separator: ".")
        let form = SpeciesFormBlueprint(
            formID: formID,
            speciesID: speciesID,
            displayName: blueprint.displayName,
            bodyBranchID: body.branch.id,
            ecologyBranchID: ecology.branch.id,
            rhythmBranchID: rhythm.branch.id,
            shortLabel: [body.branch.title, ecology.branch.title, rhythm.branch.title].joined(separator: " · ")
        )

        let totalScore = body.score + ecology.score + rhythm.score
        return MutationUnlockResult(
            speciesID: speciesID,
            bodyBranchID: body.branch.id,
            ecologyBranchID: ecology.branch.id,
            rhythmBranchID: rhythm.branch.id,
            form: form,
            confidence: min(Double(totalScore) / 24.0, 1.0),
            rationale: [
                .body: body.rationale,
                .ecology: ecology.rationale,
                .rhythm: rhythm.rationale,
            ]
        )
    }

    static func canonicalSpeciesID(for species: PetSpecies) -> String {
        switch species {
        case .shadebit:
            return PetSpecies.sparkfang.rawValue
        default:
            return species.rawValue
        }
    }

    private static func chooseBranch(
        from branches: [SpeciesLineageBranchBlueprint],
        speciesID: String,
        profile: MutationUnlockProfile
    ) -> (branch: SpeciesLineageBranchBlueprint, score: Int, rationale: String) {
        let ranked = branches.map { branch in
            let result = score(branchID: branch.id, speciesID: speciesID, profile: profile)
            return (branch, result.score, result.rationale)
        }

        return ranked.max(by: {
            if $0.1 == $1.1 {
                return $0.0.id > $1.0.id
            }
            return $0.1 < $1.1
        }) ?? (branches[0], 0, branches[0].unlockCue)
    }

    static func score(
        branchID: String,
        speciesID: String,
        profile: MutationUnlockProfile
    ) -> (score: Int, rationale: String) {
        switch (speciesID, branchID) {
        case ("windrunner", "aero-swift"):
            return score(profile, [
                (profile.averageDistanceKm >= 8, 3, "평균 거리"),
                (profile.averagePaceSeconds <= 390, 2, "순항 페이스"),
                (profile.averageCadence >= 170, 1, "가벼운 보폭"),
            ], fallback: "장거리 순항")
        case ("windrunner", "crest-guard"):
            return score(profile, [
                (profile.windRatio >= 0.34, 3, "강한 바람"),
                (profile.averageElevationGainM >= 70, 2, "저항 지형"),
                (profile.coldRatio >= 0.25, 1, "차가운 능선"),
            ], fallback: "바람 저항")
        case ("windrunner", "roam-wild"):
            return score(profile, [
                (profile.freeformRatio >= 0.34, 2, "자유 경로"),
                (profile.averageVariability >= 0.15, 2, "유동적인 루트"),
                (profile.longestDistanceKm >= 10, 1, "탐사 거리"),
            ], fallback: "자유 주행")

        case ("windrunner", "sky-urban"):
            return score(profile, [
                (profile.dominantEnvironment == .clear || profile.dominantEnvironment == .overcast, 2, "도심 컨디션"),
                (profile.loopRatio + profile.outAndBackRatio >= 0.5, 2, "도심형 코스"),
                (profile.averageDistanceBand != .endurance, 1, "생활권 거리"),
            ], fallback: "도심 장거리")
        case ("windrunner", "river-open"):
            return score(profile, [
                (profile.outAndBackRatio >= 0.33, 4, "왕복 항로"),
                (profile.averageDistanceKm >= 8, 3, "강변 장거리"),
            ], fallback: "리버사이드")
        case ("windrunner", "ridge-frontier"):
            return score(profile, [
                (profile.windRatio >= 0.25, 2, "바람 구역"),
                (profile.averageElevationGainM >= 80, 2, "능선 고도"),
                (profile.longestDistanceKm >= 10, 1, "탐사 루트"),
            ], fallback: "바람 구역")

        case ("windrunner", "cruise-loop"):
            return score(profile, [
                (profile.loopRatio >= 0.34, 3, "루프 반복"),
                (profile.averageVariability < 0.12, 2, "안정 리듬"),
            ], fallback: "일정 페이스")
        case ("windrunner", "draft-route"):
            return score(profile, [
                (profile.outAndBackRatio >= 0.33, 4, "왕복 리듬"),
                (profile.averagePaceSeconds <= 420, 2, "유지 페이스"),
            ], fallback: "out-and-back")
        case ("windrunner", "tailwind-pulse"):
            return score(profile, [
                (profile.averagePaceSeconds <= 360, 2, "빠른 순항"),
                (profile.totalDistanceKm >= 20, 2, "긴 누적"),
                (profile.averageCadence >= 172, 1, "경쾌한 후반"),
            ], fallback: "후반 유지")

        case ("stoneback", "ridge-guard"):
            return score(profile, [
                (profile.averageElevationGainM >= 100, 3, "언덕 지속"),
                (profile.totalDistanceKm >= 16, 1, "누적 버팀"),
            ], fallback: "언덕 지속")
        case ("stoneback", "summit-core"):
            return score(profile, [
                (profile.averageElevationGainM >= 140, 4, "정상 돌파"),
                (profile.coldRatio + profile.windRatio >= 0.4, 3, "험한 능선"),
            ], fallback: "고도 상승")
        case ("stoneback", "basalt-bulwark"):
            return score(profile, [
                (profile.averageCadence < 166, 2, "묵직한 보폭"),
                (profile.paceBand == .recovery || profile.paceBand == .steady, 2, "저속 유지"),
                (profile.averageDistanceKm >= 6, 1, "중거리 지구력"),
            ], fallback: "저케이던스")

        case ("stoneback", "fault-rock"):
            return score(profile, [
                (profile.mazeRatio + profile.freeformRatio >= 0.45, 2, "거친 지형"),
                (profile.averageElevationGainM >= 100, 2, "암반 고도"),
            ], fallback: "바위 지대")
        case ("stoneback", "cold-ridge"):
            return score(profile, [
                (profile.coldRatio >= 0.34, 4, "찬 공기"),
                (profile.averageElevationGainM >= 80, 1, "차가운 능선"),
            ], fallback: "cold run")
        case ("stoneback", "storm-slope"):
            return score(profile, [
                (profile.windRatio >= 0.34, 4, "강풍 언덕"),
                (profile.averageElevationGainM >= 90, 1, "경사 유지"),
            ], fallback: "wind climb")

        case ("stoneback", "climb-pulse"):
            return score(profile, [
                (profile.elevationBand == .climb, 5, "고도형 세션"),
                (profile.averageDistanceKm >= 6, 2, "오르막 누적"),
            ], fallback: "고도형 세션")
        case ("stoneback", "hold-line"):
            return score(profile, [
                (profile.averageVariability < 0.12, 3, "무너지지 않는 리듬"),
                (profile.paceBand == .steady || profile.paceBand == .recovery, 2, "버티는 페이스"),
            ], fallback: "꾸준한 유지")
        case ("stoneback", "anchor-step"):
            return score(profile, [
                (profile.averageCadence < 166, 3, "낮은 케이던스"),
                (profile.averageDistanceKm >= 5, 2, "무게 중심 유지"),
            ], fallback: "낮은 케이던스")

        case ("sparkfang", "burst-swift"):
            return score(profile, [
                (profile.averageDistanceKm < 5, 4, "짧은 세션"),
                (profile.averagePaceSeconds < 330, 3, "폭발 페이스"),
                (profile.averageCadence >= 176, 1, "경쾌한 폭발"),
            ], fallback: "짧고 빠른 세션")
        case ("sparkfang", "arc-raider"):
            return score(profile, [
                (profile.averageCadence >= 173, 2, "높은 케이던스"),
                (profile.outAndBackRatio + profile.freeformRatio >= 0.45, 2, "추격형 코스"),
                (profile.averageDistanceBand == .standard, 1, "중거리 인터벌"),
            ], fallback: "인터벌")
        case ("sparkfang", "flare-hunter"):
            return score(profile, [
                (profile.heatRatio >= 0.25, 2, "열기 세션"),
                (profile.rareEventCount > 0, 2, "돌발 이벤트"),
                (profile.averagePaceSeconds < 345, 1, "고강도 러닝"),
            ], fallback: "고강도 러닝")

        case ("sparkfang", "neon-urban"):
            return score(profile, [
                (profile.loopRatio + profile.outAndBackRatio >= 0.5, 2, "도심 코스"),
                (profile.dominantEnvironment == .clear || profile.dominantEnvironment == .overcast, 2, "도심 컨디션"),
                (profile.averageCadence >= 170, 1, "빠른 보폭"),
            ], fallback: "도심 인터벌")
        case ("sparkfang", "heat-lane"):
            return score(profile, [
                (profile.heatRatio >= 0.34, 4, "더운 날 러닝"),
            ], fallback: "더운 날 러닝")
        case ("sparkfang", "signal-track"):
            return score(profile, [
                (profile.mazeRatio >= 0.25 || profile.freeformRatio >= 0.25, 3, "변칙 코스"),
                (profile.averageVariability >= 0.15, 3, "가감속 리듬"),
                (profile.nightRatio >= 0.25, 2, "야간 신호 지대"),
            ], fallback: "가감속 코스")

        case ("sparkfang", "tempo-rush"):
            return score(profile, [
                (profile.paceBand == .tempo || profile.paceBand == .fast, 3, "빠른 템포"),
                (profile.averageDistanceKm <= 8, 1, "템포 적정 거리"),
            ], fallback: "tempo run")
        case ("sparkfang", "surge-fang"):
            return score(profile, [
                (profile.cadenceBand == .surge, 4, "고케이던스"),
                (profile.averagePaceSeconds < 360, 1, "급가속 페이스"),
            ], fallback: "고케이던스")
        case ("sparkfang", "shock-beat"):
            return score(profile, [
                (profile.rareEventCount > 0, 2, "이벤트 반응"),
                (profile.duskNightRatio >= 0.4, 2, "황혼 세션"),
                (profile.averageVariability >= 0.15, 1, "불규칙 리듬"),
            ], fallback: "돌발 이벤트")

        case ("mosshop", "canopy-guard"):
            return score(profile, [
                (profile.totalDistanceKm >= 20, 2, "긴 회복 주행"),
                (profile.averagePaceSeconds >= 390, 2, "느긋한 호흡"),
                (profile.averageVariability < 0.12, 1, "안정성"),
            ], fallback: "긴 회복 주행")
        case ("mosshop", "bloom-round"):
            return score(profile, [
                (profile.paceBand == .steady, 3, "편안한 러닝"),
                (profile.averageDistanceBand == .standard || profile.averageDistanceBand == .long, 1, "균형 거리"),
            ], fallback: "편안한 러닝")
        case ("mosshop", "dew-sleeper"):
            return score(profile, [
                (profile.paceBand == .recovery, 3, "낮은 강도"),
                (profile.averageCadence < 168, 1, "느린 리듬"),
                (profile.averageDistanceKm < 6, 1, "짧은 회복"),
            ], fallback: "낮은 강도")

        case ("mosshop", "rain-wildland"):
            return score(profile, [
                (profile.rainRatio >= 0.34, 4, "비 내린 러닝"),
            ], fallback: "rain run")
        case ("mosshop", "park-moss"):
            return score(profile, [
                (profile.loopRatio >= 0.34, 2, "공원 루프"),
                (profile.dominantEnvironment == .clear || profile.dominantEnvironment == .overcast, 2, "잔잔한 공원 컨디션"),
            ], fallback: "park route")
        case ("mosshop", "grove-rest"):
            return score(profile, [
                (profile.freeformRatio >= 0.25, 2, "회복 산책형"),
                (profile.paceBand == .recovery, 2, "쿨다운 리듬"),
                (profile.rainRatio >= 0.2 || profile.duskNightRatio >= 0.25, 1, "고요한 구간"),
            ], fallback: "cooldown run")

        case ("mosshop", "bloom-pulse"):
            return score(profile, [
                (profile.paceBand == .steady, 2, "안정 호흡"),
                (profile.averageVariability < 0.12, 2, "고른 리듬"),
            ], fallback: "steady breathing")
        case ("mosshop", "calm-loop"):
            return score(profile, [
                (profile.loopRatio >= 0.34, 3, "반복 루프"),
                (profile.averageVariability < 0.12, 1, "잔잔한 코스"),
            ], fallback: "loop course")
        case ("mosshop", "drift-heal"):
            return score(profile, [
                (profile.paceBand == .recovery, 3, "회복 페이스"),
                (profile.averageCadence < 168, 1, "느린 보폭"),
            ], fallback: "recovery pace")

        case ("seedle", "sprout-swift"):
            return score(profile, [
                (profile.averageDistanceKm < 4.5, 2, "첫 러닝 거리"),
                (profile.averageCadence >= 168, 2, "가벼운 발아 리듬"),
            ], fallback: "첫 러닝")
        case ("seedle", "root-guard"):
            return score(profile, [
                (profile.totalDistanceKm >= 14, 2, "누적 거리"),
                (profile.runCount >= 4, 2, "반복 축적"),
                (profile.averageVariability < 0.12, 1, "정착 패턴"),
            ], fallback: "누적 거리")
        case ("seedle", "bud-runner"):
            return score(profile, [
                (profile.duskNightRatio >= 0.4, 2, "황혼 적응"),
                (profile.paceBand == .tempo, 2, "입문 강화"),
            ], fallback: "입문 강화")

        case ("seedle", "garden-core"):
            return score(profile, [
                (profile.averageDistanceKm < 5, 2, "starter area"),
                (profile.dominantEnvironment == .clear || profile.dominantEnvironment == .overcast, 2, "정원권 날씨"),
            ], fallback: "starter area")
        case ("seedle", "everywhere-seed"):
            return score(profile, [
                (profile.runCount >= 4, 2, "범용 출현"),
                (profile.loopRatio < 0.5 && profile.outAndBackRatio < 0.5 && profile.freeformRatio < 0.5, 2, "고른 분포"),
            ], fallback: "범용 출현")
        case ("seedle", "twilight-bud"):
            return score(profile, [
                (profile.duskNightRatio >= 0.5, 6, "황혼 러닝"),
            ], fallback: "dusk run")

        case ("seedle", "first-step"):
            return score(profile, [
                (profile.runCount <= 2, 3, "초기 러닝"),
                (profile.averageDistanceKm < 4.5, 1, "탄생 거리"),
            ], fallback: "초기 러닝")
        case ("seedle", "steady-root"):
            return score(profile, [
                (profile.averageVariability < 0.12, 3, "낮은 변동성"),
                (profile.paceBand == .steady || profile.paceBand == .recovery, 1, "안정 적응"),
            ], fallback: "낮은 변동성")
        case ("seedle", "grow-loop"):
            return score(profile, [
                (profile.runCount >= 4, 2, "습관 누적"),
                (profile.totalDistanceKm >= 15, 2, "성장 누적"),
                (profile.loopRatio + profile.outAndBackRatio >= 0.5, 1, "habit loop"),
            ], fallback: "habit loop")

        default:
            return (0, "기본 해금")
        }
    }

    private static func score(
        _ profile: MutationUnlockProfile,
        _ rules: [(Bool, Int, String)],
        fallback: String
    ) -> (score: Int, rationale: String) {
        let matched = rules.filter(\.0)
        let score = max(matched.map(\.1).reduce(0, +), 1)
        let rationale = matched.map(\.2).joined(separator: " + ")
        return (score, rationale.isEmpty ? fallback : rationale)
    }

    private static func ratios<Key: Hashable & CaseIterable>(
        in values: [Key],
        allCases: Key.AllCases
    ) -> [Key: Double] where Key.AllCases: Collection {
        guard values.isEmpty == false else { return [:] }
        let counts = values.reduce(into: [Key: Int]()) { partial, value in
            partial[value, default: 0] += 1
        }
        let total = Double(values.count)
        return Dictionary(uniqueKeysWithValues: allCases.map { key in
            (key, Double(counts[key, default: 0]) / total)
        })
    }

    private static func dominantKey<Key: Hashable>(
        in values: [Key],
        fallback: Key
    ) -> Key {
        values.reduce(into: [Key: Int]()) { partial, value in
            partial[value, default: 0] += 1
        }
        .max(by: { $0.value < $1.value })?
        .key ?? fallback
    }
}

public enum MutationDistanceBand {
    case short
    case standard
    case long
    case endurance

    init(distanceKm: Double) {
        switch distanceKm {
        case ..<4: self = .short
        case ..<8: self = .standard
        case ..<12: self = .long
        default: self = .endurance
        }
    }
}

public enum MutationPaceBand {
    case recovery
    case steady
    case tempo
    case fast

    init(secondsPerKm: Int) {
        switch secondsPerKm {
        case ..<330: self = .fast
        case ..<390: self = .tempo
        case ..<480: self = .steady
        default: self = .recovery
        }
    }
}

public enum MutationCadenceBand {
    case low
    case steady
    case quick
    case surge

    init(cadence: Int) {
        switch cadence {
        case ..<165: self = .low
        case ..<171: self = .steady
        case ..<176: self = .quick
        default: self = .surge
        }
    }
}

public enum MutationElevationBand {
    case flat
    case rolling
    case climb

    init(elevationGainM: Int) {
        switch elevationGainM {
        case ..<40: self = .flat
        case ..<120: self = .rolling
        default: self = .climb
        }
    }
}
