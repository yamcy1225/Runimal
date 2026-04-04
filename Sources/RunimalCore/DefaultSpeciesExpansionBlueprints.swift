import Foundation

public enum DefaultSpeciesExpansionBlueprints {
    public static let baseSpeciesBlueprints: [SpeciesExpansionBlueprint] = [
        blueprint(
            speciesID: "windrunner",
            displayName: "에이라리스",
            fantasy: "먼 항로의 결을 깃결에 새기며 달린 이보다 먼저 바람길을 읽어내는 선도형 러니멀",
            body: [
                branch("aero-swift", .body, "Aero Swift", "가볍고 길게 뻗는 체형", "장거리 순항"),
                branch("crest-guard", .body, "Crest Guard", "날개깃이 단단해진 체형", "바람 저항"),
                branch("roam-wild", .body, "Roam Wild", "야생 탐사형 체형", "자유 주행"),
            ],
            ecology: [
                branch("sky-urban", .ecology, "Sky Urban", "도심 상공 기류", "도심 장거리"),
                branch("river-open", .ecology, "River Open", "강변 개활지", "리버사이드"),
                branch("ridge-frontier", .ecology, "Ridge Frontier", "능선 바람길", "바람 구역"),
            ],
            rhythm: [
                branch("cruise-loop", .rhythm, "Cruise Loop", "안정적인 루프 리듬", "일정 페이스"),
                branch("draft-route", .rhythm, "Draft Route", "왕복형 항로 리듬", "out-and-back"),
                branch("tailwind-pulse", .rhythm, "Tailwind Pulse", "후반 가속 리듬", "후반 유지"),
            ]
        ),
        blueprint(
            speciesID: "stoneback",
            displayName: "크래그맨틀",
            fantasy: "산마루의 중량과 인내를 갑각 아래 켜켜이 눌러 담는 방벽형 러니멀",
            body: [
                branch("ridge-guard", .body, "Ridge Guard", "능선 방어형 체형", "언덕 지속"),
                branch("summit-core", .body, "Summit Core", "정상 돌파형 체형", "고도 상승"),
                branch("basalt-bulwark", .body, "Basalt Bulwark", "무게중심 강화형", "저케이던스"),
            ],
            ecology: [
                branch("fault-rock", .ecology, "Fault Rock", "암석 지형 적응", "바위 지대"),
                branch("cold-ridge", .ecology, "Cold Ridge", "찬 공기 능선", "cold run"),
                branch("storm-slope", .ecology, "Storm Slope", "거센 바람 언덕", "wind climb"),
            ],
            rhythm: [
                branch("climb-pulse", .rhythm, "Climb Pulse", "오르막 리듬", "고도형 세션"),
                branch("hold-line", .rhythm, "Hold Line", "무너지지 않는 페이스", "꾸준한 유지"),
                branch("anchor-step", .rhythm, "Anchor Step", "묵직한 보폭 리듬", "낮은 케이던스"),
            ]
        ),
        blueprint(
            speciesID: "sparkfang",
            displayName: "신더래시",
            fantasy: "질주의 열과 추격의 찰나를 송곳니 끝에 벼려 두는 화염형 러니멀",
            body: [
                branch("burst-swift", .body, "Burst Swift", "폭발 질주형", "짧고 빠른 세션"),
                branch("arc-raider", .body, "Arc Raider", "짧은 추격형", "인터벌"),
                branch("flare-hunter", .body, "Flare Hunter", "불꽃 사냥형", "고강도 러닝"),
            ],
            ecology: [
                branch("neon-urban", .ecology, "Neon Urban", "도심 네온 구역", "도심 인터벌"),
                branch("heat-lane", .ecology, "Heat Lane", "열기 구간", "더운 날 러닝"),
                branch("signal-track", .ecology, "Signal Track", "신호 많은 코스", "가감속 코스"),
            ],
            rhythm: [
                branch("tempo-rush", .rhythm, "Tempo Rush", "빠른 템포 리듬", "tempo run"),
                branch("surge-fang", .rhythm, "Surge Fang", "급가속 리듬", "고케이던스"),
                branch("shock-beat", .rhythm, "Shock Beat", "심박 상승 리듬", "돌발 이벤트"),
            ]
        ),
        blueprint(
            speciesID: "mosshop",
            displayName: "모스베일",
            fantasy: "회복의 숨과 눅진한 정적을 몸 둘레에 드리워 주변 풍경까지 가라앉히는 치유형 러니멀",
            body: [
                branch("canopy-guard", .body, "Canopy Guard", "부드러운 보호형", "긴 회복 주행"),
                branch("bloom-round", .body, "Bloom Round", "둥근 생장형", "편안한 러닝"),
                branch("dew-sleeper", .body, "Dew Sleeper", "이슬 회복형", "낮은 강도"),
            ],
            ecology: [
                branch("rain-wildland", .ecology, "Rain Wildland", "비와 숲길 생태", "rain run"),
                branch("park-moss", .ecology, "Park Moss", "공원형 생태", "park route"),
                branch("grove-rest", .ecology, "Grove Rest", "회복 숲 생태", "cooldown run"),
            ],
            rhythm: [
                branch("bloom-pulse", .rhythm, "Bloom Pulse", "안정 호흡 리듬", "steady breathing"),
                branch("calm-loop", .rhythm, "Calm Loop", "반복 안정 리듬", "loop course"),
                branch("drift-heal", .rhythm, "Drift Heal", "느린 회복 리듬", "recovery pace"),
            ]
        ),
        blueprint(
            speciesID: "seedle",
            displayName: "던스프리그",
            fantasy: "탄생의 미약한 생기를 모아 새벽의 어린 순처럼 틔워 내는 발아형 러니멀",
            body: [
                branch("sprout-swift", .body, "Sprout Swift", "가벼운 발아형", "첫 러닝"),
                branch("root-guard", .body, "Root Guard", "정착 성장형", "누적 거리"),
                branch("bud-runner", .body, "Bud Runner", "막 자라나는 질주형", "입문 강화"),
            ],
            ecology: [
                branch("garden-core", .ecology, "Garden Core", "정원권 생태", "starter area"),
                branch("everywhere-seed", .ecology, "Everywhere Seed", "전 구역 적응형", "범용 출현"),
                branch("twilight-bud", .ecology, "Twilight Bud", "황혼 적응형", "dusk run"),
            ],
            rhythm: [
                branch("first-step", .rhythm, "Birth Step", "탄생 리듬", "초기 러닝"),
                branch("steady-root", .rhythm, "Steady Root", "기초 적응 리듬", "낮은 변동성"),
                branch("grow-loop", .rhythm, "Grow Loop", "꾸준 누적 리듬", "habit loop"),
            ]
        ),
    ]

    public static let starterShowcaseRoster: [LaunchRosterEntry] = [
        roster("windrunner.aero-swift.sky-urban.cruise-loop", "starter", "base"),
        roster("windrunner.crest-guard.river-open.draft-route", "starter", "distance"),
        roster("windrunner.roam-wild.ridge-frontier.tailwind-pulse", "advanced", "exploration"),
        roster("stoneback.ridge-guard.fault-rock.climb-pulse", "starter", "climb"),
        roster("stoneback.summit-core.cold-ridge.hold-line", "advanced", "ridge"),
        roster("stoneback.basalt-bulwark.storm-slope.anchor-step", "advanced", "endurance"),
        roster("sparkfang.burst-swift.neon-urban.tempo-rush", "starter", "tempo"),
        roster("sparkfang.arc-raider.heat-lane.surge-fang", "advanced", "heat"),
        roster("sparkfang.flare-hunter.signal-track.shock-beat", "advanced", "event"),
        roster("mosshop.canopy-guard.rain-wildland.bloom-pulse", "starter", "recovery"),
        roster("mosshop.bloom-round.park-moss.calm-loop", "starter", "park"),
        roster("mosshop.dew-sleeper.grove-rest.drift-heal", "advanced", "heal"),
        roster("seedle.sprout-swift.garden-core.first-step", "starter", "intro"),
        roster("seedle.root-guard.everywhere-seed.steady-root", "starter", "growth"),
        roster("seedle.bud-runner.twilight-bud.grow-loop", "advanced", "dusk"),
        roster("windrunner.aero-swift.river-open.tailwind-pulse", "season", "gale-frontier"),
        roster("stoneback.summit-core.storm-slope.climb-pulse", "season", "summit-fault"),
        roster("sparkfang.burst-swift.signal-track.shock-beat", "season", "city-pulse"),
        roster("mosshop.canopy-guard.grove-rest.bloom-pulse", "season", "verdant-circuit"),
        roster("seedle.bud-runner.everywhere-seed.grow-loop", "season", "quiet-signal"),
    ]

    public static let maxExpandableForms = SpeciesExpansionEngine.maxFormCount(for: baseSpeciesBlueprints)

    private static func blueprint(
        speciesID: String,
        displayName: String,
        fantasy: String,
        body: [SpeciesLineageBranchBlueprint],
        ecology: [SpeciesLineageBranchBlueprint],
        rhythm: [SpeciesLineageBranchBlueprint]
    ) -> SpeciesExpansionBlueprint {
        SpeciesExpansionBlueprint(
            speciesID: speciesID,
            displayName: displayName,
            fantasyLine: fantasy,
            bodyBranches: body,
            ecologyBranches: ecology,
            rhythmBranches: rhythm
        )
    }

    private static func branch(
        _ id: String,
        _ axis: SpeciesLineageAxis,
        _ title: String,
        _ theme: String,
        _ unlockCue: String
    ) -> SpeciesLineageBranchBlueprint {
        SpeciesLineageBranchBlueprint(
            id: id,
            axis: axis,
            title: title,
            theme: theme,
            unlockCue: unlockCue
        )
    }

    private static func roster(
        _ formID: String,
        _ releaseTier: String,
        _ unlockTrack: String
    ) -> LaunchRosterEntry {
        LaunchRosterEntry(
            formID: formID,
            releaseTier: releaseTier,
            unlockTrack: unlockTrack
        )
    }
}
