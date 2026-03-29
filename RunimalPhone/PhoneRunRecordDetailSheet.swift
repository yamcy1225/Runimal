import RunimalCore
import SwiftUI

struct PhoneRunRecordDetailSheet: View {
    let store: PhoneDashboardStore
    let runID: String

    @Environment(\.dismiss) private var dismiss
    @State private var actionFeedback: ActionFeedback?
    @State private var exportDocument: ExportDocument?
    @State private var exportTimeBasis: WorkoutExportTimeBasis = .timer

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

    private var usageSummary: RunUsageSummary? {
        guard let run else { return nil }
        return store.runCoreUsageSummary(for: run).map {
            RunUsageSummary(title: $0.title, detail: $0.detail, accent: $0.accent)
        }
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
                        Text("러닝 기록을 찾을 수 없습니다")
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
                    Text("러닝 기록")
                        .font(.headline.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.darkest)
                }
            }
            .toolbarBackground(GameBoyPalette.lightest, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $exportDocument) { document in
                ShareSheet(items: [document.url])
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
                }

                if workoutArchive != nil {
                    exportButtons(for: run)
                }
            }
        }
    }

    @ViewBuilder
    private func actionCard(for run: CompletedRunRecord) -> some View {
        GameSurface(title: "코어 액션", accent: accent, eyebrow: "성장 연결") {
            VStack(alignment: .leading, spacing: 12) {
                if canUseRunCore {
                    Text("이 러닝 코어를 바로 성장 재료로 전환할 수 있습니다.")
                        .font(.footnote.monospaced())
                        .foregroundStyle(GameBoyPalette.mediumDark)

                    if store.mainSelection?.kind == .egg, store.mainEgg != nil {
                        pixelActionButton(title: "메인 알 주입", detail: "알 게이지를 올립니다.", filled: true) {
                            if let updatedEgg = store.incubateMainEgg(with: run.id) {
                                actionFeedback = .incubated(updatedEgg)
                            }
                        }
                    } else {
                        pixelActionButton(title: "메인 동행체 성장", detail: "\(store.featuredCompanion.pet.displayName) XP로 변환합니다.", filled: true) {
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
                        Text(usageSummary?.detail ?? "이 러닝 코어는 이미 성장 또는 알 생성에 사용되었습니다.")
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
            GameSurface(title: "성장 결과", accent: accent, eyebrow: "코어 전환 완료") {
                VStack(alignment: .leading, spacing: 12) {
                    resultHero(
                        icon: outcome.stageAdvanced ? "arrow.up.right.circle.fill" : "bolt.fill",
                        title: outcome.stageAdvanced ? "단계 상승" : "성장 흡수 완료",
                        detail: "\(outcome.beforeProgress.stageLabel) -> \(outcome.afterProgress.stageLabel)"
                    )

                    HStack(spacing: 8) {
                        TraitChip(label: "+\(outcome.gainedExperience) XP", accent: .green)
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

                    if !outcome.bonusLabels.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(outcome.bonusLabels, id: \.self) { bonus in
                                    RunimalSignalBadge(icon: "sparkles", label: bonus, accent: accent)
                                }
                            }
                        }
                    }

                    resultNextStep("다음 추천", detail: outcome.stageAdvanced ? "보관함에서 최종 단계 경로와 새로운 역할 변화를 확인하세요." : "다음 러닝 코어를 더 먹이면 진화 임계점까지 더 빨리 도달할 수 있습니다.")
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
                    resultNextStep("다음 행동", detail: "메인 알로 지정하고 다음 코어를 더 주입하세요.")
                }
            }

        case .incubated(let egg):
            GameSurface(title: "알 디코딩 진행", accent: accent, eyebrow: "메인 알 주입 완료") {
                VStack(alignment: .leading, spacing: 12) {
                    resultHero(
                        icon: egg.readyToHatch ? "checkmark.seal.fill" : "waveform.badge.plus",
                        title: egg.readyToHatch ? "부화 준비 완료" : "디코딩 안정화",
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
                        title: "디코딩 게이지",
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

    private func export(run: CompletedRunRecord, format: WorkoutExportFormat) {
        guard let archive = workoutArchive else { return }
        let title = "\(run.reward.coreLabel)-\(sourceEyebrow(for: run))-\(exportTimeBasis.rawValue)"
        if let url = try? exportManager.exportFileURL(for: archive, title: title, format: format, timeBasis: exportTimeBasis) {
            exportDocument = ExportDocument(url: url)
        }
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
}
