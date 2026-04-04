import RunimalCore
import SwiftUI

private enum CollectionAnchor: String {
    case stable
    case growth
    case extras
}

struct PhoneCollectionView: View {
    let store: PhoneDashboardStore
    @State private var hatchResult: HatchCinematicPayload?
    @State private var showCollectionExtras = false

    private var worldPack: WorldContentPack {
        store.contentCatalog.worldContentPack()
    }

    private var worldPackSummaries: [ContentPackSummary] {
        store.contentCatalog.worldContentPackSummaries()
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    private var effectResonance: [CompanionEffectResonance] {
        RunimalEffectResonanceEngine.effectResonance(
            for: store.featuredCompanion,
            progress: store.evolutionProgress,
            activeEffects: store.activeWeeklyEffects
        )
    }

    private var resonanceBoard: [CompanionResonanceSummary] {
        RunimalEffectResonanceEngine.compareCollection(
            store.collection,
            progress: store.evolutionProgress,
            activeEffects: store.activeWeeklyEffects
        )
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    stableCard
                    worldAtlasCard
                    stableSection
                        .id(CollectionAnchor.stable.rawValue)
                    growthSection
                        .id(CollectionAnchor.growth.rawValue)
                    storageSection
                    collectionExtrasSection(proxy: proxy)
                        .id(CollectionAnchor.extras.rawValue)
                }
                .padding(20)
            }
            .background(
                ZStack {
                    GameBoyPalette.lightest
                        .ignoresSafeArea()
                    GameBoyLCDOverlay()
                        .ignoresSafeArea()
                }
            )
            .fullScreenCover(item: $hatchResult) { payload in
                HatchCinematicView(
                    egg: payload.egg,
                    pet: payload.pet,
                    sourceRun: payload.sourceRun,
                    renderState: payload.renderState
                ) {
                    hatchResult = nil
                }
            }
        }
    }

    private var worldAtlasCard: some View {
        GameSurface(title: "세계 아틀라스", accent: store.mainAccentColor, eyebrow: "CONTENT") {
            VStack(alignment: .leading, spacing: 12) {
                Text(worldPack.contentPack.playerFacingTheme)
                    .font(.headline.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    TraitChip(label: "활성 팩 \(worldPackSummaries.count)", accent: store.mainAccentColor)
                    TraitChip(label: "변이 \(worldPack.rareVariants.count)", accent: .orange.opacity(0.28))
                    TraitChip(label: "에피소드 \(worldPack.narrativeEpisodes.count)", accent: .mint.opacity(0.28))
                }

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(DefaultWorldContent.packSummaries, id: \.packID) { summary in
                        Button {
                            store.toggleWorldPack(summary.packID)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    Image(systemName: store.activeWorldPackIDs.contains(summary.packID) ? "checkmark.circle.fill" : "circle")
                                        .font(.caption.weight(.black))
                                    Text(summary.title)
                                        .font(.subheadline.monospaced().weight(.black))
                                        .lineLimit(1)
                                }

                                Text(summary.type.uppercased())
                                    .font(.caption2.monospaced().weight(.black))
                                    .foregroundStyle(GameBoyPalette.mediumDark)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(GameBoyPalette.darkest)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        store.activeWorldPackIDs.contains(summary.packID)
                                        ? store.mainAccentColor.opacity(0.14)
                                        : GameBoyPalette.mediumLight.opacity(0.1)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(
                                        store.activeWorldPackIDs.contains(summary.packID)
                                        ? store.mainAccentColor.opacity(0.46)
                                        : GameBoyPalette.darkest.opacity(0.12),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var stableSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("대표 선택", detail: "지금 함께할 주인공을 정합니다.")
            PhoneCompanionRosterPanel(
                mainSelection: store.mainSelection,
                mainLabel: store.mainSelectionLabel,
                mainDetail: store.mainSelectionDetail,
                companions: store.collection,
                eggs: store.eggInventory,
                mutationForm: store.mutationForm(for:),
                mutationHistory: store.mutationHistory(for:),
                pixelRenderState: store.pixelRenderState(for:),
                onSelectPet: store.activateCompanion(_:),
                onSelectEgg: store.activateEgg(_:),
                onHatchEgg: handleHatch(_:)
            )
            collectionGrid
        }
    }

    private var growthSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("성장", detail: "진화와 성장만 빠르게 봅니다.")
            if store.hasOwnedCompanion {
                let renderState = store.pixelRenderState(for: store.featuredCompanion)
                evolutionCard
                PhoneMythicApexPanel(
                    pet: store.featuredCompanion.pet,
                    target: store.evolutionTarget,
                    progress: store.evolutionProgress,
                    season: store.weeklyBoard.season,
                    renderState: renderState
                )
                if let outcome = store.latestFeedOutcome {
                    PhoneFeedCinematicPanel(
                        pet: store.featuredCompanion.pet,
                        outcome: outcome,
                        season: store.weeklyBoard.season,
                        renderState: renderState,
                        onDismiss: store.clearFeedOutcome
                    )
                }
            } else {
                eggOnlyGrowthCard
            }
            PhoneRunCoreDecisionPanel(
                mainSelection: store.mainSelection,
                mainLabel: store.mainSelectionLabel,
                availableRuns: store.availableRunCores,
                eggOpportunity: store.eggOpportunity(for:),
                feedPreview: store.feedProjection(for:),
                routingSummary: store.runCoreRoutingSummary(for:),
                onFeedPet: { _ = store.feedActiveCompanion(with: $0) },
                onForgeEgg: { _ = store.forgeEgg(from: $0) },
                onIncubateEgg: { _ = store.incubateMainEgg(with: $0) }
            )
            if store.hasOwnedCompanion {
                let renderState = store.pixelRenderState(for: store.featuredCompanion)
                PhonePetDetailPanel(
                    companion: store.featuredCompanion,
                    mutationForm: renderState.mutationForm,
                    mutationHistory: renderState.mutationHistory,
                    mutationVisualState: renderState.mutationVisualState,
                    growthStageIndex: renderState.growthStageIndex,
                    mutationEvidence: store.mutationEvidence(for: store.featuredCompanion),
                    worldProfile: store.worldProfile(for: store.featuredCompanion),
                    speciesIdentity: store.speciesIdentity(for: store.featuredCompanion),
                    variantNarrative: store.variantNarrative(for: store.featuredCompanion),
                    worldStatus: store.worldStatus(for: store.featuredCompanion),
                    narrativeSummary: store.narrativeSummary(for: store.featuredCompanion),
                    nextEpisodeFocus: store.nextEpisodeFocus(for: store.featuredCompanion),
                    progress: store.evolutionProgress,
                    activeEffects: store.activeWeeklyEffects,
                    season: store.weeklyBoard.season
                )
                growthTimeline
            }
        }
    }

    private var storageSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("보관함", detail: "변이와 자원을 빠르게 봅니다.")
            if store.hasOwnedCompanion {
                PhoneRareVariantShowcasePanel(activeVariant: store.featuredCompanion.pet.rareVariant)
                collectionEffectStage
                resonanceCompareBoard
            } else {
                eggOnlyStorageCard
            }
        }
    }

    private var researchSection: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 14) {
                PhoneSurplusLabPanel(
                    essenceBalance: store.essenceBalance,
                    offers: store.retirableOffers,
                    onRetire: store.retireCompanion(_:)
                )
                PhoneEssenceForgePanel(
                    essenceBalance: store.essenceBalance,
                    inventory: store.forgeInventory,
                    options: store.forgeOptions,
                    onForge: store.forgeOption(_:)
                )
                PhoneBuildTreePanel(
                    companion: store.featuredCompanion,
                    selectedRole: store.selectedRole,
                    recommendedRoles: store.buildRoles,
                    nodes: store.buildNodes,
                    essenceBalance: store.essenceBalance,
                    onSelectRole: store.selectRole(_:) ,
                    onUnlockNode: store.unlockBuildNode(_:)
                )
                variantCodex
            }
            .padding(.top, 12)
        } label: {
            sectionHeader("연구실", detail: "고급 제작 기록을 확인합니다.")
        }
        .tint(GameBoyPalette.darkest)
    }

    private func shareSection(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("공유", detail: "핵심 순간만 따로 모았습니다.")
            PhoneMilestoneSharePanel(
                featuredCompanion: store.featuredCompanion,
                collection: store.collection,
                eggInventory: store.eggInventory,
                progress: store.evolutionProgress,
                season: store.weeklyBoard.season,
                onOpenFirstHatchFlow: { openFirstHatchFlow(using: proxy) },
                onOpenRareVariantFlow: { openGrowthFlow(using: proxy) },
                onOpenMythicFlow: { openGrowthFlow(using: proxy) }
            )
        }
    }

    private func collectionExtrasSection(proxy: ScrollViewProxy) -> some View {
        DisclosureGroup(isExpanded: $showCollectionExtras) {
            VStack(alignment: .leading, spacing: 18) {
                if store.hasOwnedCompanion {
                    shareSection(proxy: proxy)
                    researchSection
                } else {
                    eggOnlyExtrasCard
                }
            }
            .padding(.top, 12)
        } label: {
            sectionHeader("추가 메뉴", detail: "공유와 제작은 필요할 때만 엽니다.")
        }
        .tint(GameBoyPalette.darkest)
    }

    private func sectionHeader(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.monospaced().weight(.black))
                .tracking(1.2)
                .foregroundStyle(GameBoyPalette.mediumDark)
            Text(detail)
                .font(.headline.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.darkest)
            Text(title == "대표 선택" ? "지금 쓸 대상을 먼저 고릅니다." : title == "성장" ? "먹이기와 성장만 남겼습니다." : title == "보관함" ? "핵심 상태만 먼저 읽습니다." : "필요할 때만 펼쳐 봅니다.")
                .font(.footnote.monospaced())
                .foregroundStyle(GameBoyPalette.mediumDark)
        }
    }

    private func openFirstHatchFlow(using proxy: ScrollViewProxy) {
        if let egg = store.eggInventory.first {
            store.activateEgg(egg.id)
        }
        focusGrowthSection(using: proxy)
    }

    private func openGrowthFlow(using proxy: ScrollViewProxy) {
        if store.mainSelection?.kind != .pet {
            store.activateCompanion(store.featuredCompanion.id)
        }
        focusGrowthSection(using: proxy)
    }

    private func focusGrowthSection(using proxy: ScrollViewProxy) {
        withAnimation(.easeInOut(duration: 0.28)) {
            showCollectionExtras = false
            proxy.scrollTo(CollectionAnchor.growth.rawValue, anchor: .top)
        }
    }

    private var stableCard: some View {
        GameSurface(title: "지금 선택한 대상") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(store.mainAccentColor.opacity(0.16))
                            .frame(width: 104, height: 104)
                            .blur(radius: 10)

                        if store.mainSelection?.kind == .egg {
                            TraceEggView(
                                accent: store.mainAccentColor,
                                shell: store.mainEgg?.shell,
                                pixelSize: 10,
                                cracked: store.mainEgg?.readyToHatch == true,
                                resonance: store.mainEggResonance
                            )
                        } else {
                            let renderState = store.pixelRenderState(for: store.featuredCompanion)
                            PixelPetView(
                                pet: store.featuredCompanion.pet,
                                pixelSize: 10,
                                growthStageIndex: renderState.growthStageIndex,
                                mutationForm: renderState.mutationForm,
                                mutationHistory: renderState.mutationHistory,
                                mutationVisualState: renderState.mutationVisualState,
                                seasonalLayers: store.seasonalLayers
                            )
                        }
                    }
                    .frame(width: 110, height: 110)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.mainSelectionLabel)
                            .font(.title2.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)
                        if let form = store.mutationForm(for: store.featuredCompanion),
                           store.mainSelection?.kind != .egg {
                            Text(form.displayTitle)
                                .font(.caption.monospaced().weight(.black))
                                .foregroundStyle(GameBoyPalette.mediumDark)
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                        }
                        Text(store.mainSelectionDetail)
                            .font(.footnote.monospaced())
                            .foregroundStyle(GameBoyPalette.mediumDark)

                        HStack(spacing: 8) {
                            if store.mainSelection?.kind == .egg, let egg = store.mainEgg {
                                TraitChip(label: egg.shell.displayLabel, accent: egg.shell.accentColor)
                                TraitChip(label: egg.readyToHatch ? "부화 준비" : "확인 중", accent: .orange.opacity(0.72))
                            } else {
                                TraitChip(label: "Lv.\(store.featuredCompanion.level)", accent: store.featuredCompanion.pet.accentColor)
                                TraitChip(label: "유대 \(store.featuredCompanion.bond)", accent: .white.opacity(0.28))
                            }
                        }
                    }
                }

                if store.hasOwnedCompanion,
                   let lore = store.contentCatalog.companionWorldProfile(for: store.featuredCompanion.pet) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(lore.fantasyLine)
                            .font(.footnote.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)
                        Text(lore.habitatLine)
                            .font(.caption.monospaced())
                            .foregroundStyle(GameBoyPalette.mediumDark)
                    }
                }

                HStack(spacing: 12) {
                    RunimalMetricTile(
                        icon: "sparkles",
                        title: "알",
                        value: "\(store.eggInventory.count)",
                        accent: .mint
                    )
                    RunimalMetricTile(
                        icon: "shippingbox.fill",
                        title: "운동 기록",
                        value: "\(store.availableRunCores.count)",
                        accent: store.mainAccentColor
                    )
                    RunimalMetricTile(
                        icon: "hexagon.fill",
                        title: "에센스",
                        value: "\(store.essenceBalance)",
                        accent: .orange
                    )
                }

                if store.hasOwnedCompanion, store.activeWeeklyEffects.isEmpty == false {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(store.activeWeeklyEffects) { effect in
                                TraitChip(label: effect.title, accent: store.featuredCompanion.pet.accentColor.opacity(0.78))
                            }
                        }
                    }
                }
            }
        }
    }

    private var eggOnlyGrowthCard: some View {
        GameSurface(title: "부화 준비도") {
            VStack(alignment: .leading, spacing: 10) {
                Text("아직 부화한 동행이 없습니다.")
                    .font(.headline.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)
                Text("지금은 알만 가지고 있으니 성장 화면도 알 기준으로만 보입니다.")
                    .font(.footnote.monospaced())
                    .foregroundStyle(GameBoyPalette.mediumDark)
                RunimalProgressBar(
                    progress: store.mainEgg?.progressRatio ?? 0,
                    accent: store.mainAccentColor,
                    height: 10
                )
                HStack(spacing: 8) {
                    TraitChip(label: store.mainEgg?.shell.displayLabel ?? "숨김 알", accent: store.mainAccentColor)
                    TraitChip(label: store.mainEgg?.readyToHatch == true ? "부화 가능" : "부화 준비 중", accent: .orange.opacity(0.72))
                }
            }
        }
    }

    private var eggOnlyStorageCard: some View {
        GameSurface(title: "보관함 안내") {
            VStack(alignment: .leading, spacing: 10) {
                Text("동행 보관 정보는 첫 부화 이후 열립니다.")
                    .font(.headline.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)
                Text("지금은 알과 운동 기록만 관리하면 됩니다. 변이, 궁합, 기록 보관은 동행이 생긴 뒤부터 쌓입니다.")
                    .font(.footnote.monospaced())
                    .foregroundStyle(GameBoyPalette.mediumDark)
            }
        }
    }

    private var eggOnlyExtrasCard: some View {
        GameSurface(title: "추가 메뉴 안내") {
            VStack(alignment: .leading, spacing: 10) {
                Text("공유와 연구는 첫 동행 이후 열립니다.")
                    .font(.headline.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)
                Text("지금은 알을 부화시키는 흐름에 집중하면 됩니다. 첫 동행이 생기면 공유 카드와 연구실이 자연스럽게 이어집니다.")
                    .font(.footnote.monospaced())
                    .foregroundStyle(GameBoyPalette.mediumDark)
            }
        }
    }

    private var evolutionCard: some View {
        GameSurface(title: "진화 진행도") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(store.evolutionProgress.stageLabel)
                        .font(.headline.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.darkest)
                    Spacer()
                    TraitChip(label: "\(store.evolutionProgress.totalExperience) XP", accent: store.pet.accentColor)
                }

                RunimalProgressBar(progress: store.evolutionProgress.progressRatio, accent: store.pet.accentColor, height: 10)

                Text(store.evolutionProgress.headline)
                    .font(.footnote.monospaced())
                    .foregroundStyle(GameBoyPalette.mediumDark)
            }
        }
    }

    private var collectionEffectStage: some View {
        GameSurface(title: "활성 효과") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(store.featuredCompanion.pet.accentColor.opacity(0.2))
                            .frame(width: 84, height: 84)
                            .blur(radius: 10)

                        Circle()
                            .stroke(store.featuredCompanion.pet.accentColor.opacity(0.76), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                            .frame(width: 70, height: 70)

                        let renderState = store.pixelRenderState(for: store.featuredCompanion)
                        PixelPetView(
                            pet: store.featuredCompanion.pet,
                            pixelSize: 8,
                            growthStageIndex: renderState.growthStageIndex,
                            mutationForm: renderState.mutationForm,
                            mutationHistory: renderState.mutationHistory,
                            mutationVisualState: renderState.mutationVisualState,
                            seasonalLayers: store.seasonalLayers
                        )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.activeWeeklyEffects.isEmpty ? "아직 활성화된 효과가 없어요" : "현재 적용 중인 효과")
                            .font(.headline.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)
                        Text(store.activeWeeklyEffects.isEmpty
                             ? "주간 보상을 받으면 효과가 쌓입니다."
                             : "활성 효과가 메인 성장에 바로 반영됩니다.")
                            .font(.footnote.monospaced())
                            .foregroundStyle(GameBoyPalette.mediumDark)
                    }
                }

                if effectResonance.isEmpty == false {
                    ForEach(effectResonance) { effect in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(effect.title)
                                    .font(.subheadline.monospaced().weight(.black))
                                    .foregroundStyle(GameBoyPalette.darkest)
                                Spacer()
                                TraitChip(label: "\(effect.intensityLabel) \(effect.score)", accent: .green)
                            }
                            Text(effect.detail)
                                .font(.caption.monospaced())
                                .foregroundStyle(GameBoyPalette.mediumDark)
                        }
                    }
                }
            }
        }
    }

    private var collectionGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("보유한 동행")
                .font(.headline.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.darkest)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(store.collection) { entry in
                    let renderState = store.pixelRenderState(for: entry)
                    GameSurface(
                        accent: entry.pet.accentColor,
                        eyebrow: entry.id == store.mainSelection?.targetID && store.mainSelection?.kind == .pet ? "대표 선택" : "보유 중"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            ZStack(alignment: .topTrailing) {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(GameBoyPalette.lightest)
                                    .frame(maxWidth: .infinity)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(GameBoyPalette.darkest, lineWidth: 2)
                                    )

                                PixelPetView(
                                    pet: entry.pet,
                                    pixelSize: 8,
                                    growthStageIndex: renderState.growthStageIndex,
                                    mutationForm: renderState.mutationForm,
                                    mutationHistory: renderState.mutationHistory,
                                    mutationVisualState: renderState.mutationVisualState,
                                    seasonalLayers: entry.id == store.mainSelection?.targetID && store.mainSelection?.kind == .pet ? store.seasonalLayers : []
                                )

                                if entry.id == store.mainSelection?.targetID && store.mainSelection?.kind == .pet {
                                    RunimalSignalBadge(icon: "star.fill", label: "메인", accent: .green)
                                }
                            }
                            .frame(height: 108)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(entry.pet.accentColor.opacity(0.24), lineWidth: 1)
                            )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.pet.displayName)
                                    .font(.subheadline.monospaced().weight(.black))
                                    .foregroundStyle(GameBoyPalette.darkest)
                                Text(primarySpeciesLabel(for: entry))
                                    .font(.caption2.monospaced().weight(.black))
                                    .foregroundStyle(GameBoyPalette.mediumDark)
                                    .lineLimit(1)
                                if let form = renderState.mutationForm {
                                    Text(form.displayTitle)
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(GameBoyPalette.mediumDark.opacity(0.88))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                            }

                            HStack(spacing: 6) {
                                TraitChip(label: "Lv.\(entry.level)", accent: entry.pet.accentColor)
                                if let rareVariant = entry.pet.rareVariant {
                                    RunimalSignalBadge(
                                        icon: "sparkles",
                                        label: RareVariantMeta.badges[rareVariant] ?? "희귀",
                                        accent: GameBoyPalette.mediumLight
                                    )
                                } else {
                                    TraitChip(
                                        label: "\(entry.totalDistanceKm.formatted(.number.precision(.fractionLength(1))))km",
                                        accent: GameBoyPalette.mediumLight
                                    )
                                }
                            }

                            RunimalProgressBar(
                                progress: RunimalBalanceConfig.companionLevelRatio(for: entry.level),
                                accent: entry.pet.accentColor,
                                height: 7
                            )

                            Text(distanceSupportLine(for: entry))
                                .font(.caption2.monospaced())
                                .foregroundStyle(GameBoyPalette.mediumDark)
                            if let lore = store.contentCatalog.companionWorldProfile(for: entry.pet) {
                                Text(lore.hookLine)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(GameBoyPalette.mediumDark.opacity(0.88))
                                    .lineLimit(2)
                            }

                            Button(entry.id == store.mainSelection?.targetID && store.mainSelection?.kind == .pet ? "선택됨" : "메인으로") {
                                store.activateCompanion(entry.id)
                            }
                            .buttonStyle(.plain)
                            .font(.caption.monospaced().weight(.black))
                            .foregroundStyle(
                                entry.id == store.mainSelection?.targetID && store.mainSelection?.kind == .pet
                                ? GameBoyPalette.lightest
                                : GameBoyPalette.darkest
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(
                                        entry.id == store.mainSelection?.targetID && store.mainSelection?.kind == .pet
                                        ? GameBoyPalette.mediumDark
                                        : GameBoyPalette.lightest
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(GameBoyPalette.darkest, lineWidth: 2)
                                    )
                            )
                            .disabled(entry.id == store.mainSelection?.targetID && store.mainSelection?.kind == .pet)
                        }
                    }
                }
            }
        }
    }

    private func primarySpeciesLabel(for entry: PetCollectionEntry) -> String {
        if let rareVariant = entry.pet.rareVariant {
            return "\(entry.pet.element.displayName.uppercased()) • \(RareVariantMeta.badges[rareVariant] ?? "희귀")"
        }

        return entry.pet.element.displayName.uppercased()
    }

    private func distanceSupportLine(for entry: PetCollectionEntry) -> String {
        if let lore = store.contentCatalog.companionWorldProfile(for: entry.pet),
           let mutationLine = lore.mutationLine {
            return mutationLine
        }

        return "\(entry.totalDistanceKm.formatted(.number.precision(.fractionLength(1)))) km  ·  유대 \(entry.bond)"
    }

    private var resonanceCompareBoard: some View {
        GameSurface(title: "궁합 보드") {
            VStack(alignment: .leading, spacing: 12) {
                if resonanceBoard.isEmpty {
                    Text("비교할 컬렉션 데이터가 아직 없습니다.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.72))
                } else {
                    ForEach(Array(resonanceBoard.prefix(3).enumerated()), id: \.element.id) { index, item in
                        HStack(alignment: .top, spacing: 12) {
                            TraitChip(
                                label: "#\(index + 1)",
                                accent: index == 0 ? .green.opacity(0.82) : .white.opacity(0.18)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.companion.pet.displayName)
                                    .font(.subheadline.monospaced().weight(.black))
                                    .foregroundStyle(GameBoyPalette.darkest)
                                Spacer()
                                TraitChip(
                                    label: "\(item.intensityLabel) \(item.totalScore)",
                                    accent: item.companion.pet.accentColor.opacity(0.82)
                                    )
                                }

                                RunimalProgressBar(
                                    progress: min(Double(item.totalScore) / 100.0, 1.0),
                                    accent: item.companion.pet.accentColor,
                                    height: 7
                                )

                                if let topEffectTitle = item.topEffectTitle {
                                    Text("가장 잘 맞는 효과 · \(topEffectTitle)")
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(GameBoyPalette.mediumDark)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var variantCodex: some View {
        GameSurface(title: "변이 도감") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(store.variantCodex) { entry in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(entry.discovered ? GameBoyPalette.mediumDark : GameBoyPalette.mediumLight)
                            .frame(width: 10, height: 10)
                            .padding(.top, 5)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(entry.label)
                                    .font(.subheadline.monospaced().weight(.black))
                                    .foregroundStyle(GameBoyPalette.darkest)
                                Spacer()
                                TraitChip(
                                    label: entry.discovered ? "발견" : "잠김",
                                    accent: entry.discovered ? .green : GameBoyPalette.mediumLight
                                )
                            }

                            Text(entry.detail)
                                .font(.caption.monospaced())
                                .foregroundStyle(GameBoyPalette.mediumDark)
                            Text(entry.passive)
                                .font(.caption2.monospaced())
                                .foregroundStyle(GameBoyPalette.mediumDark)
                        }
                    }
                }
            }
        }
    }

    private var growthTimeline: some View {
        GameSurface(title: "성장 기록") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(store.recentJournal.prefix(4)) { entry in
                    HStack(alignment: .top, spacing: 12) {
                        PixelPetView(pet: entry.reward.pet, pixelSize: 5)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(entry.reward.pet.displayName) · +\(entry.reward.experience) XP")
                                .font(.subheadline.monospaced().weight(.black))
                                .foregroundStyle(GameBoyPalette.darkest)
                            Text("\(entry.distanceKm.formatted(.number.precision(.fractionLength(1))))km · \(entry.cadence) spm")
                                .font(.caption.monospaced())
                                .foregroundStyle(GameBoyPalette.mediumDark)
                            Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2.monospaced())
                                .foregroundStyle(GameBoyPalette.mediumDark)
                        }
                    }
                }
            }
        }
    }

    private func handleHatch(_ eggID: String) {
        guard let egg = store.eggInventory.first(where: { $0.id == eggID }) else { return }
        let sourceRun = store.completedRuns.first(where: { $0.id == egg.sourceRunID })
        guard let pet = store.hatchEgg(eggID) else { return }
        hatchResult = HatchCinematicPayload(
            egg: egg,
            pet: pet,
            sourceRun: sourceRun,
            renderState: store.pixelRenderState(for: pet)
        )
    }
}

private struct HatchCinematicPayload: Identifiable {
    let egg: EggInventoryEntry
    let pet: PetCollectionEntry
    let sourceRun: CompletedRunRecord?
    let renderState: CompanionPixelRenderState

    var id: String {
        egg.id
    }
}
