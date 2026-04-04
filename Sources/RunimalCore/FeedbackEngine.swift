import Foundation

public struct LiveRunFeedback: Codable, Equatable, Sendable {
    public let label: String
    public let headline: String
    public let detail: String
    public let intensity: Double

    public init(label: String, headline: String, detail: String, intensity: Double) {
        self.label = label
        self.headline = headline
        self.detail = detail
        self.intensity = intensity
    }
}

public struct HatchInsight: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let emphasis: String

    public init(id: String, title: String, detail: String, emphasis: String) {
        self.id = id
        self.title = title
        self.detail = detail
        self.emphasis = emphasis
    }
}

public struct EvolutionTarget: Codable, Equatable, Sendable {
    public let title: String
    public let detail: String
    public let status: String
    public let focusTitle: String
    public let focusDetail: String
    public let actionTitle: String
    public let actionDetail: String
    public let checkpointTitle: String
    public let checkpointDetail: String
    public let badges: [String]

    public init(
        title: String,
        detail: String,
        status: String,
        focusTitle: String,
        focusDetail: String,
        actionTitle: String,
        actionDetail: String,
        checkpointTitle: String,
        checkpointDetail: String,
        badges: [String] = []
    ) {
        self.title = title
        self.detail = detail
        self.status = status
        self.focusTitle = focusTitle
        self.focusDetail = focusDetail
        self.actionTitle = actionTitle
        self.actionDetail = actionDetail
        self.checkpointTitle = checkpointTitle
        self.checkpointDetail = checkpointDetail
        self.badges = badges
    }
}

public struct LiveGoalTarget: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let progress: Double
    public let status: String

    public init(id: String, title: String, detail: String, progress: Double, status: String) {
        self.id = id
        self.title = title
        self.detail = detail
        self.progress = progress
        self.status = status
    }
}

public struct CompanionMomentNarrative: Codable, Equatable, Sendable {
    public let title: String
    public let detail: String
    public let emphasis: String
    public let badges: [String]

    public init(title: String, detail: String, emphasis: String, badges: [String] = []) {
        self.title = title
        self.detail = detail
        self.emphasis = emphasis
        self.badges = badges
    }
}

public enum ShareMilestoneKind: String, Codable, Equatable, Sendable {
    case firstHatch
    case rareVariant
    case mythic
}

public struct ShareMilestoneProgress: Codable, Equatable, Sendable {
    public let progress: Double
    public let label: String
    public let detail: String

    public init(progress: Double, label: String, detail: String) {
        self.progress = progress
        self.label = label
        self.detail = detail
    }
}

public extension RunimalGameEngine {
    static func evaluateLiveFeedback(for snapshot: LiveRunSnapshot, claimedRewardIDs: Set<String> = []) -> LiveRunFeedback {
        let pace = snapshot.averagePaceSeconds ?? 360
        let cadence = snapshot.cadence ?? 166
        let heartRate = snapshot.currentHeartRate ?? 148

        if claimedRewardIDs.contains("weekly-core-cache") && pace <= 325 && cadence >= 170 {
            return LiveRunFeedback(
                label: "Rare Window",
                headline: "희귀 변이 창이 열렸습니다",
                detail: "Rare Core Cache가 활성화되어 근접한 러닝도 변이 후보로 승격됩니다.",
                intensity: 0.96
            )
        }

        if pace <= RunimalBalanceConfig.surgePaceSeconds && cadence >= RunimalBalanceConfig.surgeCadence {
            return decorate(
                feedback: LiveRunFeedback(
                label: "Surge",
                headline: "희귀 변이 페이스에 접근 중",
                detail: "고케이던스와 빠른 리듬이 tempo 계열 변이를 자극하고 있습니다.",
                intensity: 0.92
                ),
                claimedRewardIDs: claimedRewardIDs
            )
        }

        if pace <= RunimalBalanceConfig.steadyPaceSeconds && cadence >= RunimalBalanceConfig.steadyCadence {
            return decorate(
                feedback: LiveRunFeedback(
                label: "Stable",
                headline: "지금 리듬이 가장 좋습니다",
                detail: "안정적인 페이스입니다. 이 구간을 유지하면 집중형 성장치가 올라갑니다.",
                intensity: 0.72
                ),
                claimedRewardIDs: claimedRewardIDs
            )
        }

        if heartRate >= Double(RunimalBalanceConfig.recoveryHeartRate) {
            return decorate(
                feedback: LiveRunFeedback(
                label: "Recover",
                headline: "조금만 정리하면 더 좋습니다",
                detail: "심박이 높습니다. 호흡을 안정시키면 성장 효율이 다시 올라갑니다.",
                intensity: 0.48
                ),
                claimedRewardIDs: claimedRewardIDs
            )
        }

        return decorate(
            feedback: LiveRunFeedback(
            label: "Warm",
            headline: "펫이 러닝 흔적을 읽는 중",
            detail: "조금 더 달리면 외형과 속성 변화가 분명해집니다.",
            intensity: 0.35
            ),
            claimedRewardIDs: claimedRewardIDs
        )
    }

    static func hatchInsights(for run: CompletedRunRecord) -> [HatchInsight] {
        let paceText = formattedPace(seconds: run.averagePaceSeconds)
        let distanceText = String(format: "%.2fkm", run.distanceMeters / 1000)
        let cadenceText = run.cadence.map(String.init) ?? "--"
        let variantText = run.reward.pet.rareVariant.map { RareVariantMeta.labels[$0] ?? $0.rawValue } ?? "Standard"

        return [
            HatchInsight(
                id: "distance",
                title: "Distance Trace",
                detail: "\(distanceText) 흔적으로 체력 계열이 강화됐습니다.",
                emphasis: distanceText
            ),
            HatchInsight(
                id: "pace",
                title: "Pace Signature",
                detail: "\(paceText) 리듬이 현재 종족과 오라를 결정했습니다.",
                emphasis: paceText
            ),
            HatchInsight(
                id: "cadence",
                title: "Mutation Trigger",
                detail: "케이던스 \(cadenceText) spm 기준으로 \(variantText) 트랙을 판정했습니다.",
                emphasis: variantText
            ),
        ]
    }

    static func evolutionTarget(
        for snapshot: CompanionProgressionSnapshot,
        pet: GeneratedPet,
        recentRun: CompletedRunRecord?,
        season: WeeklySeason
    ) -> EvolutionTarget {
        let progress = snapshot.progress
        let petName = pet.species.displayName

        if progress.stageLabel == RunimalBalanceConfig.finalStageLabel {
            let nextLateGrowth = snapshot.lateGrowthWindow.last { $0.requiredLevel > snapshot.level }
            return EvolutionTarget(
                title: "성년기 운영 시작",
                detail: "\(petName)은 이미 성년기입니다. 이제 남은 성장은 기록 질과 후반 해금 관리로 갈립니다.",
                status: "mature live",
                focusTitle: "지금 상태",
                focusDetail: "풍부한 운동 기록, 시즌 정합, 저장 잠재 운용이 후반부 품질을 좌우합니다.",
                actionTitle: "바로 할 행동",
                actionDetail: "기록 밀도가 높은 러닝을 모으고, 같은 동행과 함께 달려 저장 잠재를 다시 쌓으세요.",
                checkpointTitle: "다음 확인",
                checkpointDetail: nextLateGrowth.map { "다음 후반 해금은 Lv.\($0.requiredLevel) \($0.title)입니다." }
                    ?? "Lv.50 완성 기록 구간에 도달하면 최고 단계 표식이 열립니다.",
                badges: [
                    progress.stageLabel,
                    season.title,
                    "XP \(progress.totalExperience)"
                ]
            )
        }

        if progress.progressRatio >= 0.92 {
            return EvolutionTarget(
                title: "진화 임계점 접근",
                detail: "다음 한 번의 강한 러닝으로 진화 연출을 열 수 있습니다.",
                status: "almost there",
                focusTitle: "지금 상태",
                focusDetail: "\(petName)은 현재 \(progress.stageLabel) 막바지에 있습니다. 이번 구간은 기록 한 번의 질이 그대로 다음 단계로 연결됩니다.",
                actionTitle: "바로 할 행동",
                actionDetail: "페이스와 케이던스를 안정적으로 맞춘 러닝 하나를 더 만들고, 기록 밀도 보너스를 챙기세요.",
                checkpointTitle: "확인 기준",
                checkpointDetail: "현재 게이지가 \(Int((progress.progressRatio * 100).rounded()))%입니다. 다음 기록 반영 뒤 단계 상승 연출이 열리면 성공입니다.",
                badges: [
                    progress.stageLabel,
                    "임계 \(Int((progress.progressRatio * 100).rounded()))%"
                ]
            )
        }

        if let recentRun, recentRun.reward.pet.rareVariant != nil {
            let variantLabel = recentRun.reward.pet.rareVariant.map { RareVariantMeta.labels[$0] ?? $0.rawValue } ?? "희귀 경로"
            return EvolutionTarget(
                title: "희귀 변이 유지",
                detail: "다음 러닝도 비슷한 리듬을 유지하면 상위 트랙으로 연결될 가능성이 높습니다.",
                status: "variant chain",
                focusTitle: "지금 상태",
                focusDetail: "\(variantLabel) 흔적이 최근 러닝에 남아 있습니다. 리듬이 흔들리면 희귀 경로가 끊길 수 있습니다.",
                actionTitle: "바로 할 행동",
                actionDetail: "최근 기록과 비슷한 페이스, 케이던스, 시간대를 한 번 더 재현해 같은 결을 이어 가세요.",
                checkpointTitle: "확인 기준",
                checkpointDetail: "다음 러닝에서도 희귀 반응 또는 같은 변이 계열 문구가 다시 잡히면 체인이 유지됩니다.",
                badges: [
                    variantLabel,
                    progress.stageLabel
                ]
            )
        }

        return EvolutionTarget(
            title: "안정 페이스 누적",
            detail: "5km 이상 안정적으로 유지하는 러닝을 반복하면 상위 성장 단계가 빨라집니다.",
            status: "\(progress.totalExperience) XP",
            focusTitle: "지금 상태",
            focusDetail: "\(petName)은 아직 성장 준비 구간입니다. 지금은 한 번의 폭발보다 반복 가능한 안정 러닝이 더 중요합니다.",
            actionTitle: "바로 할 행동",
            actionDetail: "5km 안팎의 안정 러닝을 몇 번 더 쌓아 기본 성장선과 기록 태그를 먼저 단단하게 만드세요.",
            checkpointTitle: "다음 확인",
            checkpointDetail: snapshot.nextEvolutionMilestone.map { "다음 진화 기준은 Lv.\($0.requiredLevel) · \($0.requiredExperience) XP입니다." }
                ?? "다음 단계 기준이 열리면 성장 카드에 자동으로 표시됩니다.",
            badges: [
                progress.stageLabel,
                season.title,
                "XP \(progress.totalExperience)"
            ]
        )
    }

    static func hatchMomentNarrative(
        egg: EggInventoryEntry,
        pet: PetCollectionEntry,
        sourceRun: CompletedRunRecord? = nil
    ) -> CompanionMomentNarrative {
        let petName = pet.pet.species.displayName
        let shellLabel = RunimalEggEngine.title(for: egg.shell)
        let rareVariantLabel = pet.pet.rareVariant.flatMap { RareVariantMeta.labels[$0] ?? $0.rawValue }
        let incubationCount = egg.incubationRunIDs.count
        let coreLabel = sourceRun?.reward.coreLabel ?? egg.title
        let liveCompanionName = sourceRun?.liveCompanionName
        let livePotential = sourceRun?.livePotentialProfile?.storedPotentialExperience ?? 0
        let episodeTitle = sourceRun?.worldImpact?.episodeTitle

        let title: String
        let detail: String

        if let rareVariantLabel {
            title = "\(rareVariantLabel) 흔적이 고정됨"
            detail = "\(coreLabel)의 궤적이 껍질 안에서 오래 남아 \(petName)의 특별한 결로 굳었습니다."
        } else if let episodeTitle {
            title = "\(episodeTitle) 신호가 이어짐"
            detail = "\(coreLabel)의 운동 기록이 \(episodeTitle) 쪽의 장면과 맞물리며 \(petName)으로 정착됐습니다."
        } else if let liveCompanionName, livePotential > 0 {
            title = "함께 달린 반응이 생명으로 굳음"
            detail = "\(liveCompanionName)와 함께 쌓인 잠재 반응이 \(coreLabel)의 리듬과 겹치며 \(petName)이 깨어났습니다."
        } else if incubationCount > 0 {
            title = "여러 기록이 한 모습으로 모임"
            detail = "첫 기록 \(coreLabel) 위에 \(incubationCount)개의 운동 기록이 더 포개지며 \(petName)의 형태가 완성됐습니다."
        } else {
            title = "\(shellLabel) 신호가 형태를 얻음"
            detail = "\(coreLabel)에서 남은 첫 흔적이 바로 \(petName)의 시작점이 됐습니다."
        }

        var badges = [shellLabel]
        if let rareVariantLabel {
            badges.append(rareVariantLabel)
        }
        if livePotential > 0 {
            badges.append("잠재 +\(livePotential)")
        }
        if let episodeTitle {
            badges.append(episodeTitle)
        }

        return CompanionMomentNarrative(
            title: title,
            detail: detail,
            emphasis: rareVariantLabel ?? coreLabel,
            badges: badges
        )
    }

    static func growthMomentNarrative(
        pet: GeneratedPet,
        outcome: CompanionFeedOutcome
    ) -> CompanionMomentNarrative {
        let petName = pet.species.displayName
        let movedStage = outcome.beforeProgress.stageLabel != outcome.afterProgress.stageLabel
        let finalStageReached = movedStage && outcome.afterProgress.stageLabel == RunimalBalanceConfig.finalStageLabel

        let title: String
        let detail: String

        if finalStageReached {
            title = "성년기 문턱을 넘음"
            detail = "\(outcome.coreLabel)의 기록이 마지막 성장선을 밀어 올리며 \(petName)이 성년기 흐름에 들어섰습니다."
        } else if movedStage && outcome.potentialExperienceSpent > 0 && outcome.dataBonusExperience > 0 {
            title = "기록과 잠재가 함께 터짐"
            detail = "풍부한 운동 기록과 저장 잠재가 한 번에 겹치며 \(petName)이 \(outcome.afterProgress.stageLabel) 단계로 넘어섰습니다."
        } else if movedStage && outcome.potentialExperienceSpent > 0 {
            title = "저장 잠재가 성장선을 넘김"
            detail = "함께 달리며 쌓아 둔 잠재가 이번 기록과 맞물리며 \(petName)을 \(outcome.afterProgress.stageLabel) 단계로 밀어 올렸습니다."
        } else if movedStage && outcome.dataBonusExperience > 0 {
            title = "풍부한 기록이 임계선을 넘김"
            detail = "\(outcome.coreLabel)의 정보량이 임계선을 직접 넘기며 \(petName)이 \(outcome.afterProgress.stageLabel) 단계에 닿았습니다."
        } else if outcome.potentialExperienceSpent > 0 && outcome.dataBonusExperience > 0 {
            title = "다음 단계 쪽으로 크게 당겨짐"
            detail = "기록 밀도와 저장 잠재가 같이 붙어 \(petName)의 다음 성장선이 눈에 띄게 가까워졌습니다."
        } else if outcome.potentialExperienceSpent > 0 {
            title = "저장 잠재가 이번 성장에 붙음"
            detail = "같이 달리며 남긴 잠재가 이번 기록에 실려 \(petName)의 성장 속도를 끌어올렸습니다."
        } else if outcome.dataBonusExperience > 0 {
            title = "풍부한 기록이 깊게 스며듦"
            detail = "\(outcome.coreLabel)의 정보량이 높아 일반 기록보다 더 깊은 성장 흔적을 남겼습니다."
        } else {
            title = "기본 성장선이 안정적으로 이어짐"
            detail = "\(outcome.coreLabel)의 운동 기록이 \(petName)의 현재 성장 흐름을 차분하게 밀어 줬습니다."
        }

        var badges = ["+\(outcome.gainedExperience) XP"]
        if movedStage {
            badges.append(outcome.afterProgress.stageLabel)
        }
        if outcome.dataBonusExperience > 0 {
            badges.append("기록 밀도 +\(outcome.dataBonusExperience)")
        }
        if outcome.potentialExperienceSpent > 0 {
            badges.append("잠재 +\(outcome.potentialExperienceSpent)")
        }

        return CompanionMomentNarrative(
            title: title,
            detail: detail,
            emphasis: movedStage ? outcome.afterProgress.stageLabel : outcome.coreLabel,
            badges: badges
        )
    }

    static func postGrowthTarget(
        pet: GeneratedPet,
        outcome: CompanionFeedOutcome,
        season: WeeklySeason
    ) -> EvolutionTarget {
        let afterSnapshot = outcome.afterSnapshot
        let afterProgress = outcome.afterProgress
        let petName = pet.species.displayName
        let currentUnlock = afterSnapshot.stageUnlockWindow.first { $0.stageLabel == afterProgress.stageLabel }
            ?? afterSnapshot.stageUnlockWindow.first

        if outcome.stageAdvanced && afterProgress.stageLabel == RunimalBalanceConfig.finalStageLabel {
            let nextLateGrowth = afterSnapshot.lateGrowthWindow.last { $0.requiredLevel > afterSnapshot.level }
            let matureFocus = currentUnlock?.summary ?? "성년기 이후에는 기록 품질과 후반 해금이 핵심입니다."
            return EvolutionTarget(
                title: "성년기 운영 시작",
                detail: "\(petName)은 이제 성년기입니다. 진화 완료가 끝이 아니라 후반 운영 구간이 열린 상태입니다.",
                status: "mature reached",
                focusTitle: "지금 상태",
                focusDetail: matureFocus,
                actionTitle: "바로 할 행동",
                actionDetail: "같은 동행과 함께 달려 잠재를 다시 쌓고, 기록 태그가 풍부한 운동 기록을 골라 후반 해금을 압축하세요.",
                checkpointTitle: "다음 확인",
                checkpointDetail: nextLateGrowth.map { "다음 후반 해금은 Lv.\($0.requiredLevel) \($0.title)입니다. \($0.summary)" }
                    ?? "Lv.50 완성 기록 구간까지 가면 최고 단계 표식과 최종 기록 정리가 열립니다.",
                badges: [
                    afterProgress.stageLabel,
                    "Lv.\(afterSnapshot.level)",
                    season.title
                ]
            )
        }

        if outcome.stageAdvanced {
            let nextMilestone = afterSnapshot.nextEvolutionMilestone
            let nextUnlock = afterSnapshot.stageUnlockWindow.last { $0.stageLabel != afterProgress.stageLabel }
            let unlockedFeatures = currentUnlock?.unlockedFeatures.prefix(2).joined(separator: " · ")
            let focusDetail: String
            if let currentUnlock {
                focusDetail = "\(currentUnlock.summary) 지금 구간에서 열리는 핵심은 \(unlockedFeatures ?? currentUnlock.title)입니다."
            } else {
                focusDetail = "\(petName)은 이번 반영으로 \(afterProgress.stageLabel) 운영 구간에 들어왔습니다."
            }

            let actionDetail: String
            if let currentUnlock {
                actionDetail = currentUnlock.nextFocus
            } else {
                actionDetail = "이번에 열린 반응을 바로 체감할 수 있도록 비슷한 리듬의 운동 기록을 한두 번 더 이어 붙이세요."
            }

            let checkpointDetail: String
            if let nextMilestone {
                checkpointDetail = "다음 진화 기준은 Lv.\(nextMilestone.requiredLevel) · \((nextMilestone.requiredExperience)) XP입니다. \(nextUnlock?.title ?? nextMilestone.stageLabel) 쪽 문구가 보이면 흐름이 맞습니다."
            } else if let nextLateGrowth = afterSnapshot.lateGrowthWindow.last(where: { $0.requiredLevel > afterSnapshot.level }) {
                checkpointDetail = "다음 후반 해금은 Lv.\(nextLateGrowth.requiredLevel) \(nextLateGrowth.title)입니다."
            } else {
                checkpointDetail = "현재 단계 전용 반응이 기록 상세와 성장 카드에서 안정적으로 보이면 운영이 자리 잡은 상태입니다."
            }

            var badges = [
                "단계 상승",
                afterProgress.stageLabel,
                "Lv.\(afterSnapshot.level)"
            ]
            if let currentUnlock {
                badges.append(contentsOf: currentUnlock.unlockedFeatures.prefix(1))
            }

            return EvolutionTarget(
                title: "\(afterProgress.stageLabel) 운영 시작",
                detail: "\(outcome.beforeProgress.stageLabel)에서 \(afterProgress.stageLabel)로 넘어왔습니다. 이제 막 열린 기능을 바로 써보는 구간입니다.",
                status: "stage advanced",
                focusTitle: "지금 상태",
                focusDetail: focusDetail,
                actionTitle: "바로 할 행동",
                actionDetail: actionDetail,
                checkpointTitle: "다음 확인",
                checkpointDetail: checkpointDetail,
                badges: badges
            )
        }

        return evolutionTarget(
            for: afterSnapshot,
            pet: pet,
            recentRun: nil,
            season: season
        )
    }

    static func shareMilestoneTarget(
        kind: ShareMilestoneKind,
        unlocked: Bool,
        snapshot: CompanionProgressionSnapshot,
        pet: GeneratedPet,
        season: WeeklySeason,
        collectionCount: Int
    ) -> EvolutionTarget {
        switch kind {
        case .firstHatch:
            if unlocked {
                return EvolutionTarget(
                    title: "첫 부화 기록 확보",
                    detail: "이제 첫 시작점은 열렸습니다. 다음 공유 순간은 희귀 변이 또는 성년기입니다.",
                    status: "first hatch unlocked",
                    focusTitle: "지금 상태",
                    focusDetail: "컬렉션에 첫 부화 동행이 생겼고, 공유 가능한 시작 장면이 확보됐습니다.",
                    actionTitle: "바로 할 행동",
                    actionDetail: "이제는 같은 아이를 조금 더 밀어 희귀 변이나 단계 상승 쪽 대표 순간을 만드세요.",
                    checkpointTitle: "확인 기준",
                    checkpointDetail: "희귀 변이 동행이 생기거나 현재 동행이 성년기에 닿으면 다음 공유 카드가 열립니다.",
                    badges: [
                        "첫 부화",
                        "컬렉션 \(collectionCount)"
                    ]
                )
            }

            return EvolutionTarget(
                title: "첫 부화 열기",
                detail: "공유의 시작점은 첫 동행이 태어나는 순간입니다.",
                status: "first hatch locked",
                focusTitle: "지금 상태",
                focusDetail: "아직 컬렉션에 부화한 동행이 없습니다. 지금은 첫 기록을 생명으로 바꾸는 구간입니다.",
                actionTitle: "바로 할 행동",
                actionDetail: "지금 선택한 알에 운동 기록을 넣어 부화 준비를 진행하거나, 새 알을 먼저 만들어 첫 부화 조건을 여세요.",
                checkpointTitle: "확인 기준",
                checkpointDetail: "컬렉션에 첫 부화 동행이 생기면 이 카드가 바로 열립니다.",
                badges: [
                    "잠금",
                    "첫 시작"
                ]
            )

        case .rareVariant:
            if unlocked {
                return EvolutionTarget(
                    title: "희귀 경로 확보",
                    detail: "희귀 변이 카드가 열렸습니다. 이제 중요한 건 같은 결을 유지하는 겁니다.",
                    status: "rare unlocked",
                    focusTitle: "지금 상태",
                    focusDetail: "희귀 변이 한 번이 아니라, 반복 가능한 희귀 경로를 증명할 수 있는 구간입니다.",
                    actionTitle: "바로 할 행동",
                    actionDetail: "최근 희귀 반응과 비슷한 페이스, 케이던스, 시간대를 한두 번 더 재현해 같은 계열 신호를 이어 가세요.",
                    checkpointTitle: "확인 기준",
                    checkpointDetail: "다음 러닝에서도 희귀 경로 문구나 같은 변이 계열이 다시 잡히면 체인이 안정된 상태입니다.",
                    badges: [
                        "희귀 변이",
                        season.title
                    ]
                )
            }

            return EvolutionTarget(
                title: "희귀 경로 만들기",
                detail: "한 번의 선명한 러닝 패턴이 공유 가치가 높은 희귀 순간을 엽니다.",
                status: "rare locked",
                focusTitle: "지금 상태",
                focusDetail: "아직 희귀 변이 동행이 없습니다. 안정 페이스만으로는 부족하고, 선명한 리듬과 상황 조건이 필요합니다.",
                actionTitle: "바로 할 행동",
                actionDetail: "고케이던스나 장거리 안정 구간, 돌발 목표, 시즌 정합을 한 러닝에 겹치게 만들어 희귀 반응을 노리세요.",
                checkpointTitle: "확인 기준",
                checkpointDetail: "컬렉션에 희귀 변이 동행이 생기거나 러닝 결과에 희귀 경로 문구가 잡히면 이 카드가 열립니다.",
                badges: [
                    "잠금",
                    "희귀 목표"
                ]
            )

        case .mythic:
            if unlocked {
                let nextLateGrowth = snapshot.lateGrowthWindow.last { $0.requiredLevel > snapshot.level }
                return EvolutionTarget(
                    title: "성년기 공유 확정",
                    detail: "최종 공유 카드는 열렸고, 이제는 후반 운영의 질을 기록으로 남기는 구간입니다.",
                    status: "mythic unlocked",
                    focusTitle: "지금 상태",
                    focusDetail: "현재 \(pet.species.displayName)은 성년기이며, 공유 기준도 단순 도달이 아니라 어떤 기록을 남기느냐로 넘어갔습니다.",
                    actionTitle: "바로 할 행동",
                    actionDetail: "풍부한 운동 기록과 저장 잠재를 모아 후반 해금 카드까지 함께 묶이는 완성 장면을 만드세요.",
                    checkpointTitle: "확인 기준",
                    checkpointDetail: nextLateGrowth.map { "다음 후반 해금은 Lv.\($0.requiredLevel) \($0.title)입니다." }
                        ?? "Lv.50 완성 기록에 닿으면 최고 단계 공유 흐름까지 정리됩니다.",
                    badges: [
                        "성년기",
                        "Lv.\(snapshot.level)"
                    ]
                )
            }

            let nextMilestone = snapshot.nextEvolutionMilestone
            return EvolutionTarget(
                title: "성년기 카드 준비",
                detail: "공유의 정점은 성년기 도달입니다. 지금은 그 직전까지 성장선을 관리하는 구간입니다.",
                status: "mythic locked",
                focusTitle: "지금 상태",
                focusDetail: "현재 단계는 \(snapshot.progress.stageLabel)이며, 공유 카드가 열리기 전 마지막 큰 목표는 성년기 도달입니다.",
                actionTitle: "바로 할 행동",
                actionDetail: nextMilestone.map { "운동 기록과 잠재를 모아 먼저 Lv.\($0.requiredLevel) · \($0.requiredExperience) XP 기준을 넘기세요." }
                    ?? "운동 기록 밀도와 잠재를 함께 관리해 남은 성장선을 밀어 올리세요.",
                checkpointTitle: "확인 기준",
                checkpointDetail: nextMilestone.map { "다음 진화 기준은 Lv.\($0.requiredLevel) · \($0.requiredExperience) XP입니다. 성년기에 닿는 순간 이 카드가 열립니다." }
                    ?? "성년기 도달 문구와 함께 완성 포스터가 열리면 목표 달성입니다.",
                badges: [
                    snapshot.progress.stageLabel,
                    "Lv.\(snapshot.level)"
                ]
            )
        }
    }

    static func shareMilestoneProgress(
        kind: ShareMilestoneKind,
        unlocked: Bool,
        snapshot: CompanionProgressionSnapshot,
        pet: GeneratedPet,
        season: WeeklySeason,
        collectionCount: Int,
        eggInventory: [EggInventoryEntry]
    ) -> ShareMilestoneProgress {
        if unlocked {
            switch kind {
            case .firstHatch:
                let nextRare = rareVariantReadinessProgress(
                    snapshot: snapshot,
                    pet: pet,
                    season: season,
                    collectionCount: collectionCount
                )
                return ShareMilestoneProgress(
                    progress: nextRare.progress,
                    label: "다음 희귀 준비도 \(Int((nextRare.progress * 100).rounded()))%",
                    detail: "첫 부화는 완료됐습니다. \(nextRare.detail)"
                )
            case .rareVariant:
                let mythicProgress = mythicMilestoneProgress(snapshot: snapshot)
                return ShareMilestoneProgress(
                    progress: mythicProgress.progress,
                    label: "다음 성년기 준비 \(Int((mythicProgress.progress * 100).rounded()))%",
                    detail: "희귀 순간은 확보됐습니다. \(mythicProgress.detail)"
                )
            case .mythic:
                return lateGrowthProgress(snapshot: snapshot)
            }
        }

        switch kind {
        case .firstHatch:
            guard let leadingEgg = eggInventory.max(by: {
                if $0.progressRatio == $1.progressRatio {
                    return $0.storedExperience < $1.storedExperience
                }
                return $0.progressRatio < $1.progressRatio
            }) else {
                return ShareMilestoneProgress(
                    progress: 0,
                    label: "알 준비 0%",
                    detail: "아직 알이 없습니다. 먼저 새 알을 만들거나 지금 있는 기록으로 부화 준비를 시작하세요."
                )
            }

            return ShareMilestoneProgress(
                progress: leadingEgg.progressRatio,
                label: "알 준비 \(Int((leadingEgg.progressRatio * 100).rounded()))%",
                detail: "\(leadingEgg.title) · \(leadingEgg.storedExperience)/\(leadingEgg.hatchThreshold) XP"
            )

        case .rareVariant:
            let readiness = rareVariantReadinessProgress(
                snapshot: snapshot,
                pet: pet,
                season: season,
                collectionCount: collectionCount
            )
            return ShareMilestoneProgress(
                progress: readiness.progress,
                label: "희귀 준비도 \(Int((readiness.progress * 100).rounded()))%",
                detail: readiness.detail
            )

        case .mythic:
            return mythicMilestoneProgress(snapshot: snapshot)
        }
    }

    private static func rareVariantReadinessProgress(
        snapshot: CompanionProgressionSnapshot,
        pet: GeneratedPet,
        season: WeeklySeason,
        collectionCount: Int
    ) -> ShareMilestoneProgress {
        let seasonScore = RunimalGameEngine.seasonAffinity(for: pet, season: season) ? 0.18 : 0
        let stageScore = min(Double(snapshot.stageIndex) / 4.0, 1) * 0.42
        let growthScore = snapshot.progress.progressRatio * 0.28
        let collectionScore = min(Double(max(collectionCount - 1, 0)) / 4.0, 1) * 0.12
        let readiness = min(stageScore + growthScore + seasonScore + collectionScore, 0.92)

        var detailParts = ["현재 \(snapshot.progress.stageLabel)"]
        if RunimalGameEngine.seasonAffinity(for: pet, season: season) {
            detailParts.append("\(season.title) 호흡 일치")
        }
        if collectionCount > 1 {
            detailParts.append("컬렉션 \(collectionCount)")
        }

        return ShareMilestoneProgress(
            progress: readiness,
            label: "희귀 준비도 \(Int((readiness * 100).rounded()))%",
            detail: detailParts.joined(separator: " · ")
        )
    }

    private static func mythicMilestoneProgress(
        snapshot: CompanionProgressionSnapshot
    ) -> ShareMilestoneProgress {
        let finalMilestone = snapshot.evolutionMilestones.last
        let finalExperience = max(
            max(finalMilestone?.requiredExperience ?? 0, snapshot.progress.nextThreshold),
            1
        )
        let progress = min(Double(snapshot.progress.totalExperience) / Double(finalExperience), 1)
        let remainingExperience = max(finalExperience - snapshot.progress.totalExperience, 0)
        let targetLevel = finalMilestone?.requiredLevel ?? snapshot.level

        return ShareMilestoneProgress(
            progress: progress,
            label: "성년기까지 \(remainingExperience) XP",
            detail: "현재 Lv.\(snapshot.level) · 목표 Lv.\(targetLevel)"
        )
    }

    private static func lateGrowthProgress(
        snapshot: CompanionProgressionSnapshot
    ) -> ShareMilestoneProgress {
        let nextLateGrowth = RunimalBalanceConfig.companionLateGrowthMilestones.first {
            snapshot.level < $0.requiredLevel
        }

        guard let nextLateGrowth else {
            return ShareMilestoneProgress(
                progress: 1,
                label: "완성 기록 구간 완료",
                detail: "Lv.50 완성 기록까지 도달했습니다. 이제 최고 단계 기록만 쌓으면 됩니다."
            )
        }

        let previousLevel = RunimalBalanceConfig.companionLateGrowthMilestones
            .last { $0.requiredLevel <= snapshot.level }?
            .requiredLevel ?? RunimalBalanceConfig.evolutionMilestones(for: nil).last?.requiredLevel ?? 1
        let lowerBoundExperience = RunimalBalanceConfig.companionExperienceTotal(forLevel: previousLevel)
        let upperBoundExperience = RunimalBalanceConfig.companionExperienceTotal(forLevel: nextLateGrowth.requiredLevel)
        let boundedExperience = min(max(snapshot.progress.totalExperience, lowerBoundExperience), upperBoundExperience)
        let progress = upperBoundExperience == lowerBoundExperience
            ? 1
            : min(
                max(
                    Double(boundedExperience - lowerBoundExperience) / Double(upperBoundExperience - lowerBoundExperience),
                    0
                ),
                1
            )
        let remainingXP = max(upperBoundExperience - snapshot.progress.totalExperience, 0)

        return ShareMilestoneProgress(
            progress: progress,
            label: "다음 후반 해금까지 \(remainingXP) XP",
            detail: "목표 Lv.\(nextLateGrowth.requiredLevel) \(nextLateGrowth.title)"
        )
    }

    static func liveGoals(for snapshot: LiveRunSnapshot, claimedRewardIDs: Set<String> = []) -> [LiveGoalTarget] {
        let pace = snapshot.averagePaceSeconds ?? 360
        let cadence = snapshot.cadence ?? 166
        let distanceKm = snapshot.distanceMeters / 1000
        let rareDistanceTarget = claimedRewardIDs.contains("weekly-core-cache") ? 8.5 : 10.0
        let tempoPaceTarget = claimedRewardIDs.contains("weekly-core-cache") ? 325 : 315
        let tempoCadenceTarget = claimedRewardIDs.contains("weekly-core-cache") ? 170 : 172

        let tempoCadenceProgress = min(Double(cadence) / Double(tempoCadenceTarget), 1)
        let tempoPaceProgress = min(Double(tempoPaceTarget) / Double(max(pace, 1)), 1)
        let tempoProgress = min((tempoCadenceProgress + tempoPaceProgress) / 2, 1)

        let zenDistanceProgress = min(distanceKm / rareDistanceTarget, 1)
        let zenPaceProgress = min(Double(RunimalBalanceConfig.steadyPaceSeconds) / Double(max(pace, 1)), 1)
        let zenProgress = min((zenDistanceProgress + zenPaceProgress) / 2, 1)

        return [
            LiveGoalTarget(
                id: "tempo-window",
                title: "Tempo Surge Window",
                detail: cadence >= tempoCadenceTarget && pace <= tempoPaceTarget
                    ? "지금 템포 변이 창에 들어왔습니다."
                    : "케이던스 \(tempoCadenceTarget) / 페이스 \(formattedPace(seconds: tempoPaceTarget))를 맞추면 열립니다.",
                progress: tempoProgress,
                status: cadence >= tempoCadenceTarget && pace <= tempoPaceTarget ? "ready" : "\(Int(tempoProgress * 100))%"
            ),
            LiveGoalTarget(
                id: "zen-window",
                title: "Zen Bloom Track",
                detail: distanceKm >= rareDistanceTarget && pace <= RunimalBalanceConfig.steadyPaceSeconds
                    ? "장거리 안정 구간이 완성되었습니다."
                    : "\(String(format: "%.1f", max(rareDistanceTarget - distanceKm, 0)))km 더 유지하면 장거리 안정 트랙에 접근합니다.",
                progress: zenProgress,
                status: distanceKm >= rareDistanceTarget && pace <= RunimalBalanceConfig.steadyPaceSeconds ? "armed" : "\(Int(zenProgress * 100))%"
            ),
        ]
    }

    private static func formattedPace(seconds: Int?) -> String {
        guard let seconds, seconds > 0 else { return "--" }
        let minutes = seconds / 60
        return "\(minutes):\(String(format: "%02d", seconds % 60))/km"
    }

    private static func decorate(feedback: LiveRunFeedback, claimedRewardIDs: Set<String>) -> LiveRunFeedback {
        var detail = feedback.detail
        var intensity = feedback.intensity

        if claimedRewardIDs.contains("weekly-badge") {
            detail += " 주간 탄력으로 이번 러닝 XP가 더 오릅니다."
            intensity = min(intensity + 0.03, 1)
        }

        if claimedRewardIDs.contains("weekly-evo-boost") {
            detail += " 성장 가속이 추가 성장 XP를 더해주고 있습니다."
            intensity = min(intensity + 0.05, 1)
        }

        return LiveRunFeedback(
            label: feedback.label,
            headline: feedback.headline,
            detail: detail,
            intensity: intensity
        )
    }
}
