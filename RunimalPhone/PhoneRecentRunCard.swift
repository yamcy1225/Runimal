import RunimalCore
import SwiftUI
import UIKit

struct PhoneRecentRunCard: View {
    let run: CompletedRunRecord
    let accent: Color
    let targetCompanion: PetCollectionEntry
    let renderState: CompanionPixelRenderState
    let canFeed: Bool
    let onFeed: () -> Void

    @State private var shareImage: UIImage?
    @State private var isShowingShareSheet = false

    private var summaryLine: String {
        "\(distanceLabel(run.distanceMeters)) · \(durationLabel(run.durationSeconds)) · \(paceLabel(run.averagePaceSeconds))"
    }

    private var experienceLabel: String {
        "+\(run.reward.experience) XP"
    }

    private var eyebrowLabel: String {
        if run.source.hasPrefix("fit:") {
            return "FIT 가져온 기록"
        }
        if run.source.hasPrefix("healthkit:") {
            return "외부 운동 기록"
        }
        return "운동 기록"
    }

    var body: some View {
        GameSurface(title: "운동 기록", accent: accent, eyebrow: eyebrowLabel) {
            VStack(alignment: .leading, spacing: 12) {
                coreField

                coreSummary
                coreTags
                coreBonusRail
                feedStrip
                shareButton
            }
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let shareImage {
                ShareSheet(items: [shareImage as Any])
            }
        }
    }

    private var coreField: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(GameBoyPalette.lightest)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(GameBoyPalette.darkest, lineWidth: 2)
                )

            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(GameBoyPalette.mediumLight.opacity(0.22))
                .padding(6)

            GameBoyLCDOverlay()
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

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
                RunimalSignalBadge(
                    icon: "waveform.path.ecg",
                    label: "운동 코어",
                    accent: run.reward.pet.accentColor
                )
                Text(externalSourceLabel ?? "RUNIMAL")
                    .font(.caption.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.mediumDark)
            }
            .padding(14)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }

    private var coreSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(run.reward.coreLabel)
                .font(.headline.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.darkest)
            Text(summaryLine)
                .font(.subheadline.monospaced())
                .foregroundStyle(GameBoyPalette.mediumDark)
            Text(loreLine)
                .font(.caption2.monospaced())
                .foregroundStyle(GameBoyPalette.mediumDark.opacity(0.88))
        }
    }

    private var coreTags: some View {
        HStack {
            TraitChip(label: experienceLabel, accent: .green)
            if let cadence = run.cadence {
                TraitChip(label: "\(cadence) spm", accent: .white.opacity(0.18))
            }
            TraitChip(label: environmentLabel, accent: .blue.opacity(0.28))
            if let externalSourceLabel {
                TraitChip(label: externalSourceLabel, accent: run.reward.pet.accentColor.opacity(0.24))
            }
        }
    }

    @ViewBuilder
    private var coreBonusRail: some View {
        if !run.reward.bonusLabels.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(run.reward.bonusLabels, id: \.self) { bonus in
                        RunimalSignalBadge(icon: "sparkles", label: bonus, accent: run.reward.pet.accentColor.opacity(0.82))
                    }
                }
            }
        }
    }

    private var feedStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("지금 선택한 동행에 바로 반영")
                .font(.subheadline.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.darkest)

            HStack(spacing: 12) {
                PixelPetView(
                    pet: targetCompanion.pet,
                    pixelSize: 6,
                    growthStageIndex: renderState.growthStageIndex,
                    mutationForm: renderState.mutationForm,
                    mutationHistory: renderState.mutationHistory,
                    mutationVisualState: renderState.mutationVisualState
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(targetCompanion.pet.displayName)
                        .font(.subheadline.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.darkest)
                    Text(canFeed ? "이 운동 기록을 지금 선택한 동행 성장에 반영합니다." : "이미 사용했거나 지금은 반영할 수 없는 운동 기록입니다.")
                        .font(.caption.monospaced())
                        .foregroundStyle(GameBoyPalette.mediumDark)
                }

                Spacer()

                Button(action: onFeed) {
                    Text("성장에 반영")
                        .font(.caption.monospaced().weight(.black))
                        .foregroundStyle(canFeed ? GameBoyPalette.lightest : GameBoyPalette.mediumLight)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(canFeed ? GameBoyPalette.mediumDark : GameBoyPalette.mediumLight.opacity(0.55))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(GameBoyPalette.darkest, lineWidth: 2)
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canFeed)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(GameBoyPalette.mediumLight.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(GameBoyPalette.darkest.opacity(0.32), lineWidth: 1)
                )
        )
    }

    private var shareButton: some View {
        Button {
            shareImage = renderShareImage()
            isShowingShareSheet = shareImage != nil
        } label: {
            Label("러닝 카드 공유", systemImage: "square.and.arrow.up.fill")
                .font(.subheadline.monospaced().weight(.black))
                .frame(maxWidth: .infinity)
                .foregroundStyle(GameBoyPalette.lightest)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(GameBoyPalette.mediumDark)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(GameBoyPalette.darkest, lineWidth: 2)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private var loreLine: String {
        if let externalSourceLabel {
            return "\(externalSourceLabel)에서 수동으로 가져옴 · \(run.startedAt.formatted(date: .abbreviated, time: .shortened))"
        }

        return "\(run.source) · 기록 저장 \(run.startedAt.formatted(date: .abbreviated, time: .shortened))"
    }

    private var externalSourceLabel: String? {
        guard run.source.hasPrefix("healthkit:") || run.source.hasPrefix("fit:") else { return nil }
        return run.sourceLabel ?? "외부 앱"
    }

    private var environmentLabel: String {
        switch run.environmentCondition {
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

    private func renderShareImage() -> UIImage? {
        let renderer = ImageRenderer(
            content: RunShareImageCard(run: run)
                .frame(width: 1080, height: 1920)
        )
        renderer.scale = 1
        return renderer.uiImage
    }

    private func paceLabel(_ seconds: Int?) -> String {
        guard let seconds else { return "페이스 --" }
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

private struct RunShareImageCard: View {
    let run: CompletedRunRecord

    private var sourceLabel: String {
        if let label = run.sourceLabel {
            return label.uppercased()
        }
        if run.source.hasPrefix("fit:") {
            return "FIT IMPORT"
        }
        if run.source.hasPrefix("healthkit:") {
            return "HEALTHKIT"
        }
        return "LIVE RUN"
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [GameBoyPalette.mediumLight, GameBoyPalette.lightest, GameBoyPalette.mediumLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            GameBoyLCDOverlay()

            VStack(alignment: .leading, spacing: 30) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("RUNIMAL")
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundStyle(GameBoyPalette.darkest)
                    Text("오늘의 러닝이 생명으로 남았다")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(GameBoyPalette.mediumDark)
                }

                HStack(spacing: 10) {
                    shareChip(sourceLabel)
                    shareChip(environmentLabel(run.environmentCondition))
                    shareChip(run.reward.pet.displayName)
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(GameBoyPalette.lightest)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .stroke(GameBoyPalette.darkest, lineWidth: 4)
                        )

                    if !run.route.isEmpty {
                        RoutePreviewShape(points: run.route)
                            .stroke(GameBoyPalette.mediumDark, style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round))
                            .padding(34)
                    } else {
                        Image(systemName: "figure.run.square.stack")
                            .font(.system(size: 110, weight: .black))
                            .foregroundStyle(GameBoyPalette.mediumDark)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 760)

                HStack(spacing: 18) {
                    shareMetric("거리", distanceLabel(run.distanceMeters))
                    shareMetric("XP", "+\(run.reward.experience)")
                    shareMetric("페이스", paceLabel(run.averagePaceSeconds))
                    shareMetric("케이던스", run.cadence.map { "\($0) spm" } ?? "--")
                }

                Text(run.reward.coreLabel)
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundStyle(GameBoyPalette.darkest)
                    .lineLimit(2)

                Text("기록 보관이 아니라, 다음 알과 성장 선택을 자랑하는 브래그 카드.")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(GameBoyPalette.mediumDark)

                Spacer(minLength: 0)
            }
            .padding(48)
        }
    }

    private func shareChip(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 20, weight: .black, design: .monospaced))
            .foregroundStyle(GameBoyPalette.darkest)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(GameBoyPalette.lightest.opacity(0.82))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(GameBoyPalette.darkest, lineWidth: 2)
                    )
            )
    }

    private func shareMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(GameBoyPalette.mediumDark)
            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(GameBoyPalette.darkest)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(GameBoyPalette.lightest.opacity(0.84))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(GameBoyPalette.darkest, lineWidth: 2)
                )
        )
    }

    private func distanceLabel(_ meters: Double) -> String {
        String(format: "%.2f km", meters / 1000)
    }

    private func paceLabel(_ seconds: Int?) -> String {
        guard let seconds else { return "--" }
        return "\(seconds / 60):\(String(format: "%02d", seconds % 60))/km"
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
}
