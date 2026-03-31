import Foundation

public struct CompanionWorldProfile: Equatable, Sendable {
    public let fantasyLine: String
    public let habitatLine: String
    public let hookLine: String
    public let mutationLine: String?
    public let variantLine: String?
}

public struct RunWorldProfile: Equatable, Sendable {
    public let regionTitle: String
    public let seasonTitle: String?
    public let summaryLine: String
    public let episodeLine: String?
}

public enum RunimalWorldContentEngine {
    public static func profile(for pet: GeneratedPet) -> CompanionWorldProfile? {
        profile(for: pet, pack: DefaultWorldContent.pack)
    }

    public static func profile(for pet: GeneratedPet, pack: WorldContentPack) -> CompanionWorldProfile? {
        if pet.species == .shadebit {
            return shadebitProfile(for: pet, pack: pack)
        }

        guard let speciesEntry = pack.speciesBible.first(where: { $0.speciesID == canonicalSpeciesID(for: pet.species) }) else {
            return nil
        }

        let families = pack.mutationFamilies
            .filter { speciesEntry.defaultMutationFamilyIDs.contains($0.familyID) }
            .map(\.branchName)

        let variantLine = pet.rareVariant.flatMap { variant in
            pack.rareVariants.first(where: { $0.variantID == variant.rawValue })
        }.map {
            "\($0.playerFacingName) · \($0.narrativeMeaning)"
        }

        return CompanionWorldProfile(
            fantasyLine: speciesEntry.fantasy,
            habitatLine: habitatSummary(for: speciesEntry),
            hookLine: speciesEntry.narrativeHooks.first ?? speciesEntry.fantasy,
            mutationLine: families.isEmpty ? nil : "변이 축 · " + families.joined(separator: " / "),
            variantLine: variantLine
        )
    }

    public static func profile(for run: CompletedRunRecord) -> RunWorldProfile? {
        profile(for: run, pack: DefaultWorldContent.pack)
    }

    public static func profile(for run: CompletedRunRecord, pack: WorldContentPack) -> RunWorldProfile? {
        guard let region = matchedRegion(for: run, pack: pack) else {
            return nil
        }

        let speciesID = canonicalSpeciesID(for: run.reward.pet.species)
        let season = pack.seasons.first { $0.featuredRegionIDs.contains(region.regionID) } ??
            pack.seasons.first { $0.featuredSpeciesIDs.contains(speciesID) }

        let episode = pack.narrativeEpisodes.first { episode in
            episode.regionID == region.regionID &&
            (season == nil || episode.seasonID == season?.seasonID) &&
            episodeMatches(episode.triggerRules, run: run)
        }

        return RunWorldProfile(
            regionTitle: region.title,
            seasonTitle: season?.title,
            summaryLine: region.narrativeSummary,
            episodeLine: episode?.playerFacingText
        )
    }

    private static func matchedRegion(for run: CompletedRunRecord, pack: WorldContentPack) -> RegionPackEntry? {
        let speciesID = canonicalSpeciesID(for: run.reward.pet.species)
        let environmentID = run.environmentCondition.rawValue
        let timeAura = inferredTimeAura(from: run.startedAt).rawValue

        return pack.regions.first { region in
            region.activeSpeciesIDs.contains(speciesID) &&
            (region.environmentBias.environmentConditions.contains(environmentID) ||
             region.environmentBias.environmentConditions.contains(EnvironmentCondition.unknown.rawValue) ||
             region.environmentBias.environmentConditions.isEmpty) &&
            (region.environmentBias.timeAuras.contains(timeAura) ||
             region.environmentBias.timeAuras.isEmpty)
        } ?? pack.regions.first { $0.activeSpeciesIDs.contains(speciesID) }
    }

    private static func episodeMatches(_ rules: EpisodeTriggerRules, run: CompletedRunRecord) -> Bool {
        if let completedRunsMin = rules.completedRunsMin, completedRunsMin > 1 {
            return false
        }
        if let distanceKmMin = rules.distanceKmMin, (run.distanceMeters / 1000) < distanceKmMin {
            return false
        }
        if let cadenceMin = rules.cadenceMin, (run.cadence ?? 0) < cadenceMin {
            return false
        }
        if let nightRunRequired = rules.nightRunRequired, nightRunRequired && inferredTimeAura(from: run.startedAt) != .night {
            return false
        }
        if let elevationGainMin = rules.elevationGainMin, run.elevationGainM < elevationGainMin {
            return false
        }
        return true
    }

    private static func inferredTimeAura(from date: Date) -> RunTimeAura {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<8:
            return .dawn
        case 8..<17:
            return .day
        case 17..<20:
            return .dusk
        default:
            return .night
        }
    }

    private static func habitatSummary(for speciesEntry: SpeciesBibleEntry) -> String {
        let tags = speciesEntry.habitatTags.prefix(3).map(localizedHabitatTag)
        guard tags.isEmpty == false else { return speciesEntry.fantasy }
        return tags.joined(separator: " · ") + "에서 강하게 반응"
    }

    private static func canonicalSpeciesID(for species: PetSpecies) -> String {
        switch species {
        case .shadebit:
            return PetSpecies.sparkfang.rawValue
        default:
            return species.rawValue
        }
    }

    private static func shadebitProfile(for pet: GeneratedPet, pack: WorldContentPack) -> CompanionWorldProfile? {
        let twilightFamilies = ["sparkfang-eclipse-twilight", "sparkfang-maze-route", "seedle-echo-bud"]
        let familyNames = pack.mutationFamilies
            .filter { twilightFamilies.contains($0.familyID) }
            .map(\.branchName)

        let variantLine = pet.rareVariant.flatMap { variant in
            pack.rareVariants.first(where: { $0.variantID == variant.rawValue })
        }.map {
            "\($0.playerFacingName) · \($0.narrativeMeaning)"
        }

        return CompanionWorldProfile(
            fantasyLine: "밤의 전류와 그림자 경로를 머금은 황혼 계열 form",
            habitatLine: "야간 구간 · 골목 · 터널에서 강하게 반응",
            hookLine: "Sparkfang과 Seedle의 황혼 분기에서 Shadebit form이 드러난다",
            mutationLine: familyNames.isEmpty ? nil : "황혼 축 · " + familyNames.joined(separator: " / "),
            variantLine: variantLine
        )
    }

    private static func localizedHabitatTag(_ tag: String) -> String {
        switch tag {
        case "urban": return "도심"
        case "riverside": return "강변"
        case "open-path": return "개활지"
        case "ridge": return "능선"
        case "stairs": return "계단"
        case "rock": return "암석 지대"
        case "city": return "시가지"
        case "sprint-lane": return "질주 코스"
        case "signal-zone": return "신호 지대"
        case "forest": return "숲길"
        case "park": return "공원"
        case "rain-trail": return "비 내린 트레일"
        case "night": return "야간 구간"
        case "alley": return "골목"
        case "tunnel": return "터널"
        case "starter": return "입문 구간"
        case "garden": return "정원권"
        case "everywhere": return "전 구역"
        default: return tag
        }
    }
}
