import Foundation

public enum DefaultWorldContent {
    public static let sourcePacks = {
        let loadedPacks = WorldContentPackLoader.loadAllPacks()
        return loadedPacks.isEmpty ? [fallbackPack] : loadedPacks
    }()

    public static let pack = WorldContentPackComposer.merge(sourcePacks) ?? fallbackPack

    public static let packSummaries = sourcePacks.map(\.contentPack)

    private static let fallbackPack = WorldContentPack(
        schemaVersion: "0.1.0",
        project: "RunimalWorld",
        description: "Seed world content pack for current Runimal species and regions.",
        contentPack: ContentPackSummary(
            packID: "master-seed",
            title: "Runimal World Seed",
            type: "expansion",
            status: "draft",
            playerFacingTheme: "달리기로 잠든 세계를 깨우는 첫 생태권 세트",
            featuredRegionIDs: ["urban-core", "nature-trail", "altitude-ridge", "moonlight-alley", "festival-gate"],
            featuredSpeciesIDs: ["windrunner", "stoneback", "sparkfang", "mosshop", "seedle"],
            featuredVariantIDs: ["tempo-surge", "zen-bloom", "summit-heart", "eclipse-mark", "loop-sigil"],
            episodeIDs: ["episode-awakening-signal", "episode-sparkflood", "episode-mossbreath", "episode-ridgeheart", "episode-moonmark"]
        ),
        speciesBible: [
            species("windrunner", "Windrunner", "light", "장거리와 순항에 반응하는 길잡이형 러니멀", "high", "high", "medium", "low", "low", "medium", ["urban", "riverside", "open-path"], ["wing", "trail", "feather"], ["먼 길을 먼저 읽어내는 종족", "오래 달릴수록 선명해지는 존재"], ["windrunner-gale-swift", "windrunner-loop-route", "windrunner-trail-wildland"]),
            species("stoneback", "Stoneback", "earth", "오르막과 저항을 견디며 자라는 수호형 러니멀", "medium", "medium", "low", "high", "low", "low", ["ridge", "stairs", "rock"], ["shell", "ridge", "rock-heart"], ["언덕의 심장을 등에 얹은 종족", "느리더라도 끝까지 버티는 존재"], ["stoneback-ridge-guard", "stoneback-summit-pulse", "stoneback-fault-wild"]),
            species("sparkfang", "Sparkfang", "flame", "빠른 템포와 폭발적인 케이던스에 반응하는 질주형 러니멀", "low", "medium", "high", "low", "low", "medium", ["city", "sprint-lane", "signal-zone"], ["fang", "spark", "tail-flare"], ["순간의 불꽃을 좇는 종족", "파열 직전의 리듬을 먹고 자라는 존재"], ["sparkfang-tempo-rhythm", "sparkfang-neon-urban", "sparkfang-burst-swift"]),
            species("mosshop", "Mosshop", "leaf", "평온한 호흡과 자연 리듬에 반응하는 회복형 러니멀", "medium", "high", "medium", "low", "low", "low", ["forest", "park", "rain-trail"], ["moss", "round", "soft-leaf"], ["쉬는 법을 기억하는 종족", "회복의 숨결을 넓히는 존재"], ["mosshop-bloom-pulse", "mosshop-rain-wildland", "mosshop-canopy-guard"]),
            species("seedle", "Seedle", "leaf", "시작의 활력에서 태어나는 발아형 러니멀", "medium", "medium", "medium", "medium", "low", "low", ["starter", "garden", "everywhere"], ["seed", "sprout", "tiny-tail"], ["어디서든 시작될 수 있는 종족", "가장 많은 가능성을 품은 존재"], ["seedle-sprout-swift", "seedle-root-guard", "seedle-twilight-bud"])
        ],
        mutationFamilies: [
            family("windrunner-gale-swift", "windrunner", "body", "Gale Swift", "장거리와 안정 페이스", "순항과 자유"),
            family("windrunner-loop-route", "windrunner", "rhythm", "Loop Route", "반복 루프 경로", "문양과 항법"),
            family("windrunner-trail-wildland", "windrunner", "habitat", "Trail Wildland", "야외 장거리 코스", "탐사와 개활지"),
            family("stoneback-ridge-guard", "stoneback", "body", "Ridge Guard", "고도 상승과 언덕", "수호와 버팀"),
            family("stoneback-summit-pulse", "stoneback", "rhythm", "Summit Pulse", "강한 심박과 오르막 지속", "심장과 결의"),
            family("stoneback-fault-wild", "stoneback", "habitat", "Fault Wild", "거친 지형", "지각과 균열"),
            family("sparkfang-tempo-rhythm", "sparkfang", "rhythm", "Tempo Rhythm", "고케이던스", "속도와 열기"),
            family("sparkfang-neon-urban", "sparkfang", "habitat", "Neon Urban", "도심 인터벌", "도심 질주"),
            family("sparkfang-burst-swift", "sparkfang", "body", "Burst Swift", "짧고 빠른 스퍼트", "폭발과 추격"),
            family("mosshop-bloom-pulse", "mosshop", "rhythm", "Bloom Pulse", "안정적인 호흡", "회복과 개화"),
            family("mosshop-rain-wildland", "mosshop", "habitat", "Rain Wildland", "비와 숲길", "숲과 촉촉함"),
            family("mosshop-canopy-guard", "mosshop", "body", "Canopy Guard", "천천히 오래 달리기", "보호와 휴식"),
            family("sparkfang-eclipse-twilight", "sparkfang", "habitat", "Eclipse Twilight", "야간 러닝", "황혼과 전류"),
            family("sparkfang-maze-route", "sparkfang", "rhythm", "Maze Route", "복잡한 야간 경로", "왜곡과 추적"),
            family("seedle-echo-bud", "seedle", "body", "Echo Bud", "낮은 조도와 조심스러운 회복 주행", "그림자와 발아"),
            family("seedle-sprout-swift", "seedle", "body", "Sprout Swift", "입문 러닝과 가벼운 리듬", "시작과 발아"),
            family("seedle-root-guard", "seedle", "body", "Root Guard", "꾸준한 누적 거리", "정착과 성장"),
            family("seedle-twilight-bud", "seedle", "habitat", "Twilight Bud", "황혼 러닝", "가능성과 변주")
        ],
        rareVariants: [
            variant("tempo-surge", "Tempo Surge", "특별한 진화: 템포 서지", "고케이던스와 빠른 페이스", "속도와 리듬이 과열된 흔적", ["sparkfang", "windrunner"]),
            variant("zen-bloom", "Zen Bloom", "특별한 진화: 젠 블룸", "안정된 페이스와 고른 호흡", "평온함이 꽃처럼 남은 흔적", ["mosshop", "seedle"]),
            variant("summit-heart", "Summit Heart", "특별한 진화: 서밋 하트", "언덕과 고도 상승", "오르막을 견딘 심장의 흔적", ["stoneback"]),
            variant("eclipse-mark", "Eclipse Mark", "특별한 진화: 이클립스 마크", "야간 러닝과 그림자 구간", "밤의 위상이 남긴 황혼 계열의 흔적", ["sparkfang", "seedle"]),
            variant("loop-sigil", "Loop Sigil", "특별한 진화: 루프 시길", "반복되는 루프 코스", "같은 길을 반복해 새겨진 문양", ["windrunner", "sparkfang"])
        ],
        regions: [
            region("urban-core", "도심 구역", "default", ["day", "dusk"], ["loop", "out-and-back"], ["clear", "overcast"], ["seedle", "sparkfang", "windrunner"], ["tempo-surge", "loop-sigil"], "가장 먼저 활력이 되돌아오는 생활권 관문"),
            region("nature-trail", "자연 구역", "distance-total-15km", ["day", "dawn"], ["freeform", "out-and-back"], ["rain", "clear", "overcast"], ["mosshop", "seedle", "windrunner"], ["zen-bloom"], "회복과 호흡이 짙어지는 숲길 생태권"),
            region("altitude-ridge", "고지대 구역", "elevation-total-250m", ["day", "dusk"], ["out-and-back", "maze"], ["clear", "wind", "cold"], ["stoneback", "windrunner"], ["summit-heart"], "오르막과 버팀이 생명으로 응축되는 암석 지대"),
            region("moonlight-alley", "달빛 구역", "night-runs-5", ["night", "dusk"], ["maze", "loop"], ["clear", "cold", "unknown"], ["sparkfang", "seedle", "windrunner"], ["eclipse-mark", "loop-sigil"], "달빛과 그림자가 황혼 계열로 번지는 신비 구역"),
            region("festival-gate", "특별 이벤트 구역", "season-event-only", ["day", "night"], ["loop", "freeform"], ["clear", "wind", "overcast"], ["seedle", "sparkfang", "mosshop"], ["tempo-surge", "zen-bloom", "eclipse-mark"], "협동 목표로만 열리는 축제형 구역")
        ],
        seasons: [
            season("quiet-signal", "Quiet Signal", "조용한 각성과 첫 교감", ["urban-core", "nature-trail"], ["seedle", "windrunner", "mosshop"], ["zen-bloom"], ["first-egg-awakening", "starter-growth-loop"]),
            season("gale-frontier", "Gale Frontier", "바람길 개방과 장거리 탐사", ["urban-core", "altitude-ridge"], ["windrunner"], ["loop-sigil"], ["long-distance-hunt", "route-memory-signal"]),
            season("verdant-circuit", "Verdant Circuit", "회복과 자연 리듬의 복원", ["nature-trail"], ["mosshop", "seedle"], ["zen-bloom"], ["cooldown-grove", "rain-breath-ritual"]),
            season("summit-fault", "Summit Fault", "오르막과 균열의 심장", ["altitude-ridge"], ["stoneback"], ["summit-heart"], ["climb-chain", "ridge-rescue"]),
            season("hollow-dusk", "Hollow Dusk", "밤의 표식과 그림자 경계", ["moonlight-alley"], ["sparkfang", "seedle"], ["eclipse-mark"], ["night-lure", "eclipse-threshold"])
        ],
        narrativeEpisodes: [
            episode("episode-awakening-signal", "quiet-signal", "urban-core", 1, 2.0, nil, nil, nil, "처음으로 약한 활력 신호가 감지되었다. 잠든 알이 숨을 쉬기 시작한다.", [], ["seedle"], []),
            episode("episode-sparkflood", "quiet-signal", "urban-core", 3, nil, 170, nil, nil, "도심 구역의 전광 표지판이 흔들리며, 스파크 같은 송곳니 흔적이 나타난다.", [], ["sparkfang"], ["tempo-surge"]),
            episode("episode-mossbreath", "verdant-circuit", "nature-trail", 5, 12.0, nil, nil, nil, "숲길에 고요한 숨결이 번지며, 이끼처럼 부드러운 발자국이 드러난다.", ["nature-trail"], ["mosshop"], ["zen-bloom"]),
            episode("episode-ridgeheart", "summit-fault", "altitude-ridge", 5, nil, nil, nil, 120, "능선 아래에서 둔탁한 심장 소리가 울리고, 암석 등껍질의 거대한 실루엣이 깨어난다.", ["altitude-ridge"], ["stoneback"], ["summit-heart"]),
            episode("episode-moonmark", "hollow-dusk", "moonlight-alley", 5, nil, nil, true, nil, "달빛 구역의 벽면에 검은 표식이 퍼지고, 스파크와 새싹 계열에서 황혼 형질이 깨어난다.", ["moonlight-alley"], [], ["eclipse-mark"])
        ]
    )

    public static func speciesEntry(for species: PetSpecies) -> SpeciesBibleEntry? {
        pack.speciesBible.first { $0.speciesID == species.rawValue }
    }

    public static func variantEntry(for variant: RareVariant) -> VariantNarrativeEntry? {
        pack.rareVariants.first { $0.variantID == variant.rawValue }
    }

    private static func species(
        _ id: String,
        _ name: String,
        _ element: String,
        _ fantasy: String,
        _ distance: String,
        _ paceStability: String,
        _ cadence: String,
        _ elevation: String,
        _ nightAffinity: String,
        _ routeComplexity: String,
        _ habitats: [String],
        _ visuals: [String],
        _ hooks: [String],
        _ families: [String]
    ) -> SpeciesBibleEntry {
        SpeciesBibleEntry(
            speciesID: id,
            displayName: name,
            baseElement: element,
            fantasy: fantasy,
            metricBias: MetricBiasProfile(
                distance: distance,
                paceStability: paceStability,
                cadence: cadence,
                elevation: elevation,
                nightAffinity: nightAffinity,
                routeComplexity: routeComplexity
            ),
            habitatTags: habitats,
            visualKeywords: visuals,
            narrativeHooks: hooks,
            defaultMutationFamilyIDs: families
        )
    }

    private static func family(
        _ id: String,
        _ speciesID: String,
        _ axis: String,
        _ branchName: String,
        _ unlockHint: String,
        _ storyTone: String
    ) -> MutationFamilyEntry {
        MutationFamilyEntry(
            familyID: id,
            speciesID: speciesID,
            axis: axis,
            branchName: branchName,
            unlockHint: unlockHint,
            metricBias: PartialMetricBias(
                distance: nil,
                paceStability: nil,
                cadence: nil,
                elevation: nil,
                nightAffinity: nil,
                routeComplexity: nil
            ),
            visualShift: [],
            storyTone: storyTone
        )
    }

    private static func variant(
        _ id: String,
        _ name: String,
        _ playerFacingName: String,
        _ triggerHint: String,
        _ meaning: String,
        _ speciesIDs: [String]
    ) -> VariantNarrativeEntry {
        VariantNarrativeEntry(
            variantID: id,
            displayName: name,
            playerFacingName: playerFacingName,
            triggerHint: triggerHint,
            narrativeMeaning: meaning,
            suggestedSpeciesIDs: speciesIDs
        )
    }

    private static func region(
        _ id: String,
        _ title: String,
        _ unlockCondition: String,
        _ timeAuras: [String],
        _ routeShapes: [String],
        _ environmentConditions: [String],
        _ activeSpeciesIDs: [String],
        _ activeVariantIDs: [String],
        _ summary: String
    ) -> RegionPackEntry {
        RegionPackEntry(
            regionID: id,
            title: title,
            unlockCondition: unlockCondition,
            environmentBias: EnvironmentBiasProfile(
                timeAuras: timeAuras,
                routeShapes: routeShapes,
                environmentConditions: environmentConditions
            ),
            activeSpeciesIDs: activeSpeciesIDs,
            activeVariantIDs: activeVariantIDs,
            narrativeSummary: summary
        )
    }

    private static func season(
        _ id: String,
        _ title: String,
        _ theme: String,
        _ regionIDs: [String],
        _ speciesIDs: [String],
        _ variantIDs: [String],
        _ hooks: [String]
    ) -> SeasonPackEntry {
        SeasonPackEntry(
            seasonID: id,
            title: title,
            theme: theme,
            featuredRegionIDs: regionIDs,
            featuredSpeciesIDs: speciesIDs,
            featuredVariantIDs: variantIDs,
            eventHooks: hooks
        )
    }

    private static func episode(
        _ id: String,
        _ seasonID: String,
        _ regionID: String,
        _ completedRunsMin: Int?,
        _ distanceKmMin: Double?,
        _ cadenceMin: Int?,
        _ nightRunRequired: Bool?,
        _ elevationGainMin: Int?,
        _ text: String,
        _ unlockRegions: [String],
        _ unlockSpecies: [String],
        _ unlockVariants: [String]
    ) -> NarrativeEpisodeEntry {
        NarrativeEpisodeEntry(
            episodeID: id,
            seasonID: seasonID,
            regionID: regionID,
            triggerRules: EpisodeTriggerRules(
                completedRunsMin: completedRunsMin,
                distanceKmMin: distanceKmMin,
                cadenceMin: cadenceMin,
                nightRunRequired: nightRunRequired,
                elevationGainMin: elevationGainMin
            ),
            playerFacingText: text,
            rewardPayload: EpisodeRewardPayload(
                unlockRegionIDs: unlockRegions,
                unlockSpeciesIDs: unlockSpecies,
                unlockVariantIDs: unlockVariants
            )
        )
    }
}
