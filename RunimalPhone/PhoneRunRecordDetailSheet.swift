import RunimalCore
import SwiftUI

struct PhoneRunRecordDetailSheet: View {
    let store: PhoneDashboardStore
    let runID: String

    @Environment(\.dismiss) private var dismiss
    @State private var actionFeedback: ActionFeedback?

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

    private enum ActionFeedback {
        case fed(CompanionFeedOutcome)
        case forged(EggInventoryEntry)
        case incubated(EggInventoryEntry)
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
                        Color(red: 0.03, green: 0.05, blue: 0.08),
                        Color(red: 0.02, green: 0.03, blue: 0.05),
                        accent.opacity(0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if let run {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            heroCard(for: run)
                            metricCard(for: run)
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
                            .foregroundStyle(.orange)
                        Text("러닝 기록을 찾을 수 없습니다")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
                        Text("삭제되었거나 이미 정리된 기록입니다.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기") { dismiss() }
                        .fontWeight(.bold)
                }
            }
            .navigationTitle("러닝 기록")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func heroCard(for run: CompletedRunRecord) -> some View {
        GameSurface(title: run.reward.coreLabel, accent: accent, eyebrow: sourceEyebrow(for: run)) {
            VStack(alignment: .leading, spacing: 14) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    accent.opacity(0.24),
                                    Color.black.opacity(0.86),
                                    .white.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)

                    if !run.route.isEmpty {
                        RoutePreviewShape(points: run.route)
                            .stroke(accent, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                            .padding(26)
                    } else {
                        Image(systemName: "point.bottomleft.forward.to.point.topright.scurvepath")
                            .font(.system(size: 42, weight: .black))
                            .foregroundStyle(accent.opacity(0.82))
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
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)

                Text(run.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.68))
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
            }
        }
    }

    @ViewBuilder
    private func actionCard(for run: CompletedRunRecord) -> some View {
        GameSurface(title: "코어 액션", accent: accent, eyebrow: "성장 연결") {
            VStack(alignment: .leading, spacing: 12) {
                if canUseRunCore {
                    Text("이 러닝 코어를 바로 성장 재료로 전환할 수 있습니다.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))

                    if store.mainSelection?.kind == .egg, store.mainEgg != nil {
                        Button {
                            if let updatedEgg = store.incubateMainEgg(with: run.id) {
                                actionFeedback = .incubated(updatedEgg)
                            }
                        } label: {
                            actionLabel(
                                title: "메인 알에 주입",
                                detail: "현재 메인 알의 디코딩 진척을 올립니다."
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(accent)
                    } else {
                        Button {
                            if let outcome = store.feedActiveCompanion(with: run.id) {
                                actionFeedback = .fed(outcome)
                            }
                        } label: {
                            actionLabel(
                                title: "메인 동행체에 먹이기",
                                detail: "\(store.featuredCompanion.pet.displayName)의 경험치로 변환합니다."
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(accent)
                    }

                    if eggOpportunity?.eligible == true {
                        Button {
                            if let forgedEgg = store.forgeEgg(from: run.id) {
                                actionFeedback = .forged(forgedEgg)
                            }
                        } label: {
                            actionLabel(
                                title: "새 알 만들기",
                                detail: eggOpportunity?.summary ?? "이 러닝으로 새로운 알을 만듭니다."
                            )
                        }
                        .buttonStyle(.bordered)
                        .tint(.white.opacity(0.3))
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(usageSummary?.title ?? "이미 사용한 코어")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
                        Text(usageSummary?.detail ?? "이 러닝 코어는 이미 성장 또는 알 생성에 사용되었습니다.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.68))
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke((usageSummary?.accent ?? .white.opacity(0.18)).opacity(0.45), lineWidth: 1)
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
                        title: outcome.stageAdvanced ? "단계 상승 완료" : "성장 에너지 흡수 완료",
                        detail: "\(outcome.beforeProgress.stageLabel)에서 \(outcome.afterProgress.stageLabel)로 갱신됐습니다."
                    )

                    HStack(spacing: 8) {
                        TraitChip(label: "+\(outcome.gainedExperience) XP", accent: .green)
                        TraitChip(label: outcome.afterProgress.stageLabel, accent: accent)
                        if outcome.stageAdvanced {
                            TraitChip(label: "진화 발생", accent: .orange.opacity(0.82))
                        }
                    }

                    RunimalProgressBar(progress: outcome.afterProgress.progressRatio, accent: accent, height: 10)

                    Text(outcome.afterProgress.headline)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.76))

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
                        title: "새 알이 생성됐습니다",
                        detail: "이 러닝 코어가 새로운 디코딩 쉘로 고정됐습니다."
                    )

                    HStack(spacing: 12) {
                        PhoneEggForgeEffectView(egg: egg)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(egg.title)
                                .font(.headline.weight(.black))
                                .foregroundStyle(.white)
                            Text(egg.shell.hatchHint)
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.72))
                        }
                    }

                    RunimalProgressBar(progress: egg.progressRatio, accent: egg.shell.accentColor, height: 10)
                    Text("임계치 \(egg.hatchThreshold) XP · 현재 \(egg.storedExperience) XP")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.78))
                    resultNextStep("다음 추천", detail: "메인 알로 들고 다니며 다음 러닝 코어를 주입하면 부화 준비까지 빠르게 진행됩니다.")
                }
            }

        case .incubated(let egg):
            GameSurface(title: "알 디코딩 진행", accent: accent, eyebrow: "메인 알 주입 완료") {
                VStack(alignment: .leading, spacing: 12) {
                    resultHero(
                        icon: egg.readyToHatch ? "checkmark.seal.fill" : "waveform.badge.plus",
                        title: egg.readyToHatch ? "실체화 준비 완료" : "디코딩이 더 안정화됐습니다",
                        detail: egg.readyToHatch ? "이제 컬렉션에서 바로 부화 시퀀스를 시작할 수 있습니다." : "다음 러닝 코어를 더 주입하면 부화 임계점에 도달합니다."
                    )

                    HStack(spacing: 12) {
                        TraceEggView(accent: egg.shell.accentColor, shell: egg.shell, resonance: min(max(egg.progressRatio, 0.24), 1))
                            .frame(width: 88, height: 88)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(egg.title)
                                .font(.headline.weight(.black))
                                .foregroundStyle(.white)
                            Text(egg.readyToHatch ? "실체화 준비 완료" : "디코딩 신호가 더 안정화되었습니다.")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.72))
                        }
                    }

                    RunimalProgressBar(progress: egg.progressRatio, accent: accent, height: 9)
                    Text("\(egg.storedExperience) / \(egg.hatchThreshold) XP")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.78))
                    resultNextStep("다음 추천", detail: egg.readyToHatch ? "보관함으로 이동해 실체화 시퀀스를 시작하세요." : "같은 방식으로 다음 코어를 주입해 부화 게이지를 채우세요.")
                }
            }
        }
    }

    private func resultHero(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
    }

    private func resultNextStep(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(accent.opacity(0.92))
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func actionLabel(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.black))
            Text(detail)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sourceEyebrow(for run: CompletedRunRecord) -> String {
        if run.source == "watch-healthkit" {
            return "Runimal 워치 러닝"
        }

        return run.sourceLabel ?? "외부 러닝"
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
