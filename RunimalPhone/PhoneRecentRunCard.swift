import RunimalCore
import SwiftUI
import UIKit

struct PhoneRecentRunCard: View {
    let run: CompletedRunRecord
    let accent: Color
    let targetCompanion: PetCollectionEntry
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

    var body: some View {
        GameSurface(title: "러닝 코어", accent: accent, eyebrow: "FIT 수동 가져오기") {
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
                .fill(
                    LinearGradient(
                        colors: [
                            run.reward.pet.accentColor.opacity(0.24),
                            Color.black.opacity(0.86),
                            .white.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)

            if !run.route.isEmpty {
                RoutePreviewShape(points: run.route)
                    .stroke(run.reward.pet.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .padding(26)
            } else {
                Image(systemName: "point.bottomleft.forward.to.point.topright.scurvepath")
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(run.reward.pet.accentColor.opacity(0.82))
            }

            VStack(alignment: .leading, spacing: 6) {
                RunimalSignalBadge(
                    icon: "waveform.path.ecg",
                    label: "운동 코어",
                    accent: run.reward.pet.accentColor
                )
                Text(externalSourceLabel ?? "RUNIMAL")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white.opacity(0.78))
            }
            .padding(14)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }

    private var coreSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(run.reward.coreLabel)
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
            Text(summaryLine)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))
            Text(loreLine)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.62))
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
            Text("메인 동행체에 바로 먹이기")
                .font(.subheadline.weight(.black))
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                PixelPetView(pet: targetCompanion.pet, pixelSize: 6)

                VStack(alignment: .leading, spacing: 4) {
                    Text(targetCompanion.pet.displayName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Text(canFeed ? "가져온 운동 에너지를 성장 경험치로 변환합니다." : "이미 사용한 코어이거나 사용할 수 없는 기록입니다.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.64))
                }

                Spacer()

                Button("가져온 경험치 먹이기") {
                    onFeed()
                }
                .buttonStyle(.borderedProminent)
                .tint(run.reward.pet.accentColor)
                .font(.caption.weight(.black))
                .disabled(!canFeed)
            }
        }
        .padding(14)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var shareButton: some View {
        Button {
            shareImage = renderShareImage()
            isShowingShareSheet = shareImage != nil
        } label: {
            Label("러닝 카드 공유", systemImage: "square.and.arrow.up.fill")
                .font(.subheadline.weight(.black))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(run.reward.pet.accentColor)
    }

    private var loreLine: String {
        if let externalSourceLabel {
            return "\(externalSourceLabel)에서 수동으로 가져옴 · \(run.startedAt.formatted(date: .abbreviated, time: .shortened))"
        }

        return "\(run.source) · 틈새 세계 동기화 \(run.startedAt.formatted(date: .abbreviated, time: .shortened))"
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
                .frame(width: 1080, height: 1080)
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

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, run.reward.pet.accentColor.opacity(0.34), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("RUNIMAL")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(run.reward.pet.accentColor)
                    Text("KINETIC CORE REPORT")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.82))
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(.white.opacity(0.06))

                    if !run.route.isEmpty {
                        RoutePreviewShape(points: run.route)
                            .stroke(run.reward.pet.accentColor, style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round))
                            .padding(34)
                    }
                }
                .aspectRatio(1, contentMode: .fit)

                HStack(spacing: 18) {
                    shareMetric("거리", distanceLabel(run.distanceMeters))
                    shareMetric("XP", "+\(run.reward.experience)")
                    shareMetric("케이던스", run.cadence.map { "\($0) spm" } ?? "--")
                }

                Text(run.reward.coreLabel)
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("가져온 러닝 데이터를 메인 동행체 성장 코어로 변환")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
            }
            .padding(48)
        }
    }

    private func shareMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.64))
            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func distanceLabel(_ meters: Double) -> String {
        String(format: "%.2f km", meters / 1000)
    }
}
