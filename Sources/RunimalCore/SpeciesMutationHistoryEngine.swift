import Foundation

public struct MutationAxisHistory: Equatable, Identifiable, Sendable {
    public let axis: SpeciesLineageAxis
    public let currentBranchID: String
    public let currentTitle: String
    public let currentScore: Int
    public let currentProgress: Double
    public let unlockedBranchIDs: [String]
    public let unlockedTitles: [String]
    public let branches: [MutationBranchProgressSnapshot]

    public var id: SpeciesLineageAxis { axis }
}

public struct MutationHistorySnapshot: Equatable, Sendable {
    public let speciesID: String
    public let runCount: Int
    public let currentForm: MutationFormSnapshot
    public let unlockedForms: [MutationFormSnapshot]
    public let axes: [MutationAxisHistory]

    public var latestUnlockedDisplayTitle: String {
        unlockedForms.last?.displayTitle ?? currentForm.displayTitle
    }
}

public enum SpeciesMutationHistoryEngine {
    public static func history(
        for runs: [CompletedRunRecord],
        preferredSpecies: PetSpecies? = nil,
        blueprints: [SpeciesExpansionBlueprint] = DefaultSpeciesExpansionBlueprints.baseSpeciesBlueprints
    ) -> MutationHistorySnapshot? {
        let sortedRuns = runs.sorted { $0.endedAt < $1.endedAt }
        guard sortedRuns.isEmpty == false,
              let current = SpeciesMutationUnlockEngine.resolveForm(
                for: sortedRuns,
                preferredSpecies: preferredSpecies,
                blueprints: blueprints
              ) else {
            return nil
        }

        let unlockedForms = resolvedForms(
            for: sortedRuns,
            preferredSpecies: preferredSpecies,
            blueprints: blueprints
        )

        return MutationHistorySnapshot(
            speciesID: current.speciesID,
            runCount: sortedRuns.count,
            currentForm: current.snapshot,
            unlockedForms: unlockedForms,
            axes: axisHistory(
                runs: sortedRuns,
                current: current.snapshot,
                unlockedForms: unlockedForms,
                blueprints: blueprints
            )
        )
    }

    private static func resolvedForms(
        for runs: [CompletedRunRecord],
        preferredSpecies: PetSpecies?,
        blueprints: [SpeciesExpansionBlueprint]
    ) -> [MutationFormSnapshot] {
        var snapshots: [MutationFormSnapshot] = []
        var seenFormIDs = Set<String>()

        for count in 1...runs.count {
            guard let snapshot = SpeciesMutationUnlockEngine.resolveForm(
                for: Array(runs.prefix(count)),
                preferredSpecies: preferredSpecies,
                blueprints: blueprints
            )?.snapshot else {
                continue
            }

            if seenFormIDs.insert(snapshot.formID).inserted {
                snapshots.append(snapshot)
            }
        }

        return snapshots
    }

    private static func axisHistory(
        runs: [CompletedRunRecord],
        current: MutationFormSnapshot,
        unlockedForms: [MutationFormSnapshot],
        blueprints: [SpeciesExpansionBlueprint]
    ) -> [MutationAxisHistory] {
        let progressByAxis = accumulatedBranchScores(
            runs: runs,
            speciesID: current.speciesID,
            blueprints: blueprints
        )

        return [
            axisHistory(
                axis: .body,
                currentBranchID: current.bodyBranchID,
                unlockedBranchIDs: uniqueBranchIDs(from: unlockedForms.map(\.bodyBranchID)),
                speciesID: current.speciesID,
                progressByAxis: progressByAxis[.body] ?? [:],
                blueprints: blueprints
            ),
            axisHistory(
                axis: .ecology,
                currentBranchID: current.ecologyBranchID,
                unlockedBranchIDs: uniqueBranchIDs(from: unlockedForms.map(\.ecologyBranchID)),
                speciesID: current.speciesID,
                progressByAxis: progressByAxis[.ecology] ?? [:],
                blueprints: blueprints
            ),
            axisHistory(
                axis: .rhythm,
                currentBranchID: current.rhythmBranchID,
                unlockedBranchIDs: uniqueBranchIDs(from: unlockedForms.map(\.rhythmBranchID)),
                speciesID: current.speciesID,
                progressByAxis: progressByAxis[.rhythm] ?? [:],
                blueprints: blueprints
            ),
        ]
    }

    private static func axisHistory(
        axis: SpeciesLineageAxis,
        currentBranchID: String,
        unlockedBranchIDs: [String],
        speciesID: String,
        progressByAxis: [String: Int],
        blueprints: [SpeciesExpansionBlueprint]
    ) -> MutationAxisHistory {
        let orderedBranches = orderedBranches(for: axis, speciesID: speciesID, blueprints: blueprints)
        let totalScore = max(progressByAxis.values.reduce(0, +), 1)
        let branches = orderedBranches.map { branch in
            let score = progressByAxis[branch.id, default: 0]
            return MutationBranchProgressSnapshot(
                branchID: branch.id,
                title: branch.title,
                totalScore: score,
                progress: Double(score) / Double(totalScore),
                isCurrent: branch.id == currentBranchID,
                isUnlocked: unlockedBranchIDs.contains(branch.id)
            )
        }

        return MutationAxisHistory(
            axis: axis,
            currentBranchID: currentBranchID,
            currentTitle: branchTitle(
                branchID: currentBranchID,
                speciesID: speciesID,
                blueprints: blueprints
            ),
            currentScore: progressByAxis[currentBranchID, default: 0],
            currentProgress: Double(progressByAxis[currentBranchID, default: 0]) / Double(totalScore),
            unlockedBranchIDs: unlockedBranchIDs,
            unlockedTitles: unlockedBranchIDs.map {
                branchTitle(branchID: $0, speciesID: speciesID, blueprints: blueprints)
            },
            branches: branches
        )
    }

    private static func accumulatedBranchScores(
        runs: [CompletedRunRecord],
        speciesID: String,
        blueprints: [SpeciesExpansionBlueprint]
    ) -> [SpeciesLineageAxis: [String: Int]] {
        var scores: [SpeciesLineageAxis: [String: Int]] = [:]

        for run in runs {
            guard let profile = SpeciesMutationUnlockEngine.buildProfile(from: [run]) else { continue }

            for axis in SpeciesLineageAxis.allCases {
                let branchScores = SpeciesMutationContributionEngine.branchScores(
                    for: axis,
                    speciesID: speciesID,
                    profile: profile,
                    blueprints: blueprints
                )
                for branch in branchScores {
                    scores[axis, default: [:]][branch.branchID, default: 0] += branch.score
                }
            }
        }

        return scores
    }

    private static func uniqueBranchIDs(from branchIDs: [String]) -> [String] {
        var seen = Set<String>()
        return branchIDs.filter { seen.insert($0).inserted }
    }

    private static func branchTitle(
        branchID: String,
        speciesID: String,
        blueprints: [SpeciesExpansionBlueprint]
    ) -> String {
        guard let blueprint = blueprints.first(where: { $0.speciesID == speciesID }) else {
            return fallbackTitle(for: branchID)
        }

        let branch = (
            blueprint.bodyBranches +
            blueprint.ecologyBranches +
            blueprint.rhythmBranches
        ).first(where: { $0.id == branchID })

        return branch?.title ?? fallbackTitle(for: branchID)
    }

    private static func orderedBranches(
        for axis: SpeciesLineageAxis,
        speciesID: String,
        blueprints: [SpeciesExpansionBlueprint]
    ) -> [SpeciesLineageBranchBlueprint] {
        guard let blueprint = blueprints.first(where: { $0.speciesID == speciesID }) else {
            return []
        }

        switch axis {
        case .body:
            return blueprint.bodyBranches
        case .ecology:
            return blueprint.ecologyBranches
        case .rhythm:
            return blueprint.rhythmBranches
        }
    }

    private static func fallbackTitle(for branchID: String) -> String {
        branchID
            .split(separator: "-")
            .map(\.capitalized)
            .joined(separator: " ")
    }
}
