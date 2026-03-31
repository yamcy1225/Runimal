import Foundation

public enum RunimalSpeciesRuleEngine {
    public static func dominantSpecies(for summary: RunSummary) -> PetSpecies {
        scoreTable(for: summary)
            .max(by: { $0.value < $1.value })?
            .key ?? .seedle
    }

    public static func scoreTable(for summary: RunSummary) -> [PetSpecies: Int] {
        let signature = RunMetricSignature(summary: summary)
        var scores = Dictionary(uniqueKeysWithValues: PetSpecies.allCases.map { ($0, 1) })

        applyDistance(signature.distanceBand, to: &scores)
        applyPace(signature.paceBand, to: &scores)
        applyCadence(signature.cadenceBand, to: &scores)
        applyElevation(signature.elevationBand, to: &scores)
        applyVariability(signature.variabilityBand, to: &scores)
        applyAura(summary.aura, to: &scores)
        applyShape(summary.shape, to: &scores)
        applyEnvironment(summary.environmentCondition, to: &scores)

        if summary.rareEventCompleted {
            scores[.sparkfang, default: 0] += 2
            scores[.shadebit, default: 0] += 1
        }

        // Beginner-friendly patterns should still resolve predictably even as other values are sparse.
        if signature.distanceBand == .short &&
            signature.paceBand == .recovery &&
            signature.cadenceBand == .low {
            scores[.seedle, default: 0] += 3
        }

        return scores
    }

    public static func shellBiasedScores(
        for eggShell: EggShellType,
        runs: [CompletedRunRecord]
    ) -> [PetSpecies: Int] {
        var scores = Dictionary(uniqueKeysWithValues: PetSpecies.allCases.map { ($0, 1) })

        applyShell(eggShell, to: &scores)

        for run in runs {
            let summary = summarize(run: run, cadenceFallback: 165)
            let runScores = scoreTable(for: summary)
            for (species, score) in runScores {
                scores[species, default: 0] += score
            }
        }

        return scores
    }

    public static func summarize(run: CompletedRunRecord, cadenceFallback: Int = 165) -> RunSummary {
        let paceSeconds = run.averagePaceSeconds ?? Int(
            (Double(max(run.durationSeconds, 1)) / max(run.distanceMeters / 1_000, 1)).rounded()
        )

        return RunSummary(
            distanceKm: run.distanceMeters / 1_000,
            averagePaceSeconds: paceSeconds,
            cadence: run.cadence ?? cadenceFallback,
            elevationGainM: run.elevationGainM,
            variability: routeVariability(for: run.route),
            aura: aura(for: run.startedAt),
            shape: shape(for: run.route),
            environmentCondition: run.environmentCondition,
            rareEventCompleted: run.rareEventCompleted
        )
    }

    public static func summarize(runs: [CompletedRunRecord], fallbackShell: EggShellType) -> RunSummary {
        guard runs.isEmpty == false else {
            return RunSummary(
                distanceKm: 3.0,
                averagePaceSeconds: 360,
                cadence: 164,
                elevationGainM: 12,
                variability: 0.12,
                aura: fallbackAura(for: fallbackShell),
                shape: .freeform
            )
        }

        let summaries = runs.map { summarize(run: $0) }
        let distanceKm = summaries.map(\.distanceKm).reduce(0, +) / Double(summaries.count)
        let pace = summaries.map(\.averagePaceSeconds).reduce(0, +) / summaries.count
        let cadence = summaries.map(\.cadence).reduce(0, +) / summaries.count
        let elevation = summaries.map(\.elevationGainM).reduce(0, +) / summaries.count
        let variability = summaries.map(\.variability).reduce(0, +) / Double(summaries.count)
        let shape = dominantShape(in: summaries)
        let environment = dominantEnvironment(in: summaries)

        return RunSummary(
            distanceKm: max(distanceKm, 1),
            averagePaceSeconds: max(pace, 280),
            cadence: max(cadence, 120),
            elevationGainM: max(elevation, 0),
            variability: min(max(variability, 0.04), 0.24),
            aura: summaries.last?.aura ?? fallbackAura(for: fallbackShell),
            shape: shape,
            environmentCondition: environment,
            rareEventCompleted: summaries.contains(where: \.rareEventCompleted)
        )
    }

    private static func applyShell(_ shell: EggShellType, to scores: inout [PetSpecies: Int]) {
        switch shell {
        case .ember:
            scores[.sparkfang, default: 0] += 6
            scores[.windrunner, default: 0] += 2
        case .gale:
            scores[.windrunner, default: 0] += 6
            scores[.mosshop, default: 0] += 1
        case .moss:
            scores[.mosshop, default: 0] += 5
            scores[.seedle, default: 0] += 2
        case .dusk:
            scores[.shadebit, default: 0] += 6
            scores[.mosshop, default: 0] += 1
        case .stone:
            scores[.stoneback, default: 0] += 6
            scores[.windrunner, default: 0] += 1
        }
    }

    private static func applyDistance(_ band: DistanceBand, to scores: inout [PetSpecies: Int]) {
        switch band {
        case .short:
            scores[.sparkfang, default: 0] += 3
            scores[.seedle, default: 0] += 3
        case .standard:
            scores[.mosshop, default: 0] += 3
            scores[.sparkfang, default: 0] += 1
            scores[.stoneback, default: 0] += 1
        case .long:
            scores[.windrunner, default: 0] += 4
            scores[.mosshop, default: 0] += 2
            scores[.stoneback, default: 0] += 1
        case .endurance:
            scores[.windrunner, default: 0] += 6
            scores[.stoneback, default: 0] += 2
        }
    }

    private static func applyPace(_ band: PaceBand, to scores: inout [PetSpecies: Int]) {
        switch band {
        case .recovery:
            scores[.seedle, default: 0] += 3
            scores[.mosshop, default: 0] += 2
            scores[.stoneback, default: 0] += 1
        case .steady:
            scores[.mosshop, default: 0] += 3
            scores[.windrunner, default: 0] += 2
        case .tempo:
            scores[.sparkfang, default: 0] += 3
            scores[.windrunner, default: 0] += 2
            scores[.shadebit, default: 0] += 1
        case .fast:
            scores[.sparkfang, default: 0] += 5
            scores[.windrunner, default: 0] += 1
        }
    }

    private static func applyCadence(_ band: CadenceBand, to scores: inout [PetSpecies: Int]) {
        switch band {
        case .low:
            scores[.stoneback, default: 0] += 3
            scores[.seedle, default: 0] += 2
        case .steady:
            scores[.mosshop, default: 0] += 2
            scores[.windrunner, default: 0] += 1
        case .quick:
            scores[.windrunner, default: 0] += 2
            scores[.sparkfang, default: 0] += 2
            scores[.mosshop, default: 0] += 1
        case .surge:
            scores[.sparkfang, default: 0] += 4
            scores[.shadebit, default: 0] += 1
        }
    }

    private static func applyElevation(_ band: ElevationBand, to scores: inout [PetSpecies: Int]) {
        switch band {
        case .flat:
            scores[.windrunner, default: 0] += 2
            scores[.sparkfang, default: 0] += 1
        case .rolling:
            scores[.stoneback, default: 0] += 2
            scores[.mosshop, default: 0] += 2
        case .climb:
            scores[.stoneback, default: 0] += 7
            scores[.windrunner, default: 0] += 1
        }
    }

    private static func applyVariability(_ band: VariabilityBand, to scores: inout [PetSpecies: Int]) {
        switch band {
        case .stable:
            scores[.windrunner, default: 0] += 3
            scores[.mosshop, default: 0] += 2
        case .adaptive:
            scores[.mosshop, default: 0] += 2
            scores[.seedle, default: 0] += 1
        case .chaotic:
            scores[.shadebit, default: 0] += 4
            scores[.sparkfang, default: 0] += 1
        }
    }

    private static func applyAura(_ aura: RunTimeAura, to scores: inout [PetSpecies: Int]) {
        switch aura {
        case .dawn:
            scores[.windrunner, default: 0] += 2
            scores[.seedle, default: 0] += 1
        case .day:
            scores[.sparkfang, default: 0] += 2
            scores[.windrunner, default: 0] += 1
        case .dusk:
            scores[.shadebit, default: 0] += 2
            scores[.mosshop, default: 0] += 1
        case .night:
            scores[.shadebit, default: 0] += 4
            scores[.mosshop, default: 0] += 1
        }
    }

    private static func applyShape(_ shape: RouteShape, to scores: inout [PetSpecies: Int]) {
        switch shape {
        case .loop:
            scores[.mosshop, default: 0] += 2
            scores[.shadebit, default: 0] += 2
        case .outAndBack:
            scores[.windrunner, default: 0] += 3
            scores[.stoneback, default: 0] += 2
        case .maze:
            scores[.shadebit, default: 0] += 3
            scores[.sparkfang, default: 0] += 1
        case .freeform:
            scores[.seedle, default: 0] += 2
            scores[.mosshop, default: 0] += 1
        }
    }

    private static func applyEnvironment(_ environment: EnvironmentCondition, to scores: inout [PetSpecies: Int]) {
        switch environment {
        case .clear:
            scores[.windrunner, default: 0] += 1
            scores[.sparkfang, default: 0] += 1
        case .rain:
            scores[.mosshop, default: 0] += 4
            scores[.seedle, default: 0] += 2
        case .snow:
            scores[.stoneback, default: 0] += 2
            scores[.shadebit, default: 0] += 2
        case .wind:
            scores[.windrunner, default: 0] += 3
            scores[.stoneback, default: 0] += 1
        case .heat:
            scores[.sparkfang, default: 0] += 3
        case .cold:
            scores[.stoneback, default: 0] += 4
            scores[.shadebit, default: 0] += 1
        case .overcast:
            scores[.mosshop, default: 0] += 1
            scores[.shadebit, default: 0] += 1
        case .unknown:
            scores[.seedle, default: 0] += 1
        }
    }

    private static func aura(for date: Date) -> RunTimeAura {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<11:
            return .dawn
        case 11..<17:
            return .day
        case 17..<21:
            return .dusk
        default:
            return .night
        }
    }

    private static func shape(for route: [RoutePoint]) -> RouteShape {
        guard route.count > 2, let first = route.first, let last = route.last else {
            return .freeform
        }

        let closureMeters = hypot(first.latitude - last.latitude, first.longitude - last.longitude) * 111_000
        if closureMeters < 120 {
            return .loop
        }
        if route.count >= 10 {
            return .outAndBack
        }
        return .freeform
    }

    private static func routeVariability(for route: [RoutePoint]) -> Double {
        guard route.count > 4 else { return 0.12 }

        let latitudes = route.map(\.latitude)
        let longitudes = route.map(\.longitude)
        let latSpan = (latitudes.max() ?? 0) - (latitudes.min() ?? 0)
        let lonSpan = (longitudes.max() ?? 0) - (longitudes.min() ?? 0)
        let spread = max(latSpan, lonSpan) * 111_000
        return min(max(spread / 5_000, 0.04), 0.24)
    }

    private static func dominantShape(in summaries: [RunSummary]) -> RouteShape {
        let counts = summaries.reduce(into: [RouteShape: Int]()) { partial, summary in
            partial[summary.shape, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? .freeform
    }

    private static func dominantEnvironment(in summaries: [RunSummary]) -> EnvironmentCondition {
        let counts = summaries.reduce(into: [EnvironmentCondition: Int]()) { partial, summary in
            partial[summary.environmentCondition, default: 0] += 1
        }
        return counts
            .filter { $0.key != .unknown }
            .max(by: { $0.value < $1.value })?
            .key ?? .unknown
    }

    private static func fallbackAura(for shell: EggShellType) -> RunTimeAura {
        switch shell {
        case .dusk: return .night
        case .moss: return .dusk
        default: return .day
        }
    }
}

private struct RunMetricSignature {
    let distanceBand: DistanceBand
    let paceBand: PaceBand
    let cadenceBand: CadenceBand
    let elevationBand: ElevationBand
    let variabilityBand: VariabilityBand

    init(summary: RunSummary) {
        distanceBand = DistanceBand(distanceKm: summary.distanceKm)
        paceBand = PaceBand(secondsPerKm: summary.averagePaceSeconds)
        cadenceBand = CadenceBand(cadence: summary.cadence)
        elevationBand = ElevationBand(elevationGainM: summary.elevationGainM)
        variabilityBand = VariabilityBand(variability: summary.variability)
    }
}

private enum DistanceBand {
    case short
    case standard
    case long
    case endurance

    init(distanceKm: Double) {
        switch distanceKm {
        case ..<4:
            self = .short
        case ..<8:
            self = .standard
        case ..<12:
            self = .long
        default:
            self = .endurance
        }
    }
}

private enum PaceBand {
    case recovery
    case steady
    case tempo
    case fast

    init(secondsPerKm: Int) {
        switch secondsPerKm {
        case ..<330:
            self = .fast
        case ..<390:
            self = .tempo
        case ..<480:
            self = .steady
        default:
            self = .recovery
        }
    }
}

private enum CadenceBand {
    case low
    case steady
    case quick
    case surge

    init(cadence: Int) {
        switch cadence {
        case ..<165:
            self = .low
        case ..<171:
            self = .steady
        case ..<176:
            self = .quick
        default:
            self = .surge
        }
    }
}

private enum ElevationBand {
    case flat
    case rolling
    case climb

    init(elevationGainM: Int) {
        switch elevationGainM {
        case ..<40:
            self = .flat
        case ..<120:
            self = .rolling
        default:
            self = .climb
        }
    }
}

private enum VariabilityBand {
    case stable
    case adaptive
    case chaotic

    init(variability: Double) {
        switch variability {
        case ..<0.10:
            self = .stable
        case ..<0.17:
            self = .adaptive
        default:
            self = .chaotic
        }
    }
}
