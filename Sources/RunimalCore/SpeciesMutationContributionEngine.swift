import Foundation

public struct MutationAxisContributionSnapshot: Codable, Equatable, Identifiable, Sendable {
    public let axis: SpeciesLineageAxis
    public let branchID: String
    public let branchTitle: String
    public let score: Int
    public let progress: Double

    public var id: SpeciesLineageAxis { axis }

    public init(
        axis: SpeciesLineageAxis,
        branchID: String,
        branchTitle: String,
        score: Int,
        progress: Double
    ) {
        self.axis = axis
        self.branchID = branchID
        self.branchTitle = branchTitle
        self.score = score
        self.progress = progress
    }
}

public struct MutationRunContributionSnapshot: Codable, Equatable, Sendable {
    public let speciesID: String
    public let axes: [MutationAxisContributionSnapshot]

    public init(speciesID: String, axes: [MutationAxisContributionSnapshot]) {
        self.speciesID = speciesID
        self.axes = axes
    }
}

public struct MutationBranchProgressSnapshot: Equatable, Identifiable, Sendable {
    public let branchID: String
    public let title: String
    public let totalScore: Int
    public let progress: Double
    public let isCurrent: Bool
    public let isUnlocked: Bool

    public var id: String { branchID }
}

public enum SpeciesMutationContributionEngine {
    public static func runContribution(
        for run: CompletedRunRecord,
        preferredSpecies: PetSpecies? = nil,
        blueprints: [SpeciesExpansionBlueprint] = DefaultSpeciesExpansionBlueprints.baseSpeciesBlueprints
    ) -> MutationRunContributionSnapshot? {
        guard let profile = SpeciesMutationUnlockEngine.buildProfile(from: [run]) else { return nil }
        let speciesID = SpeciesMutationUnlockEngine.canonicalSpeciesID(
            for: preferredSpecies ?? run.reward.pet.species
        )
        return runContribution(speciesID: speciesID, profile: profile, blueprints: blueprints)
    }

    public static func runContribution(
        speciesID: String,
        profile: MutationUnlockProfile,
        blueprints: [SpeciesExpansionBlueprint] = DefaultSpeciesExpansionBlueprints.baseSpeciesBlueprints
    ) -> MutationRunContributionSnapshot? {
        guard blueprints.contains(where: { $0.speciesID == speciesID }) else { return nil }

        return MutationRunContributionSnapshot(
            speciesID: speciesID,
            axes: SpeciesLineageAxis.allCases.compactMap {
                topContribution(for: $0, speciesID: speciesID, profile: profile, blueprints: blueprints)
            }
        )
    }

    static func branchScores(
        for axis: SpeciesLineageAxis,
        speciesID: String,
        profile: MutationUnlockProfile,
        blueprints: [SpeciesExpansionBlueprint]
    ) -> [MutationAxisContributionSnapshot] {
        guard let blueprint = blueprints.first(where: { $0.speciesID == speciesID }) else { return [] }

        let branches: [SpeciesLineageBranchBlueprint]
        switch axis {
        case .body:
            branches = blueprint.bodyBranches
        case .ecology:
            branches = blueprint.ecologyBranches
        case .rhythm:
            branches = blueprint.rhythmBranches
        }

        let scored = branches.map { branch in
            let result = SpeciesMutationUnlockEngine.score(
                branchID: branch.id,
                speciesID: speciesID,
                profile: profile
            )
            return (
                branchID: branch.id,
                branchTitle: branch.title,
                score: result.score
            )
        }

        let totalScore = max(scored.map(\.score).reduce(0, +), 1)
        return scored.map {
            MutationAxisContributionSnapshot(
                axis: axis,
                branchID: $0.branchID,
                branchTitle: $0.branchTitle,
                score: $0.score,
                progress: Double($0.score) / Double(totalScore)
            )
        }
    }

    private static func topContribution(
        for axis: SpeciesLineageAxis,
        speciesID: String,
        profile: MutationUnlockProfile,
        blueprints: [SpeciesExpansionBlueprint]
    ) -> MutationAxisContributionSnapshot? {
        branchScores(
            for: axis,
            speciesID: speciesID,
            profile: profile,
            blueprints: blueprints
        )
        .max(by: {
            if $0.score == $1.score {
                return $0.branchID > $1.branchID
            }
            return $0.score < $1.score
        })
    }
}
