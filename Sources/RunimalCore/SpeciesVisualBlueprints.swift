import Foundation

public struct CompanionPartFocus: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String

    public init(id: String, title: String, detail: String) {
        self.id = id
        self.title = title
        self.detail = detail
    }
}

public struct BranchVisualAnatomyBlueprint: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let axis: SpeciesLineageAxis
    public let developmentLine: String
    public let affectedParts: [CompanionPartFocus]
    public let pixelShiftTags: [String]

    public init(
        id: String,
        axis: SpeciesLineageAxis,
        developmentLine: String,
        affectedParts: [CompanionPartFocus],
        pixelShiftTags: [String]
    ) {
        self.id = id
        self.axis = axis
        self.developmentLine = developmentLine
        self.affectedParts = affectedParts
        self.pixelShiftTags = pixelShiftTags
    }
}

public struct BaseSpeciesVisualBlueprint: Codable, Equatable, Identifiable, Sendable {
    public let speciesID: String
    public let silhouetteLine: String
    public let identityLine: String
    public let signatureParts: [CompanionPartFocus]
    public let pixelShiftTags: [String]

    public var id: String { speciesID }

    public init(
        speciesID: String,
        silhouetteLine: String,
        identityLine: String,
        signatureParts: [CompanionPartFocus],
        pixelShiftTags: [String]
    ) {
        self.speciesID = speciesID
        self.silhouetteLine = silhouetteLine
        self.identityLine = identityLine
        self.signatureParts = signatureParts
        self.pixelShiftTags = pixelShiftTags
    }
}

public struct GrowthStageVisualBlueprint: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let speciesID: String
    public let stageIndex: Int
    public let stageTitle: String
    public let growthLine: String
    public let developedParts: [CompanionPartFocus]
    public let pixelShiftTags: [String]

    public init(
        id: String,
        speciesID: String,
        stageIndex: Int,
        stageTitle: String,
        growthLine: String,
        developedParts: [CompanionPartFocus],
        pixelShiftTags: [String]
    ) {
        self.id = id
        self.speciesID = speciesID
        self.stageIndex = stageIndex
        self.stageTitle = stageTitle
        self.growthLine = growthLine
        self.developedParts = developedParts
        self.pixelShiftTags = pixelShiftTags
    }
}

public struct PixelCoordinate: Codable, Equatable, Hashable, Sendable {
    public let x: Int
    public let y: Int

    public init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }
}

public struct PixelOverlayPhases: Equatable, Sendable {
    public let phaseOne: [PixelCoordinate]
    public let phaseTwo: [PixelCoordinate]
    public let phaseThree: [PixelCoordinate]

    public init(
        phaseOne: [PixelCoordinate],
        phaseTwo: [PixelCoordinate],
        phaseThree: [PixelCoordinate]
    ) {
        self.phaseOne = phaseOne
        self.phaseTwo = phaseTwo
        self.phaseThree = phaseThree
    }
}

public enum SpeciesVisualRenderProfile {
    public static func bodySpritePixels(for species: PetSpecies, stageIndex: Int?) -> [PixelCoordinate] {
        let resolvedSpecies = normalizedSpecies(for: species)

        if stageIndex == 3 {
            switch resolvedSpecies {
            case .windrunner:
                return pixels(
                    (4, 0), (5, 0),
                    (3, 1), (4, 1), (5, 1), (6, 1),
                    (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2),
                    (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3),
                    (1, 4), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4), (8, 4),
                    (2, 5), (3, 5), (4, 5), (5, 5), (6, 5), (7, 5),
                    (3, 6), (4, 6), (5, 6), (6, 6),
                    (3, 7), (6, 7)
                )
            case .stoneback:
                return pixels(
                    (4, 0), (5, 0),
                    (3, 1), (4, 1), (5, 1), (6, 1),
                    (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2),
                    (1, 3), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (8, 3),
                    (1, 4), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4), (8, 4),
                    (2, 5), (3, 5), (4, 5), (5, 5), (6, 5), (7, 5),
                    (2, 6), (3, 6), (4, 6), (5, 6), (6, 6), (7, 6),
                    (3, 7), (6, 7)
                )
            case .sparkfang:
                return pixels(
                    (3, 0), (6, 0),
                    (2, 1), (3, 1), (4, 1), (5, 1), (6, 1), (7, 1),
                    (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2),
                    (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3),
                    (1, 4), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4), (8, 4),
                    (2, 5), (3, 5), (4, 5), (5, 5), (6, 5), (7, 5),
                    (3, 6), (4, 6), (5, 6), (6, 6),
                    (2, 7), (7, 7)
                )
            case .mosshop:
                return pixels(
                    (4, 0), (5, 0),
                    (3, 1), (4, 1), (5, 1), (6, 1),
                    (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2),
                    (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3),
                    (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4),
                    (1, 5), (2, 5), (3, 5), (4, 5), (5, 5), (6, 5), (7, 5), (8, 5),
                    (2, 6), (3, 6), (4, 6), (5, 6), (6, 6), (7, 6),
                    (3, 7), (4, 7), (5, 7), (6, 7)
                )
            case .seedle:
                return pixels(
                    (4, 0),
                    (3, 1), (4, 1), (5, 1),
                    (2, 2), (3, 2), (4, 2), (5, 2), (6, 2),
                    (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3),
                    (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4),
                    (2, 5), (3, 5), (4, 5), (5, 5), (6, 5), (7, 5),
                    (3, 6), (4, 6), (5, 6), (6, 6),
                    (3, 7), (6, 7)
                )
            case .shadebit:
                return bodySpritePixels(for: .sparkfang, stageIndex: stageIndex)
            }
        }

        if stageIndex == 1 {
            switch resolvedSpecies {
            case .windrunner:
                return pixels(
                    (4, 0), (5, 0),
                    (3, 1), (4, 1), (5, 1), (6, 1),
                    (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2),
                    (3, 3), (4, 3), (5, 3), (6, 3),
                    (3, 4), (4, 4), (5, 4), (6, 4),
                    (4, 5), (5, 5),
                    (3, 6), (6, 6)
                )
            case .stoneback:
                return pixels(
                    (4, 0), (5, 0),
                    (3, 1), (4, 1), (5, 1), (6, 1),
                    (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2),
                    (3, 3), (4, 3), (5, 3), (6, 3),
                    (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4),
                    (3, 5), (4, 5), (5, 5), (6, 5),
                    (3, 6), (4, 6), (5, 6), (6, 6)
                )
            case .sparkfang:
                return pixels(
                    (3, 0), (6, 0),
                    (3, 1), (4, 1), (5, 1), (6, 1),
                    (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2),
                    (3, 3), (4, 3), (5, 3), (6, 3),
                    (3, 4), (4, 4), (5, 4), (6, 4),
                    (4, 5), (5, 5),
                    (3, 6), (6, 6)
                )
            case .mosshop:
                return pixels(
                    (4, 0), (5, 0),
                    (3, 1), (4, 1), (5, 1), (6, 1),
                    (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2),
                    (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3),
                    (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4),
                    (3, 5), (4, 5), (5, 5), (6, 5),
                    (4, 6), (5, 6)
                )
            case .seedle:
                return pixels(
                    (4, 0), (5, 0),
                    (3, 1), (4, 1), (5, 1), (6, 1),
                    (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2),
                    (3, 3), (4, 3), (5, 3), (6, 3),
                    (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4),
                    (3, 5), (4, 5), (5, 5), (6, 5),
                    (4, 6), (5, 6)
                )
            case .shadebit:
                return bodySpritePixels(for: .sparkfang, stageIndex: stageIndex)
            }
        }

        switch resolvedSpecies {
        case .windrunner:
            return pixels((4, 0), (5, 0), (3, 1), (4, 1), (5, 1), (6, 1), (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4), (3, 5), (4, 5), (5, 5), (6, 5), (4, 6), (5, 6), (3, 7), (6, 7))
        case .stoneback:
            return pixels((3, 1), (4, 1), (5, 1), (6, 1), (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4), (3, 5), (4, 5), (5, 5), (6, 5), (4, 6), (5, 6), (2, 6), (7, 6))
        case .sparkfang:
            return pixels((4, 0), (5, 0), (3, 1), (4, 1), (5, 1), (6, 1), (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2), (3, 3), (4, 3), (5, 3), (6, 3), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4), (3, 5), (4, 5), (5, 5), (6, 5), (4, 6), (5, 6), (2, 6), (7, 6))
        case .mosshop:
            return pixels((3, 1), (4, 1), (5, 1), (6, 1), (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4), (3, 5), (4, 5), (5, 5), (6, 5), (4, 6), (5, 6), (3, 0), (6, 0))
        case .shadebit:
            return pixels((4, 0), (5, 0), (3, 1), (4, 1), (5, 1), (6, 1), (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (3, 4), (4, 4), (5, 4), (6, 4), (4, 5), (5, 5), (3, 6), (6, 6), (2, 7), (7, 7))
        case .seedle:
            return pixels((4, 1), (5, 1), (3, 2), (4, 2), (5, 2), (6, 2), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4), (3, 5), (4, 5), (5, 5), (6, 5), (4, 6), (5, 6), (4, 0), (5, 0))
        }
    }

    public static func eyePixels(for species: PetSpecies, stageIndex: Int?) -> [PixelCoordinate] {
        if stageIndex == 1 {
            return pixels((3, 3), (6, 3))
        }

        return pixels((3, 3), (6, 3))
    }

    public static func faceAccentPixels(for species: PetSpecies, stageIndex: Int?) -> [PixelCoordinate] {
        let resolvedSpecies = normalizedSpecies(for: species)

        if stageIndex == 3 {
            switch resolvedSpecies {
            case .windrunner:
                return pixels((2, 5), (7, 5), (3, 6), (6, 6))
            case .stoneback:
                return pixels((2, 5), (3, 5), (6, 5), (7, 5), (3, 6), (4, 6), (5, 6), (6, 6))
            case .sparkfang:
                return pixels((2, 5), (7, 5), (3, 6), (6, 6))
            case .mosshop:
                return pixels((2, 4), (7, 4), (3, 5), (6, 5))
            case .seedle:
                return pixels((2, 5), (7, 5), (3, 6), (6, 6))
            case .shadebit:
                return faceAccentPixels(for: .sparkfang, stageIndex: stageIndex)
            }
        }

        guard stageIndex == 1 else { return [] }

        switch resolvedSpecies {
        case .windrunner:
            return pixels(
                (2, 3), (3, 3), (6, 3), (7, 3),
                (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4),
                (3, 5), (4, 5), (5, 5), (6, 5)
            )
        case .stoneback:
            return pixels(
                (2, 3), (3, 3), (6, 3), (7, 3),
                (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4),
                (2, 5), (3, 5), (4, 5), (5, 5), (6, 5), (7, 5)
            )
        case .sparkfang:
            return pixels(
                (2, 3), (7, 3),
                (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4),
                (3, 5), (6, 5)
            )
        case .mosshop:
            return pixels(
                (1, 3), (2, 3), (7, 3), (8, 3),
                (1, 4), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4), (8, 4),
                (3, 5), (4, 5), (5, 5), (6, 5)
            )
        case .seedle:
            return pixels(
                (3, 3), (6, 3),
                (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4),
                (4, 5), (5, 5)
            )
        case .shadebit:
            return faceAccentPixels(for: .sparkfang, stageIndex: stageIndex)
        }
    }

    public static func baseIdentityPixels(for species: PetSpecies, stageIndex: Int? = nil) -> [PixelCoordinate] {
        let resolvedSpecies = normalizedSpecies(for: species)

        if stageIndex == 3 {
            return []
        }

        if stageIndex == 1 {
            switch resolvedSpecies {
            case .windrunner:
                return []
            case .stoneback:
                return []
            case .sparkfang:
                return []
            case .mosshop:
                return []
            case .seedle:
                return []
            case .shadebit:
                return baseIdentityPixels(for: .sparkfang, stageIndex: stageIndex)
            }
        }

        let tags = Set(DefaultSpeciesVisualBlueprints.baseAnatomy(for: species)?.pixelShiftTags ?? [])

        if tags.contains("back_heavy") || tags.contains("shoulder_mass") {
            return pixels((2, 2), (7, 2), (2, 5), (7, 5), (4, 6), (5, 6))
        }
        if tags.contains("front_sharp") || tags.contains("signal_arc") {
            return pixels((4, 1), (5, 1), (2, 3), (7, 3), (3, 5), (6, 5))
        }
        if tags.contains("canopy_soft") || tags.contains("round_body") {
            return pixels((3, 1), (6, 1), (2, 2), (7, 2), (3, 5), (6, 5))
        }
        if tags.contains("bud_top") || tags.contains("seed_core") {
            return pixels((4, 1), (5, 1), (3, 3), (6, 3), (4, 5), (5, 5))
        }
        return pixels((4, 1), (5, 1), (2, 4), (7, 4), (3, 6), (6, 6))
    }

    public static func baseAccentPixels(for species: PetSpecies, stageIndex: Int? = nil) -> [PixelCoordinate] {
        let resolvedSpecies = normalizedSpecies(for: species)

        if stageIndex == 3 {
            switch resolvedSpecies {
            case .windrunner:
                return pixels((1, 5), (8, 5), (3, 8), (6, 8))
            case .stoneback:
                return pixels((1, 6), (2, 6), (7, 6), (8, 6), (3, 8), (6, 8))
            case .sparkfang:
                return pixels((1, 5), (2, 5), (7, 5), (8, 5), (2, 8), (7, 8))
            case .mosshop:
                return pixels((1, 6), (2, 6), (7, 6), (8, 6), (3, 8), (6, 8))
            case .seedle:
                return pixels((2, 6), (7, 6), (3, 8), (6, 8))
            case .shadebit:
                return baseAccentPixels(for: .sparkfang, stageIndex: stageIndex)
            }
        }

        if stageIndex == 1 {
            switch resolvedSpecies {
            case .windrunner:
                return pixels((3, 7), (6, 7))
            case .stoneback:
                return pixels((2, 7), (3, 7), (6, 7), (7, 7))
            case .sparkfang:
                return pixels((2, 2), (7, 2), (3, 7), (6, 7))
            case .mosshop:
                return pixels((4, 1), (5, 1), (3, 7), (6, 7))
            case .seedle:
                return pixels((4, 1), (5, 1), (4, 7), (5, 7))
            case .shadebit:
                return baseAccentPixels(for: .sparkfang, stageIndex: stageIndex)
            }
        }

        let tags = Set(DefaultSpeciesVisualBlueprints.baseAnatomy(for: species)?.pixelShiftTags ?? [])

        if tags.contains("crest_long") || tags.contains("tail_stream") {
            return pixels((4, 0), (5, 0), (3, 7), (6, 7))
        }
        if tags.contains("back_heavy") || tags.contains("tail_weight") {
            return pixels((3, 1), (6, 1), (2, 6), (7, 6))
        }
        if tags.contains("front_sharp") || tags.contains("tail_snap") {
            return pixels((3, 2), (6, 2), (2, 6), (7, 6))
        }
        if tags.contains("canopy_soft") || tags.contains("dew_tail") {
            return pixels((3, 0), (6, 0), (4, 7), (5, 7))
        }
        if tags.contains("bud_top") || tags.contains("sprout_tail") {
            return pixels((4, 0), (5, 0), (4, 7), (5, 7))
        }
        return []
    }

    public static func growthBodyPixels(for species: PetSpecies, stageIndex: Int?) -> [PixelCoordinate] {
        if stageIndex == 3 {
            return []
        }

        guard let stageIndex,
              let blueprint = DefaultSpeciesVisualBlueprints.growthStage(for: species, stageIndex: stageIndex) else {
            return []
        }
        let tags = Set(blueprint.pixelShiftTags)

        if tags.contains("egg_seed") {
            return pixels((4, 4), (5, 4))
        }
        if tags.contains("crest_seed") || tags.contains("bud_top") {
            return pixels((4, 1), (5, 1))
        }
        if tags.contains("shoulder_seed") || tags.contains("front_block") {
            return pixels((3, 2), (6, 2))
        }
        if tags.contains("wing_open") || tags.contains("sprout_side") || tags.contains("signal_arc") {
            return pixels((2, 4), (7, 4))
        }
        if tags.contains("back_rise") || tags.contains("weight_lock") || tags.contains("core_soft") {
            return pixels((3, 5), (6, 5))
        }
        if tags.contains("tail_stream") || tags.contains("tail_snap") || tags.contains("dew_tail") || tags.contains("sprout_tail") {
            return pixels((4, 7), (5, 7))
        }
        if tags.contains("prime_guard") || tags.contains("prime_back") {
            return pixels((2, 2), (7, 2), (3, 6), (6, 6))
        }
        if tags.contains("prime_fang") || tags.contains("prime_signal") {
            return pixels((3, 1), (6, 1), (2, 4), (7, 4))
        }
        if tags.contains("prime_canopy") || tags.contains("prime_dew") {
            return pixels((3, 1), (6, 1), (4, 6), (5, 6))
        }
        if tags.contains("prime_bud") || tags.contains("prime_sprout") || tags.contains("prime_long") || tags.contains("prime_tail") {
            return pixels((4, 1), (5, 1), (4, 7), (5, 7))
        }
        return []
    }

    public static func growthAccentPixels(for species: PetSpecies, stageIndex: Int?) -> [PixelCoordinate] {
        if stageIndex == 3 {
            return []
        }

        guard let stageIndex,
              let blueprint = DefaultSpeciesVisualBlueprints.growthStage(for: species, stageIndex: stageIndex) else {
            return []
        }
        let tags = Set(blueprint.pixelShiftTags)

        if tags.contains("egg_seed") {
            return []
        }
        if tags.contains("front_light") || tags.contains("signal_seed") || tags.contains("canopy_seed") {
            return pixels((3, 2), (6, 2))
        }
        if tags.contains("side_aero") || tags.contains("side_burst") || tags.contains("seed_align") {
            return pixels((1, 4), (8, 4))
        }
        if tags.contains("glide_frame") || tags.contains("tail_stream") || tags.contains("beat_tail") || tags.contains("habit_trace") {
            return pixels((3, 8), (6, 8))
        }
        if tags.contains("moss_edge") || tags.contains("rest_curve") || tags.contains("base_press") {
            return pixels((2, 6), (7, 6))
        }
        if tags.contains("prime_long") || tags.contains("prime_tail") {
            return pixels((3, 0), (6, 0), (2, 8), (7, 8))
        }
        if tags.contains("prime_guard") || tags.contains("prime_back") {
            return pixels((2, 1), (7, 1), (2, 7), (7, 7))
        }
        if tags.contains("prime_fang") || tags.contains("prime_signal") {
            return pixels((2, 3), (7, 3), (2, 6), (7, 6))
        }
        if tags.contains("prime_canopy") || tags.contains("prime_dew") {
            return pixels((3, 0), (6, 0), (4, 8), (5, 8))
        }
        if tags.contains("prime_bud") || tags.contains("prime_sprout") {
            return pixels((4, 0), (5, 0), (4, 8), (5, 8))
        }
        return []
    }

    public static func mutationBodyPhases(for branchID: String?) -> PixelOverlayPhases {
        let tags = Set(DefaultSpeciesVisualBlueprints.anatomy(for: branchID ?? "")?.pixelShiftTags ?? [])

        if tags.contains(where: { ["guard_shell", "back_ridge", "basalt_block", "root_back", "canopy_wide"].contains($0) }) {
            return PixelOverlayPhases(
                phaseOne: pixels((2, 6), (7, 6)),
                phaseTwo: pixels((3, 7), (6, 7)),
                phaseThree: pixels((2, 7), (7, 7))
            )
        }
        if tags.contains(where: { ["core_peak", "bloom_core", "leaf_guard"].contains($0) }) {
            return PixelOverlayPhases(
                phaseOne: pixels((4, 0), (5, 0)),
                phaseTwo: pixels((3, 1), (6, 1)),
                phaseThree: pixels((4, 1), (5, 1))
            )
        }
        return PixelOverlayPhases(
            phaseOne: pixels((2, 1), (7, 1)),
            phaseTwo: pixels((1, 2), (8, 2)),
            phaseThree: pixels((3, 0), (6, 0))
        )
    }

    public static func mutationEcologyPhases(for branchID: String?) -> PixelOverlayPhases {
        let tags = Set(DefaultSpeciesVisualBlueprints.anatomy(for: branchID ?? "")?.pixelShiftTags ?? [])

        if tags.contains(where: { ["river_fin", "open_flow", "adapt_edges"].contains($0) }) {
            return PixelOverlayPhases(
                phaseOne: pixels((1, 4), (8, 4)),
                phaseTwo: pixels((2, 5), (7, 5)),
                phaseThree: pixels((1, 5), (8, 5))
            )
        }
        if tags.contains(where: { ["storm_slash", "signal_noise", "twilight_glow", "shadow_mark"].contains($0) }) {
            return PixelOverlayPhases(
                phaseOne: pixels((1, 2), (8, 2)),
                phaseTwo: pixels((2, 2), (7, 2)),
                phaseThree: pixels((1, 1), (8, 1))
            )
        }
        return PixelOverlayPhases(
            phaseOne: pixels((2, 0), (7, 0)),
            phaseTwo: pixels((1, 1), (8, 1)),
            phaseThree: pixels((2, 1), (7, 1))
        )
    }

    public static func mutationRhythmPhases(for branchID: String?) -> PixelOverlayPhases {
        let tags = Set(DefaultSpeciesVisualBlueprints.anatomy(for: branchID ?? "")?.pixelShiftTags ?? [])

        if tags.contains(where: { ["loop_even", "calm_loop", "grow_loop", "habit_ring"].contains($0) }) {
            return PixelOverlayPhases(
                phaseOne: pixels((2, 6), (7, 6)),
                phaseTwo: pixels((3, 7), (6, 7)),
                phaseThree: pixels((4, 8), (5, 8))
            )
        }
        if tags.contains(where: { ["pulse_tail", "surge_tail", "shock_pulse", "bloom_breath"].contains($0) }) {
            return PixelOverlayPhases(
                phaseOne: pixels((1, 3), (8, 3)),
                phaseTwo: pixels((3, 8), (6, 8)),
                phaseThree: pixels((1, 4), (8, 4))
            )
        }
        return PixelOverlayPhases(
            phaseOne: pixels((2, 7), (7, 7)),
            phaseTwo: pixels((4, 8), (5, 8)),
            phaseThree: pixels((3, 8), (6, 8))
        )
    }

    public static func bodySignaturePixels(for branchID: String?) -> [PixelCoordinate] {
        let tags = Set(DefaultSpeciesVisualBlueprints.anatomy(for: branchID ?? "")?.pixelShiftTags ?? [])

        if tags.contains(where: { ["guard_shell", "back_ridge", "basalt_block", "root_back", "canopy_wide"].contains($0) }) {
            return pixels((2, 8), (7, 8))
        }
        if tags.contains(where: { ["core_peak", "bloom_core", "leaf_guard"].contains($0) }) {
            return pixels((4, 0), (5, 0), (4, 9), (5, 9))
        }
        return pixels((1, 1), (8, 1))
    }

    public static func ecologySignaturePixels(for branchID: String?) -> [PixelCoordinate] {
        let tags = Set(DefaultSpeciesVisualBlueprints.anatomy(for: branchID ?? "")?.pixelShiftTags ?? [])

        if tags.contains(where: { ["river_fin", "open_flow", "adapt_edges"].contains($0) }) {
            return pixels((0, 5), (9, 5))
        }
        if tags.contains(where: { ["storm_slash", "signal_noise", "twilight_glow", "shadow_mark"].contains($0) }) {
            return pixels((0, 2), (9, 2), (0, 3), (9, 3))
        }
        return pixels((2, 0), (7, 0), (1, 0), (8, 0))
    }

    public static func rhythmSignaturePixels(for branchID: String?) -> [PixelCoordinate] {
        let tags = Set(DefaultSpeciesVisualBlueprints.anatomy(for: branchID ?? "")?.pixelShiftTags ?? [])

        if tags.contains(where: { ["loop_even", "calm_loop", "grow_loop", "habit_ring"].contains($0) }) {
            return pixels((3, 9), (6, 9))
        }
        if tags.contains(where: { ["pulse_tail", "surge_tail", "shock_pulse", "bloom_breath"].contains($0) }) {
            return pixels((0, 4), (9, 4), (4, 9), (5, 9))
        }
        return pixels((2, 9), (7, 9), (4, 9), (5, 9))
    }

    private static func pixels(_ points: (Int, Int)...) -> [PixelCoordinate] {
        points.map(PixelCoordinate.init)
    }

    private static func normalizedSpecies(for species: PetSpecies) -> PetSpecies {
        switch species {
        case .shadebit:
            return .sparkfang
        default:
            return species
        }
    }
}

public enum DefaultSpeciesVisualBlueprints {
    public static let baseSpeciesBlueprints: [BaseSpeciesVisualBlueprint] = [
        base("windrunner", "상단 볏과 측면선이 길고 가볍게 열린 순항형 실루엣.", "머리 볏과 꼬리 흐름이 앞뒤로 길게 빠진다.", [.crest, .wingLine, .tailWave], ["crest_long", "side_aero", "tail_stream"]),
        base("stoneback", "등 라인과 어깨선이 넓고 낮게 깔린 방어형 실루엣.", "등갑과 상체 폭이 먼저 눈에 들어온다.", [.backShell, .shoulderLine, .upperSilhouette], ["back_heavy", "shoulder_mass", "tail_weight"]),
        base("sparkfang", "전면이 날카롭고 측면 신호가 튀는 추격형 실루엣.", "머리 끝과 바깥 신호선이 빠르게 반응한다.", [.crest, .eyeSignal, .tailWave], ["front_sharp", "signal_arc", "tail_snap"]),
        base("mosshop", "상체가 둥글고 상단 잎막이 퍼진 보호형 실루엣.", "코어 광과 잎막이 부드럽게 퍼진다.", [.upperSilhouette, .crest, .coreGlow], ["canopy_soft", "round_body", "dew_tail"]),
        base("seedle", "작고 단단한 코어에서 새싹선이 위로 돋는 발아형 실루엣.", "상단 새싹과 중심 코어가 먼저 보인다.", [.crest, .coreGlow, .tailWave], ["bud_top", "seed_core", "sprout_tail"]),
    ]

    public static let branchBlueprints: [BranchVisualAnatomyBlueprint] = [
        branch("aero-swift", .body, "장거리 순항형 체형. 전방 실루엣이 얇고 길게 열린다.", [.crest, .wingLine, .upperSilhouette], ["crest_long", "wing_thin"]),
        branch("crest-guard", .body, "바람 저항형 체형. 머리 볏과 등 라인이 단단하게 굳는다.", [.crest, .backShell, .shoulderLine], ["crest_guard", "back_ridge"]),
        branch("roam-wild", .body, "탐사형 체형. 측면 돌출과 자유로운 몸선이 강해진다.", [.wingLine, .upperSilhouette, .tailWave], ["wing_wild", "tail_loose"]),
        branch("sky-urban", .ecology, "도심 기류 적응. 상부 외곽선과 반사 표식이 선명해진다.", [.outerMarkings, .eyeSignal, .coreGlow], ["urban_glint", "signal_edge"]),
        branch("river-open", .ecology, "강변 개활지 적응. 측면 핀과 좌우 흐름이 넓게 열린다.", [.wingLine, .outerMarkings, .tailWave], ["river_fin", "open_flow"]),
        branch("ridge-frontier", .ecology, "능선 바람길 적응. 외곽 표식이 위쪽으로 치솟는다.", [.outerMarkings, .crest, .coreGlow], ["ridge_trace", "crest_frontier"]),
        branch("cruise-loop", .rhythm, "안정 루프 리듬. 하단 파동이 일정하게 반복된다.", [.tailWave, .motionTrail, .coreGlow], ["loop_even", "trail_soft"]),
        branch("draft-route", .rhythm, "왕복 항로 리듬. 꼬리 파동이 뒤로 길게 남는다.", [.tailWave, .motionTrail, .wingLine], ["route_tail", "trail_long"]),
        branch("tailwind-pulse", .rhythm, "후반 가속 리듬. 뒤쪽 추진선이 점점 강해진다.", [.tailWave, .motionTrail, .eyeSignal], ["pulse_tail", "rear_push"]),

        branch("ridge-guard", .body, "능선 방어형 체형. 등갑과 어깨선이 넓고 무겁게 자란다.", [.backShell, .shoulderLine, .upperSilhouette], ["guard_shell", "shoulder_wide"]),
        branch("summit-core", .body, "정상 돌파형 체형. 중심 코어와 상체가 위로 솟는다.", [.coreGlow, .crest, .upperSilhouette], ["core_peak", "crest_spire"]),
        branch("basalt-bulwark", .body, "현무암 방벽형 체형. 하체와 등 라인이 짧고 단단해진다.", [.backShell, .shoulderLine, .tailWave], ["basalt_block", "tail_weight"]),
        branch("fault-rock", .ecology, "암석 지형 적응. 외곽 문양이 돌층처럼 끊겨 붙는다.", [.outerMarkings, .backShell, .coreGlow], ["fault_cracks", "stone_marks"]),
        branch("cold-ridge", .ecology, "찬 공기 능선 적응. 상단 표식과 코어 광이 차갑게 응결된다.", [.coreGlow, .eyeSignal, .outerMarkings], ["cold_glow", "ridge_frost"]),
        branch("storm-slope", .ecology, "강풍 언덕 적응. 측면 신호와 외곽선이 사선으로 갈라진다.", [.wingLine, .outerMarkings, .eyeSignal], ["storm_slash", "wind_edge"]),
        branch("climb-pulse", .rhythm, "오르막 리듬. 하단 추진선이 짧고 무겁게 반복된다.", [.tailWave, .motionTrail, .shoulderLine], ["climb_steps", "push_heavy"]),
        branch("hold-line", .rhythm, "유지 리듬. 보폭 잔상이 끊기지 않고 길게 이어진다.", [.motionTrail, .tailWave, .coreGlow], ["hold_line", "trail_dense"]),
        branch("anchor-step", .rhythm, "묵직한 보폭 리듬. 꼬리보다 하체 잔상이 강조된다.", [.motionTrail, .tailWave, .backShell], ["anchor_stride", "tail_short"]),

        branch("burst-swift", .body, "폭발 질주형 체형. 전면 실루엣이 날카롭게 쏠린다.", [.crest, .upperSilhouette, .wingLine], ["burst_front", "crest_sharp"]),
        branch("arc-raider", .body, "짧은 추격형 체형. 측면 곡선과 어깨가 앞으로 당겨진다.", [.shoulderLine, .wingLine, .tailWave], ["arc_shoulder", "tail_snap"]),
        branch("flare-hunter", .body, "사냥형 체형. 머리와 꼬리 끝이 뾰족하게 발달한다.", [.crest, .tailWave, .eyeSignal], ["flare_fangs", "tail_spike"]),
        branch("neon-urban", .ecology, "네온 도심 적응. 눈가 신호와 외곽선이 강하게 점등된다.", [.eyeSignal, .outerMarkings, .coreGlow], ["neon_sign", "urban_glow"]),
        branch("heat-lane", .ecology, "열기 구간 적응. 코어 광과 측면 핀이 뜨겁게 번진다.", [.coreGlow, .wingLine, .outerMarkings], ["heat_core", "lane_flare"]),
        branch("signal-track", .ecology, "신호 코스 적응. 표식과 점멸선이 불규칙하게 붙는다.", [.eyeSignal, .outerMarkings, .motionTrail], ["signal_noise", "track_glitch"]),
        branch("tempo-rush", .rhythm, "템포 리듬. 하단 추진선이 일정 간격으로 뛴다.", [.tailWave, .motionTrail, .coreGlow], ["tempo_ticks", "rush_trail"]),
        branch("surge-fang", .rhythm, "급가속 리듬. 꼬리와 잔상이 짧고 강하게 튄다.", [.tailWave, .motionTrail, .eyeSignal], ["surge_tail", "fang_flash"]),
        branch("shock-beat", .rhythm, "충격 리듬. 측면 신호와 하단 파동이 번개처럼 분절된다.", [.eyeSignal, .tailWave, .motionTrail], ["shock_pulse", "beat_split"]),

        branch("canopy-guard", .body, "보호형 체형. 상체와 상단 잎막이 넓게 펼쳐진다.", [.upperSilhouette, .backShell, .crest], ["canopy_wide", "leaf_guard"]),
        branch("bloom-round", .body, "둥근 생장형 체형. 몸통과 코어가 부드럽게 부풀어 오른다.", [.upperSilhouette, .coreGlow, .backShell], ["round_body", "bloom_core"]),
        branch("dew-sleeper", .body, "회복형 체형. 몸선이 낮고 포근하게 가라앉는다.", [.backShell, .tailWave, .coreGlow], ["dew_drop", "sleep_curve"]),
        branch("rain-wildland", .ecology, "비와 숲길 적응. 물방울 문양과 이끼 외곽이 번진다.", [.outerMarkings, .coreGlow, .wingLine], ["rain_marks", "moss_edge"]),
        branch("park-moss", .ecology, "공원 생태 적응. 상단 잎 장식과 부드러운 가장자리가 자란다.", [.crest, .outerMarkings, .coreGlow], ["park_leaf", "moss_soft"]),
        branch("grove-rest", .ecology, "회복 숲 적응. 외곽 문양이 둥글게 감싸며 안정화된다.", [.outerMarkings, .backShell, .eyeSignal], ["grove_ring", "rest_mark"]),
        branch("bloom-pulse", .rhythm, "호흡 리듬. 하단 파동이 짧은 호흡처럼 반복된다.", [.tailWave, .motionTrail, .coreGlow], ["bloom_breath", "pulse_soft"]),
        branch("calm-loop", .rhythm, "반복 안정 리듬. 보폭 잔상이 작은 고리로 고정된다.", [.motionTrail, .tailWave, .outerMarkings], ["calm_loop", "trail_round"]),
        branch("drift-heal", .rhythm, "회복 리듬. 꼬리 파동이 느리고 길게 풀린다.", [.tailWave, .motionTrail, .coreGlow], ["drift_tail", "heal_echo"]),

        branch("sprout-swift", .body, "가벼운 발아형 체형. 새싹 볏과 가는 측면선이 먼저 자란다.", [.crest, .wingLine, .upperSilhouette], ["sprout_crest", "seed_light"]),
        branch("root-guard", .body, "정착 성장형 체형. 등 라인과 하체 중심이 두터워진다.", [.backShell, .shoulderLine, .coreGlow], ["root_back", "guard_core"]),
        branch("bud-runner", .body, "질주 발아형 체형. 전면 실루엣과 꼬리가 활짝 열린다.", [.upperSilhouette, .tailWave, .crest], ["bud_front", "runner_tail"]),
        branch("garden-core", .ecology, "정원권 생태. 코어 광과 상단 잎무늬가 차분히 자란다.", [.coreGlow, .crest, .outerMarkings], ["garden_core", "leaf_marks"]),
        branch("everywhere-seed", .ecology, "전 구역 적응. 외곽선이 균형 있게 퍼지며 범용 표식이 붙는다.", [.outerMarkings, .wingLine, .eyeSignal], ["seed_balance", "adapt_edges"]),
        branch("twilight-bud", .ecology, "황혼 적응. 코어 광이 어둡게 번지고 그림자 표식이 붙는다.", [.coreGlow, .outerMarkings, .eyeSignal], ["twilight_glow", "shadow_mark"]),
        branch("first-step", .rhythm, "탄생 리듬. 작은 꼬리 파동이 천천히 생긴다.", [.tailWave, .motionTrail, .coreGlow], ["first_step", "small_pulse"]),
        branch("steady-root", .rhythm, "기초 적응 리듬. 잔상이 짧고 안정적으로 정렬된다.", [.motionTrail, .tailWave, .backShell], ["steady_root", "trail_align"]),
        branch("grow-loop", .rhythm, "습관 누적 리듬. 꼬리와 하단 잔상이 작은 고리로 축적된다.", [.tailWave, .motionTrail, .outerMarkings], ["grow_loop", "habit_ring"]),
    ]

    public static let growthStageBlueprints: [GrowthStageVisualBlueprint] = [
        growth("windrunner", 0, "알", "상단 볏의 씨앗과 꼬리 흐름의 시작점만 남아 있다.", [.crest, .tailWave], ["egg_seed"]),
        growth("windrunner", 1, "유아기", "머리가 먼저 커지고 볼선이 둥글게 퍼지며 바람 볏은 짧은 솜털처럼만 남는다.", [.crest, .upperSilhouette], ["baby_round", "baby_cheeks", "baby_tuft"]),
        growth("windrunner", 2, "유년기", "측면 핀이 열리며 몸선이 좌우로 넓게 퍼진다.", [.wingLine, .upperSilhouette], ["wing_open", "side_aero"]),
        growth("windrunner", 3, "동행 완성", "꼬리 흐름이 길어지고 순항 자세가 고정된다.", [.tailWave, .wingLine], ["tail_stream", "glide_frame"]),
        growth("windrunner", 4, "고유형", "상단 볏, 측면선, 꼬리 흐름이 모두 이어져 장거리 실루엣이 완성된다.", [.crest, .wingLine, .tailWave], ["prime_long", "prime_tail"]),

        growth("stoneback", 0, "알", "등의 중심점만 단단하게 응축된 초기 형태다.", [.backShell], ["egg_seed"]),
        growth("stoneback", 1, "유아기", "돌처럼 단단한 등 대신 넓은 이마와 통통한 볼이 먼저 잡히며 짧은 다리로 버틴다.", [.shoulderLine, .upperSilhouette], ["baby_round", "baby_cheeks", "baby_stable"]),
        growth("stoneback", 2, "유년기", "등 라인이 두꺼워지며 후면 무게중심이 잡힌다.", [.backShell, .shoulderLine], ["back_rise", "weight_lock"]),
        growth("stoneback", 3, "동행 완성", "하부와 꼬리 뒤축이 묵직하게 눌리며 버팀형 자세가 완성된다.", [.tailWave, .backShell], ["tail_weight", "base_press"]),
        growth("stoneback", 4, "고유형", "넓은 등과 어깨선이 완전히 연결되어 방어형 골격이 굳어진다.", [.backShell, .shoulderLine, .upperSilhouette], ["prime_guard", "prime_back"]),

        growth("sparkfang", 0, "알", "전면 끝과 코어 신호가 아주 작게만 살아 있다.", [.eyeSignal], ["egg_seed"]),
        growth("sparkfang", 1, "유아기", "날카로운 앞선은 접히고, 장난기 있는 귀선과 큰 눈이 먼저 살아나는 개구진 얼굴이 된다.", [.crest, .eyeSignal], ["baby_round", "baby_cheeks", "baby_prank"]),
        growth("sparkfang", 2, "유년기", "측면 반응선이 번쩍이며 짧은 추격 실루엣이 굳는다.", [.wingLine, .eyeSignal], ["signal_arc", "side_burst"]),
        growth("sparkfang", 3, "동행 완성", "꼬리 끝이 짧고 강하게 튀며 스냅이 생긴다.", [.tailWave, .motionTrail], ["tail_snap", "beat_tail"]),
        growth("sparkfang", 4, "고유형", "전면 날과 신호선, 꼬리 스냅이 하나의 추격형 인상으로 묶인다.", [.crest, .eyeSignal, .tailWave], ["prime_fang", "prime_signal"]),

        growth("mosshop", 0, "알", "상단 잎막의 흔적과 작은 코어 광만 드러난다.", [.crest, .coreGlow], ["egg_seed"]),
        growth("mosshop", 1, "유아기", "둥근 몸통 위에 작은 잎모자만 얹힌 채, 포근한 볼과 배가 먼저 부풀어 오른다.", [.upperSilhouette, .crest], ["baby_round", "baby_cheeks", "baby_leaf"]),
        growth("mosshop", 2, "유년기", "코어 광이 안정되고 외곽이 포근하게 감싸기 시작한다.", [.coreGlow, .outerMarkings], ["core_soft", "moss_edge"]),
        growth("mosshop", 3, "동행 완성", "꼬리 끝과 하부 곡선이 느리게 풀리며 회복형 자세가 된다.", [.tailWave, .backShell], ["dew_tail", "rest_curve"]),
        growth("mosshop", 4, "고유형", "잎막, 둥근 몸선, 코어 광이 한 덩어리의 보호형 인상으로 정리된다.", [.crest, .coreGlow, .upperSilhouette], ["prime_canopy", "prime_dew"]),

        growth("seedle", 0, "알", "중심 코어에 새싹점만 맺힌 발아 직전 형태다.", [.coreGlow], ["egg_seed"]),
        growth("seedle", 1, "유아기", "씨앗 같은 몸통이 통통하게 열리고, 작은 새싹 하나가 머리 위에서 장난스럽게 흔들린다.", [.crest, .coreGlow], ["baby_round", "baby_cheeks", "baby_sprout"]),
        growth("seedle", 2, "유년기", "몸선이 작게 정렬되고 측면선이 가볍게 붙는다.", [.upperSilhouette, .wingLine], ["sprout_side", "seed_align"]),
        growth("seedle", 3, "동행 완성", "가느다란 꼬리선과 습관 흔적이 아래로 길게 남는다.", [.tailWave, .motionTrail], ["sprout_tail", "habit_trace"]),
        growth("seedle", 4, "고유형", "새싹, 코어, 꼬리선이 모두 이어져 발아형 기본 골격이 완성된다.", [.crest, .coreGlow, .tailWave], ["prime_bud", "prime_sprout"]),
    ]

    public static func anatomy(for branchID: String) -> BranchVisualAnatomyBlueprint? {
        branchBlueprints.first(where: { $0.id == branchID })
    }

    public static func anatomy(for form: MutationFormSnapshot) -> [BranchVisualAnatomyBlueprint] {
        [form.bodyBranchID, form.ecologyBranchID, form.rhythmBranchID]
            .compactMap(anatomy(for:))
    }

    public static func baseAnatomy(for species: PetSpecies) -> BaseSpeciesVisualBlueprint? {
        let speciesID: String
        switch species {
        case .shadebit:
            speciesID = PetSpecies.sparkfang.rawValue
        default:
            speciesID = species.rawValue
        }
        return baseSpeciesBlueprints.first { $0.speciesID == speciesID }
    }

    public static func growthStage(for species: PetSpecies, stageIndex: Int) -> GrowthStageVisualBlueprint? {
        let speciesID = baseAnatomy(for: species)?.speciesID ?? species.rawValue
        return growthStageBlueprints.first { $0.speciesID == speciesID && $0.stageIndex == stageIndex }
    }

    private static func branch(
        _ id: String,
        _ axis: SpeciesLineageAxis,
        _ developmentLine: String,
        _ affectedParts: [CompanionPartFocus],
        _ pixelShiftTags: [String]
    ) -> BranchVisualAnatomyBlueprint {
        BranchVisualAnatomyBlueprint(
            id: id,
            axis: axis,
            developmentLine: developmentLine,
            affectedParts: affectedParts,
            pixelShiftTags: pixelShiftTags
        )
    }

    private static func base(
        _ speciesID: String,
        _ silhouetteLine: String,
        _ identityLine: String,
        _ signatureParts: [CompanionPartFocus],
        _ pixelShiftTags: [String]
    ) -> BaseSpeciesVisualBlueprint {
        BaseSpeciesVisualBlueprint(
            speciesID: speciesID,
            silhouetteLine: silhouetteLine,
            identityLine: identityLine,
            signatureParts: signatureParts,
            pixelShiftTags: pixelShiftTags
        )
    }

    private static func growth(
        _ speciesID: String,
        _ stageIndex: Int,
        _ stageTitle: String,
        _ growthLine: String,
        _ developedParts: [CompanionPartFocus],
        _ pixelShiftTags: [String]
    ) -> GrowthStageVisualBlueprint {
        GrowthStageVisualBlueprint(
            id: "\(speciesID)-stage-\(stageIndex)",
            speciesID: speciesID,
            stageIndex: stageIndex,
            stageTitle: stageTitle,
            growthLine: growthLine,
            developedParts: developedParts,
            pixelShiftTags: pixelShiftTags
        )
    }
}

private extension CompanionPartFocus {
    static let crest = CompanionPartFocus(id: "head-crest", title: "머리 볏", detail: "전방 인상과 상단 실루엣을 바꾼다.")
    static let eyeSignal = CompanionPartFocus(id: "eye-signal", title: "눈가 신호", detail: "시선과 반응성을 드러내는 점멸 부위다.")
    static let upperSilhouette = CompanionPartFocus(id: "upper-silhouette", title: "상체 실루엣", detail: "몸의 전면 윤곽과 자세를 결정한다.")
    static let backShell = CompanionPartFocus(id: "back-shell", title: "등 라인", detail: "등갑과 후면 무게중심을 바꾼다.")
    static let shoulderLine = CompanionPartFocus(id: "shoulder-line", title: "어깨선", detail: "상체 폭과 방어형 인상을 만든다.")
    static let wingLine = CompanionPartFocus(id: "wing-line", title: "측면 핀", detail: "날개선이나 옆으로 뻗는 파츠를 만든다.")
    static let outerMarkings = CompanionPartFocus(id: "outer-markings", title: "외곽 문양", detail: "서식지와 환경 적응 흔적을 만든다.")
    static let coreGlow = CompanionPartFocus(id: "core-glow", title: "코어 광", detail: "중심 에너지와 내부 발광을 나타낸다.")
    static let tailWave = CompanionPartFocus(id: "tail-wave", title: "꼬리 파동", detail: "후면 리듬과 추진 잔상을 만든다.")
    static let motionTrail = CompanionPartFocus(id: "motion-trail", title: "이동 잔상", detail: "보폭과 리듬의 흔적을 남긴다.")
}
