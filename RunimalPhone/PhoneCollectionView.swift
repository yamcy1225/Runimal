import RunimalCore
import SwiftUI

struct PhoneCollectionView: View {
    let store: PhoneDashboardStore
    @State private var showResetAlert = false
    @State private var showDangerZone = false
    @State private var hatchResult: HatchCinematicPayload?

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
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                stableCard
                stableSection
                growthSection
                storageSection
                shareSection
                researchSection
                dangerSection
            }
            .padding(20)
        }
        .fullScreenCover(item: $hatchResult) { payload in
            HatchCinematicView(egg: payload.egg, pet: payload.pet) {
                hatchResult = nil
            }
        }
    }

    private var stableSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("메인 슬롯", detail: "지금 함께 들고 다닐 동행을 정합니다.")
            PhoneCompanionRosterPanel(
                mainSelection: store.mainSelection,
                mainLabel: store.mainSelectionLabel,
                mainDetail: store.mainSelectionDetail,
                companions: store.collection,
                eggs: store.eggInventory,
                onSelectPet: store.activateCompanion(_:),
                onSelectEgg: store.activateEgg(_:),
                onHatchEgg: handleHatch(_:)
            )
            collectionGrid
        }
    }

    private var growthSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("성장", detail: "메인 동행의 진화와 성장만 모아 둡니다.")
            evolutionCard
            PhoneMythicApexPanel(
                pet: store.featuredCompanion.pet,
                progress: store.evolutionProgress,
                season: store.weeklyBoard.season
            )
            if let outcome = store.latestFeedOutcome {
                PhoneFeedCinematicPanel(
                    pet: store.featuredCompanion.pet,
                    outcome: outcome,
                    onDismiss: store.clearFeedOutcome
                )
            }
            PhoneRunCoreDecisionPanel(
                mainSelection: store.mainSelection,
                mainLabel: store.mainSelectionLabel,
                availableRuns: store.availableRunCores,
                eggOpportunity: store.eggOpportunity(for:),
                onFeedPet: store.feedActiveCompanion(with:),
                onForgeEgg: store.forgeEgg(from:),
                onIncubateEgg: store.incubateMainEgg(with:)
            )
            PhonePetDetailPanel(
                companion: store.featuredCompanion,
                progress: store.evolutionProgress,
                activeEffects: store.activeWeeklyEffects,
                season: store.weeklyBoard.season
            )
            growthTimeline
        }
    }

    private var storageSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("보관함", detail: "변이, 효과, 자원을 빠르게 읽습니다.")
            PhoneRareVariantShowcasePanel(activeVariant: store.featuredCompanion.pet.rareVariant)
            collectionEffectStage
            resonanceCompareBoard
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
            sectionHeader("연구실", detail: "고급 성장과 제작 기록을 펼쳐 봅니다.")
        }
        .tint(.white)
    }

    private var shareSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("공유", detail: "가장 자랑할 만한 순간만 따로 모았습니다.")
            PhoneMilestoneSharePanel(
                featuredCompanion: store.featuredCompanion,
                collection: store.collection,
                progress: store.evolutionProgress,
                season: store.weeklyBoard.season
            )
        }
    }

    private func sectionHeader(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.black))
                .tracking(1.2)
                .foregroundStyle(store.mainAccentColor.opacity(0.9))
            Text(detail)
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
            Text(title == "메인 슬롯" ? "메인 한 칸만 먼저 고릅니다." : title == "성장" ? "먹이기와 진화만 바로 이어집니다." : title == "보관함" ? "많이 읽지 않아도 상태가 보이게 정리했습니다." : "펼쳤을 때만 세부 기능이 보입니다.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var stableCard: some View {
        GameSurface(title: "메인 동행체") {
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
                            PixelPetView(pet: store.featuredCompanion.pet, pixelSize: 10, seasonalLayers: store.seasonalLayers)
                        }
                    }
                    .frame(width: 110, height: 110)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.mainSelectionLabel)
                            .font(.title2.weight(.black))
                            .foregroundStyle(.white)
                        Text(store.mainSelectionDetail)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.72))

                        HStack(spacing: 8) {
                            if store.mainSelection?.kind == .egg, let egg = store.mainEgg {
                                TraitChip(label: egg.shell.displayLabel, accent: egg.shell.accentColor)
                                TraitChip(label: egg.readyToHatch ? "디코딩 준비" : "스캔 중", accent: .orange.opacity(0.72))
                            } else {
                                TraitChip(label: "Lv.\(store.featuredCompanion.level)", accent: store.featuredCompanion.pet.accentColor)
                                TraitChip(label: "유대 \(store.featuredCompanion.bond)", accent: .white.opacity(0.28))
                            }
                        }
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
                        title: "러닝 코어",
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

                if store.activeWeeklyEffects.isEmpty == false {
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
        .alert("모든 기록을 초기화할까요?", isPresented: $showResetAlert) {
            Button("초기화", role: .destructive) {
                store.resetProgress()
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("보유 펫, 알, 성장 기록, 주간 보상 상태를 초기 씨드 상태로 되돌립니다.")
        }
    }

    private var dangerSection: some View {
        GameSurface(title: "위험 구역", accent: .red.opacity(0.82), eyebrow: "신중하게 사용") {
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        showDangerZone.toggle()
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("초기화 메뉴 열기")
                                .font(.headline.weight(.black))
                                .foregroundStyle(.white)
                            Text("펼친 뒤에만 리셋 버튼이 보입니다.")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.62))
                        }

                        Spacer()

                        Image(systemName: showDangerZone ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.red.opacity(0.92))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if showDangerZone {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("모든 동행체, 알, 성장 기록을 초기 상태로 되돌립니다. 되돌리기 어렵기 때문에 마지막 구역에 분리했습니다.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.68))

                        Button(role: .destructive) {
                            showResetAlert = true
                        } label: {
                            Label("처음부터 다시 시작", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red.opacity(0.9))
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    private var evolutionCard: some View {
        GameSurface(title: "진화 진행도") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(store.evolutionProgress.stageLabel)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    TraitChip(label: "\(store.evolutionProgress.totalExperience) XP", accent: store.pet.accentColor)
                }

                RunimalProgressBar(progress: store.evolutionProgress.progressRatio, accent: store.pet.accentColor, height: 10)

                Text(store.evolutionProgress.headline)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.72))
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

                        PixelPetView(pet: store.featuredCompanion.pet, pixelSize: 8, seasonalLayers: store.seasonalLayers)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.activeWeeklyEffects.isEmpty ? "아직 활성화된 효과가 없어요" : "현재 적용 중인 효과")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(store.activeWeeklyEffects.isEmpty
                             ? "주간 보상을 받으면 이곳에 성장 효과가 쌓입니다."
                             : "활성 효과가 메인 동행체 성장에 직접 반영됩니다.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }

                if effectResonance.isEmpty == false {
                    ForEach(effectResonance) { effect in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(effect.title)
                                    .foregroundStyle(.white)
                                Spacer()
                                TraitChip(label: "\(effect.intensityLabel) \(effect.score)", accent: .green)
                            }
                            Text(effect.detail)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.68))
                        }
                    }
                }
            }
        }
    }

    private var collectionGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("보유한 동행체")
                .font(.headline)
                .foregroundStyle(.white)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(store.collection) { entry in
                    GameSurface(accent: entry.pet.accentColor, eyebrow: entry.id == store.featuredCompanion.id ? "메인 슬롯" : "보유 중") {
                        VStack(alignment: .leading, spacing: 10) {
                            ZStack(alignment: .topTrailing) {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(entry.pet.accentColor.opacity(0.08))
                                    .frame(maxWidth: .infinity)

                                PixelPetView(
                                    pet: entry.pet,
                                    pixelSize: 8,
                                    seasonalLayers: entry.id == store.featuredCompanion.id ? store.seasonalLayers : []
                                )

                                if entry.id == store.featuredCompanion.id {
                                    RunimalSignalBadge(icon: "star.fill", label: "메인", accent: .green)
                                }
                            }
                            .frame(height: 108)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(entry.pet.accentColor.opacity(0.24), lineWidth: 1)
                            )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.pet.displayName)
                                    .font(.subheadline.weight(.black))
                                    .foregroundStyle(.white)
                                Text(entry.pet.subtitle)
                                    .font(.caption2)
                                    .foregroundStyle(entry.pet.accentColor.opacity(0.88))
                                    .lineLimit(1)
                            }

                            HStack(spacing: 6) {
                                TraitChip(label: "Lv.\(entry.level)", accent: entry.pet.accentColor)
                                TraitChip(label: "\(entry.totalDistanceKm.formatted(.number.precision(.fractionLength(1))))km", accent: .white.opacity(0.24))
                                if let rareVariant = entry.pet.rareVariant {
                                    RunimalSignalBadge(
                                        icon: "sparkles",
                                        label: RareVariantMeta.badges[rareVariant] ?? "희귀",
                                        accent: .orange.opacity(0.76)
                                    )
                                }
                            }

                            RunimalProgressBar(
                                progress: min(Double(entry.level) / 12.0, 1.0),
                                accent: entry.pet.accentColor,
                                height: 7
                            )

                            Button(entry.id == store.featuredCompanion.id ? "선택됨" : "메인으로") {
                                store.activateCompanion(entry.id)
                            }
                            .buttonStyle(.bordered)
                            .tint(entry.pet.accentColor)
                            .disabled(entry.id == store.featuredCompanion.id)
                        }
                    }
                }
            }
        }
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
                                        .font(.subheadline.weight(.black))
                                        .foregroundStyle(.white)
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
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.56))
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
                            .fill(entry.discovered ? store.pet.accentColor : .white.opacity(0.16))
                            .frame(width: 10, height: 10)
                            .padding(.top, 5)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(entry.label)
                                    .foregroundStyle(.white)
                                Spacer()
                                TraitChip(
                                    label: entry.discovered ? "발견" : "잠김",
                                    accent: entry.discovered ? .green : .white.opacity(0.2)
                                )
                            }

                            Text(entry.detail)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.72))
                            Text(entry.passive)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
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
                                .foregroundStyle(.white)
                            Text("\(entry.distanceKm.formatted(.number.precision(.fractionLength(1))))km · \(entry.cadence) spm")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.72))
                            Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.56))
                        }
                    }
                }
            }
        }
    }

    private func handleHatch(_ eggID: String) {
        guard let egg = store.eggInventory.first(where: { $0.id == eggID }) else { return }
        guard let pet = store.hatchEgg(eggID) else { return }
        hatchResult = HatchCinematicPayload(egg: egg, pet: pet)
    }
}

private struct HatchCinematicPayload: Identifiable {
    let egg: EggInventoryEntry
    let pet: PetCollectionEntry

    var id: String {
        egg.id
    }
}
