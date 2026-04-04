import Foundation

public struct MutationBranchBridgeSnapshot: Equatable, Identifiable, Sendable {
    public let axis: SpeciesLineageAxis
    public let branchID: String
    public let branchTitle: String
    public let startStageIndex: Int
    public let startStageTitle: String
    public let inheritedParts: [CompanionPartFocus]
    public let redirectedParts: [CompanionPartFocus]

    public var id: SpeciesLineageAxis { axis }
}

public enum SpeciesGrowthMutationBridgeEngine {
    public static func bridge(
        for species: PetSpecies,
        form: MutationFormSnapshot?
    ) -> [MutationBranchBridgeSnapshot] {
        guard let form else { return [] }

        return [
            bridgeEntry(axis: .body, species: species, branchID: form.bodyBranchID, branchTitle: form.shortLabel),
            bridgeEntry(axis: .ecology, species: species, branchID: form.ecologyBranchID, branchTitle: form.shortLabel),
            bridgeEntry(axis: .rhythm, species: species, branchID: form.rhythmBranchID, branchTitle: form.shortLabel),
        ].compactMap { $0 }
    }

    public static func bridge(
        for species: PetSpecies,
        axis: SpeciesLineageAxis,
        branchID: String
    ) -> MutationBranchBridgeSnapshot? {
        let branchTitle = branchTitle(for: species, axis: axis, branchID: branchID) ?? branchID
        return bridgeEntry(axis: axis, species: species, branchID: branchID, branchTitle: branchTitle)
    }

    private static func bridgeEntry(
        axis: SpeciesLineageAxis,
        species: PetSpecies,
        branchID: String,
        branchTitle: String
    ) -> MutationBranchBridgeSnapshot? {
        guard let anatomy = DefaultSpeciesVisualBlueprints.anatomy(for: branchID) else { return nil }

        let growthStages = (0...4).compactMap { DefaultSpeciesVisualBlueprints.growthStage(for: species, stageIndex: $0) }
        let affectedPartIDs = Set(anatomy.affectedParts.map(\.id))
        let activeStages = Array(growthStages.dropFirst())

        let matchedStage = activeStages.first { stage in
            stage.developedParts.contains { affectedPartIDs.contains($0.id) }
        } ?? growthStages[min(defaultStageIndex(for: axis), max(0, growthStages.count - 1))]

        let inheritedParts = matchedStage.developedParts.filter { affectedPartIDs.contains($0.id) }
        let redirectedParts = anatomy.affectedParts.filter { part in
            inheritedParts.contains(where: { $0.id == part.id }) == false
        }

        return MutationBranchBridgeSnapshot(
            axis: axis,
            branchID: branchID,
            branchTitle: branchTitle,
            startStageIndex: matchedStage.stageIndex,
            startStageTitle: matchedStage.stageTitle,
            inheritedParts: inheritedParts,
            redirectedParts: redirectedParts
        )
    }

    private static func defaultStageIndex(for axis: SpeciesLineageAxis) -> Int {
        switch axis {
        case .body:
            return 1
        case .ecology:
            return 2
        case .rhythm:
            return 3
        }
    }

    private static func branchTitle(
        for species: PetSpecies,
        axis: SpeciesLineageAxis,
        branchID: String
    ) -> String? {
        let canonicalID = SpeciesMutationUnlockEngine.canonicalSpeciesID(for: species)
        guard let blueprint = DefaultSpeciesExpansionBlueprints.baseSpeciesBlueprints.first(where: { $0.speciesID == canonicalID }) else {
            return nil
        }

        let branches: [SpeciesLineageBranchBlueprint]
        switch axis {
        case .body:
            branches = blueprint.bodyBranches
        case .ecology:
            branches = blueprint.ecologyBranches
        case .rhythm:
            branches = blueprint.rhythmBranches
        }

        return branches.first(where: { $0.id == branchID })?.title
    }
}
