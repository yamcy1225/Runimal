import Foundation

public enum RunimalWorldProgressEngine {
    public static func impact(
        for run: CompletedRunRecord,
        current snapshot: WorldProgressSnapshot = .empty,
        pack: WorldContentPack = DefaultWorldContent.pack
    ) -> WorldRunImpact? {
        guard let resolution = RunimalWorldContentEngine.resolve(for: run, pack: pack) else {
            return nil
        }

        let distanceKm = run.distanceMeters / 1000
        let cadencePeak = run.cadence ?? 0
        let nightRunDelta = resolution.timeAura == .night ? 1 : 0

        let unlockedRegion = snapshot.regions.contains(where: { $0.regionID == resolution.region.regionID }) == false
        let unlockedSeason = resolution.season.map { season in
            snapshot.seasons.contains(where: { $0.seasonID == season.seasonID }) == false
        } ?? false

        let episodeImpact = selectEpisodeImpact(
            for: run,
            resolution: resolution,
            snapshot: snapshot
        )

        return WorldRunImpact(
            regionID: resolution.region.regionID,
            regionTitle: resolution.region.title,
            seasonID: resolution.season?.seasonID,
            seasonTitle: resolution.season?.title,
            episodeID: episodeImpact?.episode.episodeID,
            episodeTitle: episodeImpact?.episode.playerFacingText,
            unlockedRegion: unlockedRegion,
            unlockedSeason: unlockedSeason,
            unlockedEpisode: episodeImpact?.unlocked ?? false,
            regionRunCountDelta: 1,
            seasonRunCountDelta: resolution.season == nil ? 0 : 1,
            episodeRunCountDelta: episodeImpact == nil ? 0 : 1,
            distanceKmDelta: distanceKm,
            elevationGainDelta: run.elevationGainM,
            nightRunDelta: nightRunDelta,
            cadencePeakDelta: cadencePeak
        )
    }

    public static func applying(
        run: CompletedRunRecord,
        to snapshot: WorldProgressSnapshot,
        pack: WorldContentPack = DefaultWorldContent.pack
    ) -> WorldProgressSnapshot {
        guard let impact = impact(for: run, current: snapshot, pack: pack) else {
            return snapshot
        }

        let nextRegions = updateRegions(
            in: snapshot.regions,
            impact: impact,
            endedAt: run.endedAt
        )
        let nextSeasons = updateSeasons(
            in: snapshot.seasons,
            impact: impact,
            endedAt: run.endedAt
        )
        let nextEpisodes = updateEpisodes(
            in: snapshot.episodes,
            run: run,
            resolution: RunimalWorldContentEngine.resolve(for: run, pack: pack),
            pack: pack
        )

        return WorldProgressSnapshot(
            regions: nextRegions.sorted { $0.unlockedAt > $1.unlockedAt },
            seasons: nextSeasons.sorted { $0.unlockedAt > $1.unlockedAt },
            episodes: nextEpisodes.sorted { ($0.unlockedAt ?? $0.lastRunAt) > ($1.unlockedAt ?? $1.lastRunAt) },
            lastImpact: impact,
            lastUpdatedAt: run.endedAt
        )
    }

    public static func rebuild(
        from runs: [CompletedRunRecord],
        pack: WorldContentPack = DefaultWorldContent.pack
    ) -> WorldProgressSnapshot {
        runs.sorted { $0.endedAt < $1.endedAt }
            .reduce(.empty) { partial, run in
                applying(run: run, to: partial, pack: pack)
            }
    }

    public static func progressRatio(
        for episode: WorldEpisodeProgress,
        entry: NarrativeEpisodeEntry
    ) -> Double {
        let totalConditions = conditionCount(for: entry.triggerRules)
        guard totalConditions > 0 else { return episode.unlockedAt == nil ? 0 : 1 }

        var satisfied = 0
        if episode.runCount >= max(entry.triggerRules.completedRunsMin ?? 1, 1) {
            satisfied += 1
        }
        if let distanceKmMin = entry.triggerRules.distanceKmMin, episode.totalDistanceKm >= distanceKmMin {
            satisfied += 1
        } else if entry.triggerRules.distanceKmMin == nil {
            satisfied += 1
        }
        if let cadenceMin = entry.triggerRules.cadenceMin, episode.cadencePeak >= cadenceMin {
            satisfied += 1
        } else if entry.triggerRules.cadenceMin == nil {
            satisfied += 1
        }
        if let nightRunRequired = entry.triggerRules.nightRunRequired, nightRunRequired {
            if episode.nightRunCount > 0 { satisfied += 1 }
        } else {
            satisfied += 1
        }
        if let elevationGainMin = entry.triggerRules.elevationGainMin, episode.totalElevationGainM >= elevationGainMin {
            satisfied += 1
        } else if entry.triggerRules.elevationGainMin == nil {
            satisfied += 1
        }

        return min(max(Double(satisfied) / Double(totalConditions), 0), 1)
    }

    private static func updateRegions(
        in regions: [WorldRegionProgress],
        impact: WorldRunImpact,
        endedAt: Date
    ) -> [WorldRegionProgress] {
        var next = regions
        if let index = next.firstIndex(where: { $0.regionID == impact.regionID }) {
            let current = next[index]
            next[index] = WorldRegionProgress(
                regionID: current.regionID,
                title: current.title,
                runCount: current.runCount + impact.regionRunCountDelta,
                totalDistanceKm: current.totalDistanceKm + impact.distanceKmDelta,
                unlockedAt: current.unlockedAt,
                lastRunAt: endedAt
            )
        } else {
            next.append(
                WorldRegionProgress(
                    regionID: impact.regionID,
                    title: impact.regionTitle,
                    runCount: impact.regionRunCountDelta,
                    totalDistanceKm: impact.distanceKmDelta,
                    unlockedAt: endedAt,
                    lastRunAt: endedAt
                )
            )
        }
        return next
    }

    private static func updateSeasons(
        in seasons: [WorldSeasonProgress],
        impact: WorldRunImpact,
        endedAt: Date
    ) -> [WorldSeasonProgress] {
        guard let seasonID = impact.seasonID, let seasonTitle = impact.seasonTitle, impact.seasonRunCountDelta > 0 else {
            return seasons
        }

        var next = seasons
        if let index = next.firstIndex(where: { $0.seasonID == seasonID }) {
            let current = next[index]
            next[index] = WorldSeasonProgress(
                seasonID: current.seasonID,
                title: current.title,
                runCount: current.runCount + impact.seasonRunCountDelta,
                totalDistanceKm: current.totalDistanceKm + impact.distanceKmDelta,
                unlockedAt: current.unlockedAt,
                lastRunAt: endedAt
            )
        } else {
            next.append(
                WorldSeasonProgress(
                    seasonID: seasonID,
                    title: seasonTitle,
                    runCount: impact.seasonRunCountDelta,
                    totalDistanceKm: impact.distanceKmDelta,
                    unlockedAt: endedAt,
                    lastRunAt: endedAt
                )
            )
        }
        return next
    }

    private static func updateEpisodes(
        in episodes: [WorldEpisodeProgress],
        run: CompletedRunRecord,
        resolution: RunWorldResolution?,
        pack: WorldContentPack
    ) -> [WorldEpisodeProgress] {
        guard let resolution else { return episodes }

        let candidateEpisodes = pack.narrativeEpisodes.filter { episode in
            episode.regionID == resolution.region.regionID &&
                (resolution.season == nil || episode.seasonID == resolution.season?.seasonID)
        }
        guard candidateEpisodes.isEmpty == false else { return episodes }

        var next = episodes
        let distanceKm = run.distanceMeters / 1000
        let cadencePeak = run.cadence ?? 0
        let nightRunCount = resolution.timeAura == .night ? 1 : 0

        for episode in candidateEpisodes {
            if let index = next.firstIndex(where: { $0.episodeID == episode.episodeID }) {
                let current = next[index]
                let updated = WorldEpisodeProgress(
                    episodeID: current.episodeID,
                    title: current.title,
                    regionID: current.regionID,
                    seasonID: current.seasonID,
                    runCount: current.runCount + 1,
                    totalDistanceKm: current.totalDistanceKm + distanceKm,
                    nightRunCount: current.nightRunCount + nightRunCount,
                    cadencePeak: max(current.cadencePeak, cadencePeak),
                    totalElevationGainM: current.totalElevationGainM + run.elevationGainM,
                    unlockedAt: current.unlockedAt ?? unlockDateIfSatisfied(
                        episode: episode,
                        runCount: current.runCount + 1,
                        totalDistanceKm: current.totalDistanceKm + distanceKm,
                        nightRunCount: current.nightRunCount + nightRunCount,
                        cadencePeak: max(current.cadencePeak, cadencePeak),
                        totalElevationGainM: current.totalElevationGainM + run.elevationGainM,
                        endedAt: run.endedAt
                    ),
                    lastRunAt: run.endedAt
                )
                next[index] = updated
            } else {
                next.append(
                    WorldEpisodeProgress(
                        episodeID: episode.episodeID,
                        title: episode.playerFacingText,
                        regionID: episode.regionID,
                        seasonID: episode.seasonID,
                        runCount: 1,
                        totalDistanceKm: distanceKm,
                        nightRunCount: nightRunCount,
                        cadencePeak: cadencePeak,
                        totalElevationGainM: run.elevationGainM,
                        unlockedAt: unlockDateIfSatisfied(
                            episode: episode,
                            runCount: 1,
                            totalDistanceKm: distanceKm,
                            nightRunCount: nightRunCount,
                            cadencePeak: cadencePeak,
                            totalElevationGainM: run.elevationGainM,
                            endedAt: run.endedAt
                        ),
                        lastRunAt: run.endedAt
                    )
                )
            }
        }

        return next
    }

    private static func selectEpisodeImpact(
        for run: CompletedRunRecord,
        resolution: RunWorldResolution,
        snapshot: WorldProgressSnapshot
    ) -> (episode: NarrativeEpisodeEntry, unlocked: Bool)? {
        let candidateEpisodes = resolution.candidateEpisodes
        guard candidateEpisodes.isEmpty == false else { return nil }

        let distanceKm = run.distanceMeters / 1000
        let cadencePeak = run.cadence ?? 0
        let nightRunCount = resolution.timeAura == .night ? 1 : 0

        let ranked = candidateEpisodes.compactMap { episode -> (NarrativeEpisodeEntry, Bool, Double)? in
            let current = snapshot.episodes.first(where: { $0.episodeID == episode.episodeID })
            let runCount = (current?.runCount ?? 0) + 1
            let totalDistanceKm = (current?.totalDistanceKm ?? 0) + distanceKm
            let nextNightRunCount = (current?.nightRunCount ?? 0) + nightRunCount
            let nextCadencePeak = max(current?.cadencePeak ?? 0, cadencePeak)
            let totalElevationGainM = (current?.totalElevationGainM ?? 0) + run.elevationGainM
            let unlocked = current?.unlockedAt == nil &&
                unlockDateIfSatisfied(
                    episode: episode,
                    runCount: runCount,
                    totalDistanceKm: totalDistanceKm,
                    nightRunCount: nextNightRunCount,
                    cadencePeak: nextCadencePeak,
                    totalElevationGainM: totalElevationGainM,
                    endedAt: run.endedAt
                ) != nil

            let progress = progressRatio(
                runCount: runCount,
                totalDistanceKm: totalDistanceKm,
                nightRunCount: nextNightRunCount,
                cadencePeak: nextCadencePeak,
                totalElevationGainM: totalElevationGainM,
                rules: episode.triggerRules
            )
            return (episode, unlocked, progress)
        }

        return ranked.sorted {
            if $0.1 != $1.1 { return $0.1 && !$1.1 }
            if $0.2 != $1.2 { return $0.2 > $1.2 }
            return $0.0.episodeID < $1.0.episodeID
        }.first.map { ($0.0, $0.1) }
    }

    private static func unlockDateIfSatisfied(
        episode: NarrativeEpisodeEntry,
        runCount: Int,
        totalDistanceKm: Double,
        nightRunCount: Int,
        cadencePeak: Int,
        totalElevationGainM: Int,
        endedAt: Date
    ) -> Date? {
        let rules = episode.triggerRules
        if runCount < max(rules.completedRunsMin ?? 1, 1) { return nil }
        if let distanceKmMin = rules.distanceKmMin, totalDistanceKm < distanceKmMin { return nil }
        if let cadenceMin = rules.cadenceMin, cadencePeak < cadenceMin { return nil }
        if let nightRunRequired = rules.nightRunRequired, nightRunRequired, nightRunCount == 0 { return nil }
        if let elevationGainMin = rules.elevationGainMin, totalElevationGainM < elevationGainMin { return nil }
        return endedAt
    }

    private static func conditionCount(for rules: EpisodeTriggerRules) -> Int {
        var total = 1
        if rules.distanceKmMin != nil { total += 1 }
        if rules.cadenceMin != nil { total += 1 }
        if rules.nightRunRequired == true { total += 1 }
        if rules.elevationGainMin != nil { total += 1 }
        return total
    }

    private static func progressRatio(
        runCount: Int,
        totalDistanceKm: Double,
        nightRunCount: Int,
        cadencePeak: Int,
        totalElevationGainM: Int,
        rules: EpisodeTriggerRules
    ) -> Double {
        let totalConditions = conditionCount(for: rules)
        var satisfied = runCount >= max(rules.completedRunsMin ?? 1, 1) ? 1 : 0
        if let distanceKmMin = rules.distanceKmMin {
            satisfied += totalDistanceKm >= distanceKmMin ? 1 : 0
        }
        if let cadenceMin = rules.cadenceMin {
            satisfied += cadencePeak >= cadenceMin ? 1 : 0
        }
        if let nightRunRequired = rules.nightRunRequired, nightRunRequired {
            satisfied += nightRunCount > 0 ? 1 : 0
        }
        if let elevationGainMin = rules.elevationGainMin {
            satisfied += totalElevationGainM >= elevationGainMin ? 1 : 0
        }
        return min(max(Double(satisfied) / Double(totalConditions), 0), 1)
    }
}
