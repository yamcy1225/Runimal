import RunimalCore
import SwiftUI
import UIKit

struct PhoneMilestoneSharePanel: View {
    let featuredCompanion: PetCollectionEntry
    let collection: [PetCollectionEntry]
    let progress: EvolutionProgress
    let season: WeeklySeason

    @State private var shareImage: UIImage?
    @State private var isShowingShareSheet = false

    private var milestoneCards: [MilestoneCard] {
        [
            firstHatchCard,
            rareVariantCard,
            mythicCard,
        ]
    }

    var body: some View {
        GameSurface(title: "공유 쇼케이스", accent: featuredCompanion.pet.accentColor, eyebrow: "SHARE READY") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    Text("가치가 가장 높은 순간만 시그널 포스터로 정리합니다.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.68))

                    Spacer(minLength: 12)

                    HStack(spacing: 6) {
                        ForEach(Array(milestoneCards.enumerated()), id: \.offset) { index, card in
                            Capsule(style: .continuous)
                                .fill(card.accent.opacity(index == 0 ? 0.92 : 0.35))
                                .frame(width: index == 0 ? 22 : 8, height: 8)
                        }
                    }
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(.white.opacity(0.08), lineWidth: 1)
                        )

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 18) {
                            ForEach(milestoneCards) { card in
                                milestoneCard(for: card)
                            }
                        }
                        .padding(14)
                    }
                }
                .frame(height: 436)
            }
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let shareImage {
                ShareSheet(items: [shareImage as Any])
            }
        }
    }

    private var firstHatchCard: MilestoneCard {
        if let firstHatch = collection.first(where: { $0.id.hasPrefix("hatched-") }) {
            return .unlocked(.firstHatch(firstHatch))
        }
        return .locked(
            id: "locked-first-hatch",
            accent: .cyan.opacity(0.78),
            supportAccent: .mint.opacity(0.62),
            icon: "sparkles",
            badge: "FIRST HATCH",
            kicker: "LOCKED",
            title: "첫 부화",
            detail: "처음 부화한 동행체가 생기면 이 카드가 열립니다.",
            emphasis: "WAITING"
        )
    }

    private var rareVariantCard: MilestoneCard {
        if let rareCompanion = collection.first(where: { $0.pet.rareVariant != nil }) {
            return .unlocked(.rareVariant(rareCompanion))
        }
        return .locked(
            id: "locked-rare-variant",
            accent: .orange.opacity(0.84),
            supportAccent: .red.opacity(0.76),
            icon: "star.circle.fill",
            badge: "RARE VARIANT",
            kicker: "LOCKED",
            title: "희귀 변이",
            detail: "돌발 목표와 특정 러닝 패턴이 맞아야 열립니다.",
            emphasis: "SIGNAL"
        )
    }

    private var mythicCard: MilestoneCard {
        if progress.stageLabel == "Mythic" {
            return .unlocked(.mythic(featuredCompanion, RunimalGameEngine.mythicTitle(for: featuredCompanion.pet, season: season)))
        }
        return .locked(
            id: "locked-mythic",
            accent: .yellow.opacity(0.88),
            supportAccent: .pink.opacity(0.72),
            icon: "crown.fill",
            badge: "MYTHIC",
            kicker: "LOCKED",
            title: "최종 진화",
            detail: "Stage를 끝까지 올리면 Mythic 포스터가 열립니다.",
            emphasis: "APEX"
        )
    }

    private func milestoneCard(for card: MilestoneCard) -> some View {
        let accent = card.accent

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    RunimalSignalBadge(icon: card.icon, label: card.badge, accent: accent)
                    Text(card.kicker)
                        .font(.caption2.weight(.bold))
                        .tracking(1.4)
                        .foregroundStyle(accent.opacity(0.88))
                }

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    Image(systemName: card.icon)
                        .font(.caption2.weight(.black))
                    Text(card.emphasis)
                        .font(.caption2.weight(.black))
                        .tracking(1.2)
                }
                .foregroundStyle(.white.opacity(0.74))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(.white.opacity(0.06))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(accent.opacity(0.18), lineWidth: 1)
                        )
                )
            }

            previewPoster(for: card)

            VStack(alignment: .leading, spacing: 8) {
                Text(card.title)
                    .font(.title2.weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .fixedSize(horizontal: false, vertical: true)

                Text(card.detail)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                if let milestone = card.milestone {
                    shareImage = renderShareImage(for: milestone)
                    isShowingShareSheet = shareImage != nil
                }
            } label: {
                Label(card.isUnlocked ? card.actionLabel : "아직 잠김", systemImage: card.isUnlocked ? "square.and.arrow.up.fill" : "lock.fill")
                    .font(.subheadline.weight(.black))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(accent)
            .disabled(card.isUnlocked == false)
            .opacity(card.isUnlocked ? 1 : 0.84)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 404)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.05),
                            card.accent.opacity(0.05),
                            .black.opacity(0.12),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(accent.opacity(0.14), lineWidth: 1)
                )
        )
    }

    private func previewPoster(for card: MilestoneCard) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            .black.opacity(0.92),
                            card.accent.opacity(0.26),
                            card.supportAccent.opacity(0.18),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )

            Circle()
                .fill(card.supportAccent.opacity(0.22))
                .frame(width: 88, height: 88)
                .blur(radius: 20)
                .offset(x: 12, y: 4)

            VStack(alignment: .leading, spacing: 8) {
                Text(card.badge)
                    .font(.caption2.weight(.black))
                    .tracking(1.4)
                    .foregroundStyle(.white.opacity(0.88))
                Spacer()
                card.previewView
                    .scaleEffect(1.12)
                    .frame(maxWidth: .infinity)
                Text(card.title)
                    .font(.caption.weight(.black))
                    .lineLimit(1)
                    .foregroundStyle(.white)
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 188)
        .shadow(color: card.accent.opacity(0.1), radius: 8, y: 4)
    }

    private func renderShareImage(for milestone: ShareMilestone) -> UIImage? {
        let renderer = ImageRenderer(
            content: MilestoneShareImageCard(milestone: milestone)
                .frame(width: 1080, height: 1350)
        )
        renderer.scale = 1
        return renderer.uiImage
    }
}

private struct MilestoneCard: Identifiable {
    let id: String
    let milestone: ShareMilestone?
    let accent: Color
    let supportAccent: Color
    let icon: String
    let badge: String
    let kicker: String
    let title: String
    let detail: String
    let emphasis: String

    var isUnlocked: Bool { milestone != nil }

    var actionLabel: String {
        switch milestone {
        case .firstHatch?:
            return "첫 해독 포스터"
        case .rareVariant?:
            return "희귀 포착 카드"
        case .mythic?:
            return "최종 진화 포스터"
        case nil:
            return "아직 잠김"
        }
    }

    var previewGradient: [Color] {
        [
            accent.opacity(0.18),
            supportAccent.opacity(0.14),
            .white.opacity(0.04),
        ]
    }

    @ViewBuilder
    var previewView: some View {
        if let milestone {
            PixelPetView(pet: milestone.pet, pixelSize: 7)
        } else {
            TraceEggView(accent: accent, pixelSize: 7, cracked: false, resonance: 0.32)
        }
    }

    static func unlocked(_ milestone: ShareMilestone) -> MilestoneCard {
        MilestoneCard(
            id: milestone.id,
            milestone: milestone,
            accent: milestone.accent,
            supportAccent: milestone.supportAccent,
            icon: milestone.icon,
            badge: milestone.badge,
            kicker: milestone.kicker,
            title: milestone.title,
            detail: milestone.detail,
            emphasis: milestone.emphasis
        )
    }

    static func locked(
        id: String,
        accent: Color,
        supportAccent: Color,
        icon: String,
        badge: String,
        kicker: String,
        title: String,
        detail: String,
        emphasis: String
    ) -> MilestoneCard {
        MilestoneCard(
            id: id,
            milestone: nil,
            accent: accent,
            supportAccent: supportAccent,
            icon: icon,
            badge: badge,
            kicker: kicker,
            title: title,
            detail: detail,
            emphasis: emphasis
        )
    }
}

private enum ShareMilestone {
    case firstHatch(PetCollectionEntry)
    case rareVariant(PetCollectionEntry)
    case mythic(PetCollectionEntry, String)

    var id: String {
        switch self {
        case .firstHatch(let companion):
            return "first-hatch-\(companion.id)"
        case .rareVariant(let companion):
            return "rare-\(companion.id)"
        case .mythic(let companion, _):
            return "mythic-\(companion.id)"
        }
    }

    var pet: GeneratedPet {
        switch self {
        case .firstHatch(let companion), .rareVariant(let companion), .mythic(let companion, _):
            return companion.pet
        }
    }

    var accent: Color {
        switch self {
        case .firstHatch(let companion):
            return companion.pet.accentColor
        case .rareVariant:
            return .orange
        case .mythic:
            return .yellow
        }
    }

    var supportAccent: Color {
        switch self {
        case .firstHatch:
            return .cyan.opacity(0.7)
        case .rareVariant:
            return .red.opacity(0.82)
        case .mythic:
            return .pink.opacity(0.76)
        }
    }

    var previewGradient: [Color] {
        switch self {
        case .firstHatch:
            return [
                accent.opacity(0.18),
                supportAccent.opacity(0.14),
                .white.opacity(0.04),
            ]
        case .rareVariant:
            return [
                .orange.opacity(0.22),
                .red.opacity(0.18),
                .black.opacity(0.78),
            ]
        case .mythic:
            return [
                .yellow.opacity(0.22),
                supportAccent.opacity(0.14),
                .black.opacity(0.82),
            ]
        }
    }

    var icon: String {
        switch self {
        case .firstHatch:
            return "sparkles"
        case .rareVariant:
            return "star.circle.fill"
        case .mythic:
            return "crown.fill"
        }
    }

    var kicker: String {
        switch self {
        case .firstHatch:
            return "FIRST SIGNAL"
        case .rareVariant:
            return "UNCOMMON TRACE"
        case .mythic:
            return "APEX FORM"
        }
    }

    var badge: String {
        switch self {
        case .firstHatch:
            return "FIRST HATCH"
        case .rareVariant:
            return "RARE VARIANT"
        case .mythic:
            return "MYTHIC"
        }
    }

    var title: String {
        switch self {
        case .firstHatch(let companion):
            return "\(companion.pet.displayName) 부화 완료"
        case .rareVariant(let companion):
            let variant = companion.pet.rareVariant.flatMap { RareVariantMeta.labels[$0] } ?? "Rare"
            return "\(variant) 획득"
        case .mythic(_, let title):
            return title
        }
    }

    var detail: String {
        switch self {
        case .firstHatch:
            return "처음 해독에 성공한 동행체를 스타트 카드로 저장합니다."
        case .rareVariant(let companion):
            return RareVariantMeta.triggerHints[companion.pet.rareVariant ?? .tempoSurge] ?? "희귀 신호를 포착했습니다."
        case .mythic:
            return "최종 진화에 도달한 순간을 전용 포스터로 남깁니다."
        }
    }

    var emphasis: String {
        switch self {
        case .firstHatch:
            return "DECODED"
        case .rareVariant(let companion):
            return companion.pet.rareVariant.flatMap { RareVariantMeta.badges[$0] } ?? "RARE"
        case .mythic:
            return "APEX LOCK"
        }
    }

    var headline: String {
        switch self {
        case .firstHatch:
            return "첫 해독 완료"
        case .rareVariant(let companion):
            let variant = companion.pet.rareVariant.flatMap { RareVariantMeta.labels[$0] } ?? "Rare"
            return "\(variant) 신호 포착"
        case .mythic:
            return "최종 진화 도달"
        }
    }

    var subline: String {
        switch self {
        case .firstHatch:
            return "첫 러닝 루프를 통과한 개체가 현실 슬롯에 정착했습니다."
        case .rareVariant:
            return "돌발 목표와 러닝 패턴이 희귀 변이를 해독했습니다."
        case .mythic:
            return "이 동행체는 현재 시즌에서 가장 높은 단계까지 안정화됐습니다."
        }
    }

    var metrics: [(String, String)] {
        switch self {
        case .firstHatch(let companion):
            return [
                ("SPECIES", companion.pet.displayName),
                ("ELEMENT", companion.pet.element.displayName),
                ("STATUS", "HATCHED"),
            ]
        case .rareVariant(let companion):
            return [
                ("VARIANT", companion.pet.rareVariant.flatMap { RareVariantMeta.labels[$0] } ?? "Rare"),
                ("ELEMENT", companion.pet.element.displayName),
                ("STATUS", "LOCKED"),
            ]
        case .mythic(let companion, let title):
            return [
                ("TITLE", title),
                ("ELEMENT", companion.pet.element.displayName),
                ("STATUS", "MYTHIC"),
            ]
        }
    }
}

private struct MilestoneShareImageCard: View {
    let milestone: ShareMilestone

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, milestone.accent.opacity(0.28), milestone.supportAccent.opacity(0.18), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.08), .clear, .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )

            decorativeBackdrop

            VStack {
                Spacer()
                Circle()
                    .fill(milestone.supportAccent.opacity(0.22))
                    .frame(width: 520, height: 520)
                    .blur(radius: 80)
                    .offset(x: 220, y: 120)
            }

            VStack(alignment: .leading, spacing: 28) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("RUNIMAL")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(milestone.accent)
                        Text(milestone.kicker)
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.82))
                    }

                    Spacer()

                    RunimalSignalBadge(icon: milestone.icon, label: milestone.badge, accent: milestone.accent)
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .fill(.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 36, style: .continuous)
                                .stroke(milestone.accent.opacity(0.30), lineWidth: 2)
                        )

                    VStack(spacing: 16) {
                        PixelPetView(pet: milestone.pet, pixelSize: 14)
                        Text(milestone.emphasis)
                            .font(.system(size: 20, weight: .black, design: .monospaced))
                            .foregroundStyle(milestone.accent)
                    }
                    .padding(.vertical, 34)
                }
                .frame(height: 520)

                VStack(alignment: .leading, spacing: 10) {
                    Text(milestone.headline)
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)

                    Text(milestone.subline)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                }

                HStack(spacing: 16) {
                    ForEach(Array(milestone.metrics.enumerated()), id: \.offset) { _, metric in
                        shareMetric(metric.0, metric.1)
                    }
                }

                HStack {
                    Text("RUNIMAL // DIGITAL GAP FIELD GUIDE")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.46))
                    Spacer()
                    Text(milestone.emphasis)
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .foregroundStyle(milestone.accent)
                }

                Spacer()
            }
            .padding(48)
        }
    }

    @ViewBuilder
    private var decorativeBackdrop: some View {
        switch milestone {
        case .firstHatch:
            hatchBackdrop
        case .rareVariant:
            rareBackdrop
        case .mythic:
            mythicBackdrop
        }
    }

    private var hatchBackdrop: some View {
        ZStack {
            Circle()
                .stroke(milestone.accent.opacity(0.22), lineWidth: 18)
                .frame(width: 460, height: 460)
                .blur(radius: 2)
                .offset(x: 250, y: -80)

            Circle()
                .trim(from: 0.08, to: 0.82)
                .stroke(
                    LinearGradient(
                        colors: [milestone.supportAccent.opacity(0.0), milestone.supportAccent.opacity(0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(width: 320, height: 320)
                .offset(x: 270, y: -40)
        }
    }

    private var rareBackdrop: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill((index % 2 == 0 ? milestone.accent : milestone.supportAccent).opacity(0.16))
                    .frame(width: 320, height: 24)
                    .rotationEffect(.degrees(-28))
                    .offset(x: 260, y: CGFloat(-120 + (index * 44)))
            }

            Circle()
                .stroke(milestone.accent.opacity(0.28), lineWidth: 6)
                .frame(width: 180, height: 180)
                .offset(x: 260, y: -120)
        }
    }

    private var mythicBackdrop: some View {
        ZStack {
            Circle()
                .stroke(milestone.accent.opacity(0.26), lineWidth: 20)
                .frame(width: 380, height: 380)
                .offset(x: 240, y: -30)

            Circle()
                .stroke(milestone.supportAccent.opacity(0.22), lineWidth: 8)
                .frame(width: 280, height: 280)
                .offset(x: 240, y: -30)

            ForEach(0..<8, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(milestone.accent.opacity(0.7))
                    .frame(width: 10, height: 72)
                    .offset(y: -156)
                    .rotationEffect(.degrees(Double(index) * 45))
                    .offset(x: 240, y: -30)
            }
        }
    }

    private func shareMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.56))
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
