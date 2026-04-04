import Foundation

public enum WorldContentPackComposer {
    public static func merge(_ packs: [WorldContentPack]) -> WorldContentPack? {
        guard packs.isEmpty == false else { return nil }

        let orderedPacks = packs.sorted { lhs, rhs in
            sortKey(for: lhs) < sortKey(for: rhs)
        }

        let speciesBible = mergeSpeciesBible(orderedPacks.flatMap(\.speciesBible))
        let mutationFamilies = mergeEntries(orderedPacks.flatMap(\.mutationFamilies), by: \.familyID)
        let rareVariants = mergeEntries(orderedPacks.flatMap(\.rareVariants), by: \.variantID)
        let regions = mergeEntries(orderedPacks.flatMap(\.regions), by: \.regionID)
        let seasons = mergeEntries(orderedPacks.flatMap(\.seasons), by: \.seasonID)
        let narrativeEpisodes = mergeEntries(orderedPacks.flatMap(\.narrativeEpisodes), by: \.episodeID)

        let packIDs = orderedPacks.map(\.contentPack.packID)

        return WorldContentPack(
            schemaVersion: orderedPacks.map(\.schemaVersion).max() ?? "0.1.0",
            project: orderedPacks.last?.project ?? "RunimalWorld",
            description: orderedPacks.map(\.description).joined(separator: " + "),
            contentPack: ContentPackSummary(
                packID: packIDs.joined(separator: "+"),
                title: orderedPacks.count == 1 ? (orderedPacks.first?.contentPack.title ?? "Runimal World") : "Runimal World Collection",
                type: orderedPacks.count == 1 ? (orderedPacks.first?.contentPack.type ?? "expansion") : "bundle",
                status: orderedPacks.allSatisfy { $0.contentPack.status == "live" } ? "live" : "active",
                playerFacingTheme: mergeLines(orderedPacks.map(\.contentPack.playerFacingTheme), limit: 2),
                featuredRegionIDs: uniqueValues(orderedPacks.flatMap(\.contentPack.featuredRegionIDs)),
                featuredSpeciesIDs: uniqueValues(orderedPacks.flatMap(\.contentPack.featuredSpeciesIDs)),
                featuredVariantIDs: uniqueValues(orderedPacks.flatMap(\.contentPack.featuredVariantIDs)),
                episodeIDs: uniqueValues(orderedPacks.flatMap(\.contentPack.episodeIDs))
            ),
            speciesBible: speciesBible,
            mutationFamilies: mutationFamilies,
            rareVariants: rareVariants,
            regions: regions,
            seasons: seasons,
            narrativeEpisodes: narrativeEpisodes
        )
    }

    private static func mergeEntries<T>(_ entries: [T], by keyPath: KeyPath<T, String>) -> [T] {
        var orderedKeys: [String] = []
        var lookup: [String: T] = [:]

        for entry in entries {
            let key = entry[keyPath: keyPath]
            if lookup[key] == nil {
                orderedKeys.append(key)
            }
            lookup[key] = entry
        }

        return orderedKeys.compactMap { lookup[$0] }
    }

    private static func mergeSpeciesBible(_ entries: [SpeciesBibleEntry]) -> [SpeciesBibleEntry] {
        var orderedKeys: [String] = []
        var lookup: [String: SpeciesBibleEntry] = [:]

        for entry in entries {
            if let current = lookup[entry.speciesID] {
                lookup[entry.speciesID] = SpeciesBibleEntry(
                    speciesID: current.speciesID,
                    displayName: current.displayName,
                    baseElement: current.baseElement,
                    fantasy: current.fantasy,
                    metricBias: current.metricBias,
                    habitatTags: uniqueValues(current.habitatTags + entry.habitatTags),
                    visualKeywords: uniqueValues(current.visualKeywords + entry.visualKeywords),
                    narrativeHooks: uniqueValues(current.narrativeHooks + entry.narrativeHooks),
                    defaultMutationFamilyIDs: uniqueValues(current.defaultMutationFamilyIDs + entry.defaultMutationFamilyIDs)
                )
            } else {
                orderedKeys.append(entry.speciesID)
                lookup[entry.speciesID] = entry
            }
        }

        return orderedKeys.compactMap { lookup[$0] }
    }

    private static func uniqueValues(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        return values.filter { seen.insert($0).inserted }
    }

    private static func sortKey(for pack: WorldContentPack) -> String {
        let packID = pack.contentPack.packID
        let isSeedPack = packID.contains("seed") || packID.contains("master")
        return (isSeedPack ? "0" : "1") + ":" + packID
    }

    private static func mergeLines(_ values: [String], limit: Int) -> String {
        uniqueValues(values)
            .prefix(limit)
            .joined(separator: " / ")
    }
}
