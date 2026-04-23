import RunimalCore
import SwiftUI

struct PhoneRareVariantShowcasePanel: View {
    let activeVariant: RareVariant?

    private let variants = RareVariant.allCases

    var body: some View {
        GameSurface(title: "희귀 변이 쇼케이스", accent: .orange.opacity(0.86), eyebrow: "5종 변이") {
            VStack(alignment: .leading, spacing: 14) {
                if let activeVariant {
                    spotlightCard(for: activeVariant)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(variants, id: \.self) { variant in
                            variantCard(for: variant)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
    }

    private func variantCard(for variant: RareVariant) -> some View {
        let pet = showcasePet(for: variant)
        let isActive = activeVariant == variant
        let accent = showcaseColor(for: variant)

        return VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(accent.opacity(0.10))
                    .frame(width: 148, height: 118)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(accent.opacity(isActive ? 0.72 : 0.28), lineWidth: isActive ? 1.6 : 1)
                    )

                PixelPetView(pet: pet, pixelSize: 7)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if isActive {
                    RunimalSignalBadge(icon: "star.fill", label: "현재", accent: .green)
                        .padding(8)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(RareVariantMeta.labels[variant] ?? variant.rawValue)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(RareVariantMeta.triggerHints[variant] ?? "패턴 미정")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(2)
            }

            TraitChip(label: RareVariantMeta.badges[variant] ?? "VARIANT", accent: accent.opacity(0.82))
        }
        .frame(width: 148)
    }

    private func spotlightCard(for variant: RareVariant) -> some View {
        let accent = showcaseColor(for: variant)

        return HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.18))
                    .frame(width: 86, height: 86)
                    .blur(radius: 16)

                PixelPetView(pet: showcasePet(for: variant), pixelSize: 8)
            }
            .frame(width: 96, height: 96)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(accent.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(accent.opacity(0.32), lineWidth: 1.2)
                    )
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    RunimalSignalBadge(icon: "sparkles", label: "ACTIVE SIGNAL", accent: accent)
                    TraitChip(label: RareVariantMeta.badges[variant] ?? "VARIANT", accent: .white.opacity(0.18))
                }

                Text(RareVariantMeta.labels[variant] ?? variant.rawValue)
                    .font(.headline.weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)

                Text("희귀 변이는 숫자 보너스보다 먼저 한눈에 다른 존재처럼 읽혀야 합니다. 현재 활성 변이를 메인 배너에서 바로 확인합니다.")
                    .font(.caption)
                    .foregroundStyle(GameBoyPalette.mediumDark)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(accent.opacity(0.18), lineWidth: 1)
                )
        )
    }

    private func showcasePet(for variant: RareVariant) -> GeneratedPet {
        switch variant {
        case .tempoSurge:
            return GeneratedPet(species: .sparkfang, element: .flame, palette: PetSpecies.sparkfang.paletteName(rareVariant: .tempoSurge), rareVariant: .tempoSurge, explanation: [], stats: PetStats(vitality: 10, agility: 14, dexterity: 15, focus: 9, defense: 8))
        case .zenBloom:
            return GeneratedPet(species: .mosshop, element: .leaf, palette: PetSpecies.mosshop.paletteName(rareVariant: .zenBloom), rareVariant: .zenBloom, explanation: [], stats: PetStats(vitality: 14, agility: 8, dexterity: 9, focus: 14, defense: 10))
        case .summitHeart:
            return GeneratedPet(species: .stoneback, element: .earth, palette: PetSpecies.stoneback.paletteName(rareVariant: .summitHeart), rareVariant: .summitHeart, explanation: [], stats: PetStats(vitality: 15, agility: 8, dexterity: 8, focus: 10, defense: 15))
        case .eclipseMark:
            return GeneratedPet(species: .shadebit, element: .lunar, palette: PetSpecies.shadebit.paletteName(rareVariant: .eclipseMark), rareVariant: .eclipseMark, explanation: [], stats: PetStats(vitality: 9, agility: 13, dexterity: 12, focus: 15, defense: 8))
        case .loopSigil:
            return GeneratedPet(species: .windrunner, element: .light, palette: PetSpecies.windrunner.paletteName(rareVariant: .loopSigil), rareVariant: .loopSigil, explanation: [], stats: PetStats(vitality: 10, agility: 15, dexterity: 12, focus: 13, defense: 9))
        }
    }

    private func showcaseColor(for variant: RareVariant) -> Color {
        switch variant {
        case .tempoSurge: return .orange
        case .zenBloom: return .mint
        case .summitHeart: return Color(red: 0.86, green: 0.72, blue: 0.46)
        case .eclipseMark: return .indigo
        case .loopSigil: return .cyan
        }
    }
}
