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

public struct RunWorldResolution: Equatable, Sendable {
    public let region: RegionPackEntry
    public let season: SeasonPackEntry?
    public let primaryEpisode: NarrativeEpisodeEntry?
    public let candidateEpisodes: [NarrativeEpisodeEntry]
    public let timeAura: RunTimeAura
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
        guard let resolution = resolve(for: run, pack: pack) else {
            return nil
        }

        return RunWorldProfile(
            regionTitle: resolution.region.title,
            seasonTitle: resolution.season?.title,
            summaryLine: resolution.region.narrativeSummary,
            episodeLine: resolution.primaryEpisode?.playerFacingText
        )
    }

    public static func resolve(for run: CompletedRunRecord, pack: WorldContentPack) -> RunWorldResolution? {
        guard let region = matchedRegion(for: run, pack: pack) else {
            return nil
        }

        let speciesID = canonicalSpeciesID(for: run.reward.pet.species)
        let season = matchedSeason(
            forRegionID: region.regionID,
            speciesID: speciesID,
            pack: pack
        )
        let candidateEpisodes = pack.narrativeEpisodes.filter { episode in
            episode.regionID == region.regionID &&
                (season == nil || episode.seasonID == season?.seasonID)
        }
        let primaryEpisode = candidateEpisodes.first { episode in
            episodeMatches(episode.triggerRules, run: run)
        }

        return RunWorldResolution(
            region: region,
            season: season,
            primaryEpisode: primaryEpisode,
            candidateEpisodes: candidateEpisodes,
            timeAura: inferredTimeAura(from: run.startedAt)
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

    private static func matchedSeason(
        forRegionID regionID: String,
        speciesID: String,
        pack: WorldContentPack
    ) -> SeasonPackEntry? {
        let candidates = pack.seasons.filter {
            $0.featuredRegionIDs.contains(regionID) || $0.featuredSpeciesIDs.contains(speciesID)
        }

        return candidates.sorted {
            let lhsRegionMatch = $0.featuredRegionIDs.contains(regionID)
            let rhsRegionMatch = $1.featuredRegionIDs.contains(regionID)
            if lhsRegionMatch != rhsRegionMatch { return lhsRegionMatch && !rhsRegionMatch }
            let lhsSpeciesMatch = $0.featuredSpeciesIDs.contains(speciesID)
            let rhsSpeciesMatch = $1.featuredSpeciesIDs.contains(speciesID)
            if lhsSpeciesMatch != rhsSpeciesMatch { return lhsSpeciesMatch && !rhsSpeciesMatch }
            if $0.featuredRegionIDs.count != $1.featuredRegionIDs.count {
                return $0.featuredRegionIDs.count < $1.featuredRegionIDs.count
            }
            if $0.featuredSpeciesIDs.count != $1.featuredSpeciesIDs.count {
                return $0.featuredSpeciesIDs.count < $1.featuredSpeciesIDs.count
            }
            return $0.seasonID < $1.seasonID
        }.first
    }

    static func inferredTimeAura(from date: Date) -> RunTimeAura {
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
            hookLine: "신더래시와 던스프리그의 황혼 분기에서 셰이드빗의 형태가 드러난다",
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
