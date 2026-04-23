import RunimalCore
import SwiftUI

struct PhoneRunRecordDetailSheet: View {
    let store: PhoneDashboardStore
    let runID: String

    @Environment(\.dismiss) private var dismiss
    @State private var actionFeedback: ActionFeedback?
    @State private var exportDocument: ExportDocument?
    @State private var exportFeedback: ExportFeedback?
    @State private var exportTimeBasis: WorkoutExportTimeBasis = .timer
    @State private var showDeleteConfirmation = false

    private let exportManager = PhoneWorkoutExportManager()

    private var run: CompletedRunRecord? {
        store.completedRuns.first(where: { $0.id == runID })
    }

    private var accent: Color {
        run?.reward.pet.accentColor ?? store.pet.accentColor
    }

    private var canUseRunCore: Bool {
        guard let run else { return false }
        return store.canUseRunCore(run)
    }

    private var eggOpportunity: EggCreationOpportunity? {
        guard let run else { return nil }
        return store.eggOpportunity(for: run)
    }

    private var workoutArchive: WorkoutSessionArchive? {
        store.workoutArchive(for: runID)
    }

    private enum ActionFeedback {
        case fed(CompanionFeedOutcome)
        case forged(EggInventoryEntry)
        case incubated(EggInventoryEntry)
    }

    private struct ExportDocument: Identifiable {
        let id = UUID()
        let url: URL
    }

    private struct ExportFeedback {
        let format: WorkoutExportFormat
        let filename: String
        let bytes: Int
        let timeBasis: WorkoutExportTimeBasis
        let lapCount: Int
        let pauseCount: Int
        let containerLabel: String
    }

    private var usageSummary: RunUsageSummary? {
        guard let run else { return nil }
        return store.runCoreUsageSummary(for: run).map {
            RunUsageSummary(title: $0.title, detail: $0.detail, accent: $0.accent)
        }
    }

    private var runCoreProfile: RunCoreDataProfile? {
        guard let run else { return nil }
        return RunimalRunCoreGrowthBalanceEngine.dataProfile(for: run)
    }

    private var livePotentialProfile: LiveCompanionPotentialProfile? {
        run?.livePotentialProfile
    }

    private var featuredLateGrowthFeatures: CompanionLateGrowthFeatures {
        RunimalBalanceConfig.lateGrowthFeatures(forLevel: store.featuredCompanion.level)
    }

    private var narrativeBeat: RunNarrativeBeat? {
        guard let run else { return nil }
        return store.narrativeBeat(for: run)
    }

    private var routingSummary: PhoneRunCoreRoutingSummary? {
        guard let run else { return nil }
        return store.runCoreRoutingSummary(for: run)
    }

    private struct RunUsageSummary {
        let title: String
        let detail: String
        let accent: Color
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        GameBoyPalette.mediumLight,
                        GameBoyPalette.lightest,
                        GameBoyPalette.mediumLight.opacity(0.88)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                GameBoyLCDOverlay()
                .ignoresSafeArea()

                if let run {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            heroCard(for: run)
                            metricCard(for: run)
                            if let workoutArchive {
                                PhoneWorkoutArchiveSummaryPanel(
                                    archive: workoutArchive,
                                    accent: accent
                                )
                            }
                            actionCard(for: run)
                            if let actionFeedback {
                                feedbackCard(actionFeedback)
                            }
                        }
                        .padding(20)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 36, weight: .black))
                            .foregroundStyle(GameBoyPalette.mediumDark)
                        Text("운동 기록을 찾을 수 없습니다")
                            .font(.headline.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)
                        Text("삭제되었거나 이미 정리된 기록입니다.")
                            .font(.footnote.monospaced())
                            .foregroundStyle(GameBoyPalette.mediumDark)
                    }
                    .padding(24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("닫기")
                            .font(.caption.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.lightest)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(GameBoyPalette.mediumDark)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(GameBoyPalette.darkest, lineWidth: 2)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }

                ToolbarItem(placement: .principal) {
                    Text("운동 기록")
                        .font(.headline.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.darkest)
                }

                if let run {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Text("삭제")
                                .font(.caption.monospaced().weight(.black))
                                .foregroundStyle(store.canDeleteRunRecord(run) ? .red : GameBoyPalette.mediumDark)
                        }
                        .disabled(store.canDeleteRunRecord(run) == false)
                    }
                }
            }
            .toolbarBackground(GameBoyPalette.lightest, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $exportDocument) { document in
                ShareSheet(items: [document.url])
            }
            .alert("이 운동 기록을 삭제할까요?", isPresented: $showDeleteConfirmation) {
                Button("삭제", role: .destructive) {
                    guard let run else { return }
                    if store.deleteRunRecord(id: run.id) {
                        dismiss()
                    }
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("아직 성장이나 알 생성에 쓰이지 않은 기록만 삭제할 수 있습니다.")
            }
        }
    }

    private func heroCard(for run: CompletedRunRecord) -> some View {
        GameSurface(title: run.reward.coreLabel, accent: accent, eyebrow: sourceEyebrow(for: run)) {
            VStack(alignment: .leading, spacing: 14) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(GameBoyPalette.lightest)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(GameBoyPalette.darkest, lineWidth: 2)
                        )

                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(GameBoyPalette.mediumLight.opacity(0.22))
                        .padding(6)

                    GameBoyLCDOverlay()
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                    if !run.route.isEmpty {
                        RoutePreviewShape(points: run.route)
                            .stroke(GameBoyPalette.mediumDark, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                            .padding(26)
                    } else {
                        Image(systemName: "point.bottomleft.forward.to.point.topright.scurvepath")
                            .font(.system(size: 42, weight: .black))
                            .foregroundStyle(GameBoyPalette.mediumDark)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        RunimalSignalBadge(icon: "flame.fill", label: "+\(run.reward.experience) XP", accent: .green)
                        if let runCoreProfile, runCoreProfile.bonusExperience > 0 {
                            RunimalSignalBadge(icon: "square.stack.3d.up.fill", label: "기록 밀도 +\(runCoreProfile.bonusExperience)", accent: .cyan)
                        }
                        if let livePotentialProfile, livePotentialProfile.storedPotentialExperience > 0 {
                            RunimalSignalBadge(icon: "bolt.heart.fill", label: "동행 잠재 +\(livePotentialProfile.storedPotentialExperience)", accent: .orange)
                        }
                        TraitChip(
                            label: canUseRunCore ? "사용 가능" : "사용 완료",
                            accent: canUseRunCore ? .green : .white.opacity(0.18)
                        )
                    }
                    .padding(14)
                }
                .aspectRatio(1, contentMode: .fit)

                Text(summaryLine(for: run))
                    .font(.headline.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)

                if let form = store.mutationForm(for: run) {
                    Text(form.displayTitle)
                        .font(.footnote.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.mediumDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                if let worldProfile = store.contentCatalog.runWorldProfile(for: run) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("\(worldProfile.regionTitle)\(worldProfile.seasonTitle.map { " · \($0)" } ?? "")")
                            .font(.footnote.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)
                        Text(worldProfile.episodeLine ?? worldProfile.summaryLine)
                            .font(.caption.monospaced())
                            .foregroundStyle(GameBoyPalette.mediumDark)
                            .lineLimit(3)
                    }
                }

                if !run.reward.bonusLabels.isEmpty {
                    rewardBonusRail(labels: run.reward.bonusLabels, accent: accent)
                }

                Text(run.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.monospaced())
                    .foregroundStyle(GameBoyPalette.mediumDark)
            }
        }
    }

    private func metricCard(for run: CompletedRunRecord) -> some View {
        GameSurface(title: "러닝 세부 정보", accent: accent, eyebrow: "기록 값") {
            VStack(alignment: .leading, spacing: 12) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    RunimalMetricTile(icon: "map", title: "거리", value: distanceLabel(run.distanceMeters), accent: accent)
                    RunimalMetricTile(icon: "timer", title: "시간", value: durationLabel(run.durationSeconds), accent: .cyan)
                    RunimalMetricTile(icon: "speedometer", title: "평균 페이스", value: paceLabel(run.averagePaceSeconds), accent: .orange)
                    RunimalMetricTile(icon: "waveform.path.ecg", title: "평균 심박", value: heartRateLabel(run.averageHeartRate), accent: .pink)
                    RunimalMetricTile(icon: "figure.run", title: "평균 케이던스", value: cadenceLabel(run.cadence), accent: .mint)
                    RunimalMetricTile(icon: "mountain.2.fill", title: "상승고도", value: "\(run.elevationGainM)m", accent: .yellow)
                }

                HStack(spacing: 8) {
                    TraitChip(label: environmentLabel(run.environmentCondition), accent: .blue.opacity(0.28))
                    if run.rareEventCompleted {
                        TraitChip(label: "희귀 신호 달성", accent: .red.opacity(0.28))
                    }
                    if store.mutationForm(for: run) != nil {
                        TraitChip(label: "변이 기록", accent: accent.opacity(0.18))
                    }
                }

                if let worldProfile = store.contentCatalog.runWorldProfile(for: run) {
                    Text(worldProfile.summaryLine)
                        .font(.caption.monospaced())
                        .foregroundStyle(GameBoyPalette.mediumDark)
                }

                if let runCoreProfile {
                    infoValueCard(
                        title: "기록 가치",
                        headline: dataProfileHeadline(runCoreProfile),
                        detail: "이 기록은 \(runCoreProfile.informationScore)점 정보량으로 계산되며, 먹이 반영 시 추가 보너스가 붙습니다.",
                        badges: runCoreProfile.labels,
                        accent: .cyan
                    )
                }

                if let livePotentialProfile,
                   let liveCompanionName = run.liveCompanionName,
                   livePotentialProfile.storedPotentialExperience > 0 {
                    infoValueCard(
                        title: "동행 잠재치",
                        headline: "\(liveCompanionName) 잠재 성장 · \(livePotentialProfile.eventScore)건",
                        detail: "이 러닝에서 감지된 실시간 반응이 저장형 잠재치로 남았습니다. 아래 이벤트가 많을수록 나중에 같은 동행에게 기록을 먹일 때 보너스가 더 크게 붙습니다.",
                        badges: livePotentialProfile.labels,
                        accent: .orange
                    )
                }

                if store.mainSelection?.kind == .pet,
                   store.featuredCompanion.level >= 31 {
                    infoValueCard(
                        title: "후반 성장 해금",
                        headline: "\(store.featuredCompanion.pet.displayName) Lv.\(store.featuredCompanion.level)",
                        detail: "지금 선택한 동행에게 이 기록을 주면 후반부 해금 기준에 따라 보관 태그와 잠재 반영 폭이 함께 달라집니다.",
                        badges: featuredLateGrowthBadges(for: run),
                        accent: .green
                    )
                }

                if let narrativeBeat {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(narrativeBeat.title)
                                .font(.caption.monospaced().weight(.black))
                                .foregroundStyle(GameBoyPalette.darkest)
                            Spacer()
                            HStack(spacing: 6) {
                                ForEach(Array(narrativeBeat.badges.prefix(2)), id: \.self) { badge in
                                    TraitChip(label: badge, accent: accent.opacity(0.18))
                                }
                            }
                        }

                        Text(narrativeBeat.detail)
                            .font(.caption.monospaced())
                            .foregroundStyle(GameBoyPalette.mediumDark)
                            .lineSpacing(3)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(GameBoyPalette.mediumLight.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(GameBoyPalette.darkest.opacity(0.14), lineWidth: 1)
                            )
                    )
                }

                if let contribution = run.mutationContribution {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("이번 러닝 기여")
                            .font(.caption.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)

                        ForEach(contribution.axes) { axis in
                            HStack(spacing: 8) {
                                Text(axisLabel(axis.axis))
                                    .font(.caption2.monospaced().weight(.black))
                                    .foregroundStyle(GameBoyPalette.mediumDark)
                                    .frame(width: 22, alignment: .leading)
                                Text(axis.branchTitle)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(GameBoyPalette.darkest)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(Int((axis.progress * 100).rounded()))%")
                                    .font(.caption2.monospacedDigit().weight(.black))
                                    .foregroundStyle(GameBoyPalette.mediumDark)
                            }
                        }

                        if let pivot = mutationPivotSummary(for: run) {
                            HStack(spacing: 8) {
                                TraitChip(label: pivot.stageTitle, accent: accent.opacity(0.2))
                                TraitChip(label: pivot.axisTitle, accent: .mint.opacity(0.18))
                                Text(pivot.summary)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(GameBoyPalette.mediumDark)
                                    .lineLimit(1)
                            }
                        }
                    }
                }

                if workoutArchive != nil {
                    exportButtons(for: run)
                }
            }
        }
    }

    @ViewBuilder
    private func actionCard(for run: CompletedRunRecord) -> some View {
        GameSurface(title: "운동 기록 사용", accent: accent, eyebrow: "성장 연결") {
            VStack(alignment: .leading, spacing: 12) {
                if canUseRunCore {
                    Text(actionIntroLine(for: run))
                        .font(.footnote.monospaced())
                        .foregroundStyle(GameBoyPalette.mediumDark)

                    if let routingSummary {
                        infoValueCard(
                            title: routingSummary.title,
                            headline: routingSummary.headline,
                            detail: routingSummary.detail,
                            badges: routingSummary.badges,
                            accent: routingSummary.accent
                        )
                    }

                    if store.mainSelection?.kind == .pet,
                       let preview = store.feedProjection(for: run) {
                        infoValueCard(
                            title: "성장 예상",
                            headline: "Lv.\(preview.beforeSnapshot.level) -> Lv.\(preview.projectedSnapshot.level)",
                            detail: growthPreviewDetail(for: preview),
                            badges: growthPreviewBadges(for: preview),
                            accent: .green
                        )
                    }

                    if store.mainSelection?.kind == .egg, store.mainEgg != nil {
                        pixelActionButton(title: "지금 선택한 알 부화 준비", detail: "이 운동 기록을 알 게이지에 반영합니다.", filled: true) {
                            if let updatedEgg = store.incubateMainEgg(with: run.id) {
                                actionFeedback = .incubated(updatedEgg)
                            }
                        }
                    } else {
                        pixelActionButton(title: "지금 선택한 동행 성장", detail: growthActionDetail(for: run), filled: true) {
                            if let outcome = store.feedActiveCompanion(with: run.id) {
                                actionFeedback = .fed(outcome)
                            }
                        }
                    }

                    if eggOpportunity?.eligible == true {
                        pixelActionButton(title: "새 알 생성", detail: eggOpportunity?.summary ?? "이 코어로 새 알을 만듭니다.") {
                            if let forgedEgg = store.forgeEgg(from: run.id) {
                                actionFeedback = .forged(forgedEgg)
                            }
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(usageSummary?.title ?? "이미 사용한 코어")
                            .font(.headline.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)
                        Text(usageSummary?.detail ?? "이 운동 기록은 이미 성장이나 알 생성에 사용되었습니다.")
                            .font(.footnote.monospaced())
                            .foregroundStyle(GameBoyPalette.mediumDark)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(GameBoyPalette.mediumLight.opacity(0.18), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke((usageSummary?.accent ?? GameBoyPalette.mediumDark).opacity(0.45), lineWidth: 1)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func feedbackCard(_ feedback: ActionFeedback) -> some View {
        switch feedback {
        case .fed(let outcome):
            GameSurface(title: "성장 결과", accent: accent, eyebrow: "기록 반영 완료") {
                VStack(alignment: .leading, spacing: 12) {
                    resultHero(
                        icon: outcome.stageAdvanced ? "arrow.up.right.circle.fill" : "bolt.fill",
                        title: outcome.stageAdvanced ? "단계 상승" : "성장 흡수 완료",
                        detail: "Lv.\(outcome.beforeSnapshot.level) \(outcome.beforeProgress.stageLabel) -> Lv.\(outcome.afterSnapshot.level) \(outcome.afterProgress.stageLabel)"
                    )

                    HStack(spacing: 8) {
                        TraitChip(label: "+\(outcome.gainedExperience) XP", accent: .green)
                        TraitChip(label: "Lv.\(outcome.afterSnapshot.level)", accent: .green.opacity(0.22))
                        TraitChip(label: outcome.afterProgress.stageLabel, accent: accent)
                        if outcome.stageAdvanced {
                            TraitChip(label: "진화 발생", accent: .orange.opacity(0.82))
                        }
                    }

                    pixelProgressPanel(
                        title: "성장 게이지",
                        progress: outcome.afterProgress.progressRatio,
                        accent: accent,
                        detail: outcome.afterProgress.headline
                    )

                    if outcome.potentialExperienceSpent > 0 {
                        infoValueCard(
                            title: "잠재 반영",
                            headline: "저장 잠재 \(outcome.potentialExperienceSpent) XP 사용",
                            detail: outcome.remainingStoredPotentialExperience > 0
                                ? "이번 반영에서 저장 잠재를 사용했고, \(outcome.remainingStoredPotentialExperience) XP가 다음 기록을 위해 남았습니다."
                                : "이번 반영에서 저장 잠재를 모두 사용했습니다. 다음에는 함께 달리며 새 잠재치를 쌓을 수 있습니다.",
                            badges: [
                                "잠재 사용 +\(outcome.potentialExperienceSpent)",
                                "잔여 \(outcome.remainingStoredPotentialExperience)"
                            ],
                            accent: .orange
                        )
                    }

                    if !outcome.bonusLabels.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(outcome.bonusLabels, id: \.self) { bonus in
                                    RunimalSignalBadge(icon: "sparkles", label: bonus, accent: accent)
                                }
                            }
                        }
                    }

                    resultNextStep("다음 추천", detail: outcome.stageAdvanced ? "보관함에서 완성 경로와 새로운 역할 변화를 확인하세요." : "다음 운동 기록을 더 먹이면 다음 단계에 더 빨리 도달할 수 있습니다.")
                }
            }

        case .forged(let egg):
            GameSurface(title: "새 알 생성", accent: accent, eyebrow: "코어 정제 완료") {
                VStack(alignment: .leading, spacing: 12) {
                    resultHero(
                        icon: "sparkles.rectangle.stack.fill",
                        title: "새 알 생성",
                        detail: "코어가 새 쉘로 고정됐습니다."
                    )

                    HStack(spacing: 12) {
                        PhoneEggForgeEffectView(egg: egg)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(egg.title)
                                .font(.headline.monospaced().weight(.black))
                                .foregroundStyle(GameBoyPalette.darkest)
                            Text(egg.shell.hatchHint)
                                .font(.footnote.monospaced())
                                .foregroundStyle(GameBoyPalette.mediumDark)
                        }
                    }

                    pixelProgressPanel(
                        title: "알 생성 게이지",
                        progress: egg.progressRatio,
                        accent: egg.shell.accentColor,
                        detail: "임계치 \(egg.hatchThreshold) XP · 현재 \(egg.storedExperience) XP"
                    )
                    resultNextStep("다음 행동", detail: "지금 선택한 알로 바꾸고 다음 기록을 더 주세요.")
                }
            }

        case .incubated(let egg):
            GameSurface(title: "알 성장 진행", accent: accent, eyebrow: "지금 선택한 알 반영 완료") {
                VStack(alignment: .leading, spacing: 12) {
                    resultHero(
                        icon: egg.readyToHatch ? "checkmark.seal.fill" : "waveform.badge.plus",
                        title: egg.readyToHatch ? "부화 준비 완료" : "부화 준비 중",
                        detail: egg.readyToHatch ? "이제 바로 부화할 수 있습니다." : "다음 코어를 넣으면 부화에 가까워집니다."
                    )

                    HStack(spacing: 12) {
                        TraceEggView(accent: egg.shell.accentColor, shell: egg.shell, resonance: min(max(egg.progressRatio, 0.24), 1))
                            .frame(width: 88, height: 88)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(egg.title)
                                .font(.headline.monospaced().weight(.black))
                                .foregroundStyle(GameBoyPalette.darkest)
                            Text(egg.readyToHatch ? "부화 가능" : "게이지 상승")
                                .font(.footnote.monospaced())
                                .foregroundStyle(GameBoyPalette.mediumDark)
                        }
                    }

                    pixelProgressPanel(
                        title: "부화 게이지",
                        progress: egg.progressRatio,
                        accent: accent,
                        detail: "\(egg.storedExperience) / \(egg.hatchThreshold) XP"
                    )
                    resultNextStep("다음 행동", detail: egg.readyToHatch ? "보관함으로 가서 바로 부화하세요." : "다음 코어를 더 넣어 게이지를 채우세요.")
                }
            }
        }
    }

    private func resultHero(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(GameBoyPalette.lightest)
                    .frame(width: 46, height: 46)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(GameBoyPalette.darkest, lineWidth: 2)
                    )
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(GameBoyPalette.mediumDark)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)
                Text(detail)
                    .font(.footnote.monospaced())
                    .foregroundStyle(GameBoyPalette.mediumDark)
            }
        }
    }

    private func rewardBonusRail(labels: [String], accent: Color) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(labels, id: \.self) { label in
                    RunimalSignalBadge(icon: "sparkles", label: label, accent: accent.opacity(0.82))
                }
            }
            .padding(.vertical, 1)
        }
    }

    private func pixelProgressPanel(title: String, progress: Double, accent: Color, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)
                Spacer()
                Rectangle()
                    .fill(accent.opacity(0.8))
                    .frame(width: 14, height: 4)
            }

            RunimalProgressBar(progress: progress, accent: accent, height: 10)

            Text(detail)
                .font(.caption.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.mediumDark)
        }
        .padding(12)
        .background(GameBoyPalette.mediumLight.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(GameBoyPalette.darkest.opacity(0.22), lineWidth: 1)
        )
    }

    private func resultNextStep(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.darkest)
            Text(detail)
                .font(.footnote.monospaced())
                .foregroundStyle(GameBoyPalette.mediumDark)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GameBoyPalette.mediumLight.opacity(0.18), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func infoValueCard(title: String, headline: String, detail: String, badges: [String], accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)
                Spacer()
                Rectangle()
                    .fill(accent.opacity(0.8))
                    .frame(width: 14, height: 4)
            }

            Text(headline)
                .font(.subheadline.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.darkest)

            Text(detail)
                .font(.caption.monospaced())
                .foregroundStyle(GameBoyPalette.mediumDark)
                .lineSpacing(3)

            if badges.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(badges, id: \.self) { badge in
                            TraitChip(label: badge, accent: accent.opacity(0.18))
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(GameBoyPalette.mediumLight.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(GameBoyPalette.darkest.opacity(0.14), lineWidth: 1)
        )
    }

    private func pixelActionButton(title: String, detail: String, filled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.monospaced().weight(.black))
                Text(detail)
                    .font(.caption.monospaced())
                    .foregroundStyle(filled ? GameBoyPalette.lightest.opacity(0.9) : GameBoyPalette.mediumDark)
            }
            .foregroundStyle(filled ? GameBoyPalette.lightest : GameBoyPalette.darkest)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(filled ? GameBoyPalette.mediumDark : GameBoyPalette.lightest)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(GameBoyPalette.darkest, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func dataProfileHeadline(_ profile: RunCoreDataProfile) -> String {
        switch profile.informationScore {
        case ..<4:
            return "가벼운 기록"
        case 4...7:
            return "균형 잡힌 기록"
        case 8...10:
            return "풍부한 기록"
        default:
            return "매우 풍부한 기록"
        }
    }

    private func actionIntroLine(for run: CompletedRunRecord) -> String {
        let dataBonus = runCoreProfile?.bonusExperience ?? 0
        let feedPreview = store.feedProjection(for: run)
        if let livePotentialProfile,
           let liveCompanionName = run.liveCompanionName,
           livePotentialProfile.storedPotentialExperience > 0 {
            if let feedPreview, feedPreview.potentialExperienceSpent > 0 {
                return "이 운동 기록은 기록 밀도 +\(dataBonus) 보너스를 갖고 있고, 함께 달린 \(liveCompanionName)에게는 잠재치가 따로 저장돼 있습니다. 지금 선택한 동행 성장에 반영하면 저장 잠재 \(feedPreview.potentialExperienceSpent) XP도 함께 사용됩니다."
            }
            return "이 운동 기록은 기록 밀도 +\(dataBonus) 보너스를 갖고 있고, 함께 달린 \(liveCompanionName)에게는 잠재치가 따로 저장돼 있습니다."
        }
        if let feedPreview, feedPreview.potentialExperienceSpent > 0 {
            return "이 운동 기록은 기본 XP 외에 기록 밀도 +\(dataBonus) 보너스를 갖고 있고, 지금 선택한 동행에게 저장된 잠재 \(feedPreview.potentialExperienceSpent) XP도 이번에 함께 반영됩니다."
        }
        return "이 운동 기록은 기본 XP 외에 기록 밀도 +\(dataBonus) 보너스를 함께 갖고 있습니다."
    }

    private func growthActionDetail(for run: CompletedRunRecord) -> String {
        let dataBonus = runCoreProfile?.bonusExperience ?? 0
        if let preview = store.feedProjection(for: run), preview.potentialExperienceSpent > 0 {
            return "\(store.featuredCompanion.pet.displayName) 성장에 반영합니다. Lv.\(preview.beforeSnapshot.level)에서 Lv.\(preview.projectedSnapshot.level)로 올라가고, 기록 밀도 +\(dataBonus), 저장 잠재 \(preview.storedPotentialExperience) 중 \(preview.potentialExperienceSpent) XP를 이번에 사용합니다."
        }
        if let preview = store.feedProjection(for: run) {
            return "\(store.featuredCompanion.pet.displayName) 성장에 반영합니다. Lv.\(preview.beforeSnapshot.level)에서 Lv.\(preview.projectedSnapshot.level)로 올라가며 기록 밀도 +\(dataBonus) 보너스가 붙습니다."
        }
        return "\(store.featuredCompanion.pet.displayName) 성장에 반영합니다. 기록 밀도 +\(dataBonus) 보너스가 붙습니다."
    }

    private func growthPreviewDetail(for preview: CompanionFeedProjection) -> String {
        if let nextMilestone = preview.projectedSnapshot.nextEvolutionMilestone {
            return "\(preview.beforeProgress.stageLabel)에서 \(preview.projectedProgress.stageLabel) 흐름으로 이동합니다. 다음 진화 기준은 Lv.\(nextMilestone.requiredLevel) · \(nextMilestone.requiredExperience) XP입니다."
        }
        if let nextLateGrowth = preview.projectedSnapshot.lateGrowthWindow.last,
           preview.projectedSnapshot.level < nextLateGrowth.requiredLevel {
            return "\(preview.projectedProgress.stageLabel) 이후에는 Lv.\(nextLateGrowth.requiredLevel) \(nextLateGrowth.title) 해금이 다음 목표입니다."
        }
        return "\(preview.projectedProgress.stageLabel) 상태가 더 깊어지고, 이후에는 후반 기록 운영이 중심이 됩니다."
    }

    private func growthPreviewBadges(for preview: CompanionFeedProjection) -> [String] {
        var badges = ["예상 +\(preview.projectedTotalExperience) XP"]
        if preview.stageAdvanced {
            badges.append("\(preview.projectedProgress.stageLabel) 도달")
        }
        if preview.levelGain > 0 {
            badges.append("레벨 +\(preview.levelGain)")
        }
        if preview.potentialExperienceSpent > 0 {
            badges.append("잠재 사용 +\(preview.potentialExperienceSpent)")
        }
        return badges
    }

    private func potentialSpendPreview(for run: CompletedRunRecord) -> (stored: Int, spend: Int, remaining: Int)? {
        guard let preview = store.feedProjection(for: run),
              preview.potentialExperienceSpent > 0 else {
            return nil
        }
        return (
            stored: preview.storedPotentialExperience,
            spend: preview.potentialExperienceSpent,
            remaining: preview.projectedRemainingStoredPotentialExperience
        )
    }

    private func featuredLateGrowthBadges(for run: CompletedRunRecord) -> [String] {
        var badges = ["기록 태그 \(featuredLateGrowthFeatures.insightLabelLimit)개"]

        if featuredLateGrowthFeatures.potentialSpendCapBonus > 0 {
            badges.append("잠재 저장 \(featuredLateGrowthFeatures.storedPotentialCap)")
            badges.append("잠재 사용 상한 +\(featuredLateGrowthFeatures.potentialSpendCapBonus)")
        }

        if featuredLateGrowthFeatures.seasonRecordEcho,
           RunimalGameEngine.seasonAffinity(for: store.featuredCompanion.pet, season: store.weeklyBoard.season) {
            badges.append("\(store.weeklyBoard.season.title) 기록 보관")
        }

        if featuredLateGrowthFeatures.preservesWorldSignals, run.worldImpact != nil {
            badges.append("이야기 표식 보관")
        }

        if featuredLateGrowthFeatures.completedRecordMark,
           (run.worldImpact != nil || (runCoreProfile?.informationScore ?? 0) >= 10) {
            badges.append("완성 기록 보관")
        }

        return badges
    }

    private func exportButtons(for run: CompletedRunRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("세션 내보내기")
                .font(.caption.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.darkest)

            HStack(spacing: 8) {
                ForEach(WorkoutExportTimeBasis.allCases) { basis in
                    Button {
                        exportTimeBasis = basis
                    } label: {
                        Text(basis.label)
                            .font(.caption2.monospaced().weight(.black))
                            .foregroundStyle(exportTimeBasis == basis ? GameBoyPalette.lightest : GameBoyPalette.darkest)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(exportTimeBasis == basis ? GameBoyPalette.mediumDark : GameBoyPalette.lightest)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(GameBoyPalette.darkest, lineWidth: 2)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(exportTimeBasisDescription)
                .font(.caption.monospaced())
                .foregroundStyle(GameBoyPalette.mediumDark)

            if let exportFeedback {
                exportFeedbackCard(exportFeedback)
            }

            HStack(spacing: 10) {
                pixelActionButton(title: "GPX 내보내기", detail: "트랙 공유용") {
                    export(run: run, format: .gpx)
                }
                pixelActionButton(title: "TCX 내보내기", detail: "랩/훈련용") {
                    export(run: run, format: .tcx)
                }
            }

            pixelActionButton(title: "FIT 내보내기", detail: "플랫폼 업로드용", filled: true) {
                export(run: run, format: .fit)
            }
        }
    }

    private var exportTimeBasisDescription: String {
        switch exportTimeBasis {
        case .elapsed:
            return "전체 시간 기준. 정지까지 포함한 일상 기록용입니다."
        case .timer:
            return "운동 시간 기준. pause를 제외한 기본 훈련 기록용입니다."
        case .moving:
            return "이동 시간 기준. 실제 이동 구간 중심의 분석용입니다."
        }
    }

    private func exportFeedbackCard(_ feedback: ExportFeedback) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("내보내기 완료")
                .font(.caption.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.darkest)

            HStack(spacing: 8) {
                TraitChip(label: feedback.format.displayName, accent: accent.opacity(0.25))
                TraitChip(label: "\(feedback.timeBasis.label) 기준", accent: .green.opacity(0.2))
                TraitChip(label: byteCountLabel(feedback.bytes), accent: .blue.opacity(0.2))
            }

            HStack(spacing: 8) {
                TraitChip(label: "랩 \(feedback.lapCount)개", accent: .orange.opacity(0.2))
                TraitChip(label: "pause \(feedback.pauseCount)회", accent: .yellow.opacity(0.2))
                TraitChip(label: feedback.containerLabel, accent: .mint.opacity(0.2))
            }

            Text(feedback.filename)
                .font(.caption.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.mediumDark)
                .lineLimit(2)

            Text("공유 시트로 바로 이어집니다. 같은 러닝도 기준을 바꿔 다시 뽑아 비교할 수 있습니다.")
                .font(.caption.monospaced())
                .foregroundStyle(GameBoyPalette.mediumDark)
        }
        .padding(12)
        .background(GameBoyPalette.mediumLight.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(GameBoyPalette.darkest.opacity(0.2), lineWidth: 1)
        )
    }

    private func export(run: CompletedRunRecord, format: WorkoutExportFormat) {
        guard let archive = workoutArchive else { return }
        let title = "\(run.reward.coreLabel)-\(sourceEyebrow(for: run))-\(exportTimeBasis.rawValue)"
        if let url = try? exportManager.exportFileURL(for: archive, title: title, format: format, timeBasis: exportTimeBasis) {
            let byteCount = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            let summary = workoutExportFormatSummary(for: archive, format: format)
            let pauseCount = archive.events.filter { $0.kind == .pause }.count
            exportFeedback = ExportFeedback(
                format: format,
                filename: url.lastPathComponent,
                bytes: byteCount,
                timeBasis: exportTimeBasis,
                lapCount: archive.laps.count,
                pauseCount: pauseCount,
                containerLabel: summary.containerLabel
            )
            exportDocument = ExportDocument(url: url)
        }
    }

    private func mutationPivotSummary(for run: CompletedRunRecord) -> (stageTitle: String, axisTitle: String, summary: String)? {
        guard let contribution = run.mutationContribution,
              let topAxis = contribution.axes.max(by: { $0.progress < $1.progress }),
              let bridge = SpeciesGrowthMutationBridgeEngine.bridge(
                for: run.reward.pet.species,
                axis: topAxis.axis,
                branchID: topAxis.branchID
              ) else {
            return nil
        }

        let keyPart = bridge.redirectedParts.first?.title ?? bridge.inheritedParts.first?.title ?? topAxis.branchTitle
        return (
            stageTitle: bridge.startStageTitle,
            axisTitle: axisLabel(topAxis.axis),
            summary: "\(keyPart) 갈래를 밀었습니다"
        )
    }

    private func sourceEyebrow(for run: CompletedRunRecord) -> String {
        if run.source == "watch-healthkit" {
            return "Runimal"
        }

        if run.source.hasPrefix("fit:") {
            return "FIT"
        }

        return run.sourceLabel ?? "외부"
    }

    private func environmentLabel(_ condition: EnvironmentCondition) -> String {
        switch condition {
        case .clear: return "맑음"
        case .rain: return "비"
        case .snow: return "눈"
        case .wind: return "바람"
        case .heat: return "고온"
        case .cold: return "저온"
        case .overcast: return "흐림"
        case .unknown: return "미확인"
        }
    }

    private func axisLabel(_ axis: SpeciesLineageAxis) -> String {
        switch axis {
        case .body:
            return "체형"
        case .ecology:
            return "생태"
        case .rhythm:
            return "리듬"
        }
    }

    private func heartRateLabel(_ heartRate: Double?) -> String {
        guard let heartRate else { return "-- bpm" }
        return "\(Int(heartRate.rounded())) bpm"
    }

    private func cadenceLabel(_ cadence: Int?) -> String {
        guard let cadence else { return "-- spm" }
        return "\(cadence) spm"
    }

    private func summaryLine(for run: CompletedRunRecord) -> String {
        "\(distanceLabel(run.distanceMeters)) · \(durationLabel(run.durationSeconds)) · \(paceLabel(run.averagePaceSeconds))"
    }

    private func paceLabel(_ seconds: Int?) -> String {
        guard let seconds else { return "--/km" }
        let minutes = seconds / 60
        return "\(minutes):\(String(format: "%02d", seconds % 60))/km"
    }

    private func distanceLabel(_ meters: Double) -> String {
        String(format: "%.2f km", meters / 1000)
    }

    private func durationLabel(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60

        if hours > 0 {
            return "\(hours):\(String(format: "%02d", minutes)):\(String(format: "%02d", remainingSeconds))"
        }

        return "\(minutes):\(String(format: "%02d", remainingSeconds))"
    }

    private func byteCountLabel(_ bytes: Int) -> String {
        guard bytes > 0 else { return "0 KB" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
