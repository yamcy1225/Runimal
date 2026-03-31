import Foundation

public enum SpeciesLineageAxis: String, Codable, CaseIterable, Sendable {
    case body
    case ecology
    case rhythm
}

public struct SpeciesLineageBranchBlueprint: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let axis: SpeciesLineageAxis
    public let title: String
    public let theme: String
    public let unlockCue: String

    public init(
        id: String,
        axis: SpeciesLineageAxis,
        title: String,
        theme: String,
        unlockCue: String
    ) {
        self.id = id
        self.axis = axis
        self.title = title
        self.theme = theme
        self.unlockCue = unlockCue
    }
}

public struct SpeciesExpansionBlueprint: Codable, Equatable, Identifiable, Sendable {
    public let speciesID: String
    public let displayName: String
    public let fantasyLine: String
    public let bodyBranches: [SpeciesLineageBranchBlueprint]
    public let ecologyBranches: [SpeciesLineageBranchBlueprint]
    public let rhythmBranches: [SpeciesLineageBranchBlueprint]

    public var id: String { speciesID }

    public init(
        speciesID: String,
        displayName: String,
        fantasyLine: String,
        bodyBranches: [SpeciesLineageBranchBlueprint],
        ecologyBranches: [SpeciesLineageBranchBlueprint],
        rhythmBranches: [SpeciesLineageBranchBlueprint]
    ) {
        self.speciesID = speciesID
        self.displayName = displayName
        self.fantasyLine = fantasyLine
        self.bodyBranches = bodyBranches
        self.ecologyBranches = ecologyBranches
        self.rhythmBranches = rhythmBranches
    }
}

public struct SpeciesFormBlueprint: Codable, Equatable, Identifiable, Sendable {
    public let formID: String
    public let speciesID: String
    public let displayName: String
    public let bodyBranchID: String
    public let ecologyBranchID: String
    public let rhythmBranchID: String
    public let shortLabel: String

    public var id: String { formID }

    public init(
        formID: String,
        speciesID: String,
        displayName: String,
        bodyBranchID: String,
        ecologyBranchID: String,
        rhythmBranchID: String,
        shortLabel: String
    ) {
        self.formID = formID
        self.speciesID = speciesID
        self.displayName = displayName
        self.bodyBranchID = bodyBranchID
        self.ecologyBranchID = ecologyBranchID
        self.rhythmBranchID = rhythmBranchID
        self.shortLabel = shortLabel
    }
}

public struct LaunchRosterEntry: Codable, Equatable, Identifiable, Sendable {
    public let formID: String
    public let releaseTier: String
    public let unlockTrack: String

    public var id: String { formID }

    public init(formID: String, releaseTier: String, unlockTrack: String) {
        self.formID = formID
        self.releaseTier = releaseTier
        self.unlockTrack = unlockTrack
    }
}

public enum SpeciesExpansionEngine {
    public static func expandedForms(
        for blueprint: SpeciesExpansionBlueprint
    ) -> [SpeciesFormBlueprint] {
        blueprint.bodyBranches.flatMap { body in
            blueprint.ecologyBranches.flatMap { ecology in
                blueprint.rhythmBranches.map { rhythm in
                    SpeciesFormBlueprint(
                        formID: [
                            blueprint.speciesID,
                            body.id,
                            ecology.id,
                            rhythm.id,
                        ].joined(separator: "."),
                        speciesID: blueprint.speciesID,
                        displayName: blueprint.displayName,
                        bodyBranchID: body.id,
                        ecologyBranchID: ecology.id,
                        rhythmBranchID: rhythm.id,
                        shortLabel: [
                            body.title,
                            ecology.title,
                            rhythm.title,
                        ].joined(separator: " · ")
                    )
                }
            }
        }
    }

    public static func maxFormCount(
        for blueprints: [SpeciesExpansionBlueprint]
    ) -> Int {
        blueprints
            .map { $0.bodyBranches.count * $0.ecologyBranches.count * $0.rhythmBranches.count }
            .reduce(0, +)
    }
}
