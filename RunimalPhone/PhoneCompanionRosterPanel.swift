import RunimalCore
import SwiftUI

struct PhoneCompanionRosterPanel: View {
    let mainSelection: MainCompanionSelection?
    let mainLabel: String
    let mainDetail: String
    let companions: [PetCollectionEntry]
    let eggs: [EggInventoryEntry]
    let mutationForm: (PetCollectionEntry) -> MutationFormSnapshot?
    let mutationHistory: (PetCollectionEntry) -> MutationHistorySnapshot?
    let pixelRenderState: (PetCollectionEntry) -> CompanionPixelRenderState
    let onSelectPet: (String) -> Void
    let onSelectEgg: (String) -> Void
    let onHatchEgg: (String) -> Void

    var body: some View {
        GameSurface(title: "대표 선택", accent: GameBoyPalette.mediumDark, eyebrow: "함께 달릴 동행") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    RunimalSignalBadge(icon: "star.fill", label: mainLabel, accent: GameBoyPalette.mediumDark)
                    RunimalSignalBadge(icon: "waveform.path.ecg", label: "활성 링크", accent: GameBoyPalette.mediumLight)
                }

                if eggs.isEmpty == false {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("고를 수 있는 알")
                            .font(.caption.monospaced().weight(.black))
                            .tracking(1.1)
                            .foregroundStyle(GameBoyPalette.mediumDark)

                        ForEach(eggs) { egg in
                            HStack(alignment: .center, spacing: 12) {
                                portraitTile(accent: egg.shell.accentColor, supportAccent: egg.shell.particleColor) {
                                    TraceEggView(accent: egg.shell.accentColor, shell: egg.shell, pixelSize: 6.6, cracked: egg.readyToHatch)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(egg.title)
                                        .font(.subheadline.monospaced().weight(.black))
                                        .foregroundStyle(GameBoyPalette.darkest)
                                    Text(egg.shell.scanHeadline)
                                        .font(.caption.monospaced())
                                        .foregroundStyle(GameBoyPalette.mediumDark)
                                        .lineLimit(2)
                                    RunimalProgressBar(progress: egg.progressRatio, accent: egg.shell.accentColor, height: 7)
                                    HStack(spacing: 6) {
                                        TraitChip(label: egg.shell.displayLabel, accent: egg.shell.accentColor)
                                        TraitChip(label: "\(egg.storedExperience) XP", accent: GameBoyPalette.mediumLight)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        ForEach(egg.shell.scanLogLines.prefix(2), id: \.self) { line in
                                            Text(line)
                                                .font(.caption2.monospaced())
                                                .foregroundStyle(GameBoyPalette.mediumDark.opacity(0.84))
                                                .lineLimit(1)
                                        }
                                    }
                                }

                                Spacer()

                                VStack(spacing: 8) {
                                    pixelActionButton(
                                        title: mainSelection?.targetID == egg.id && mainSelection?.kind == .egg ? "지금 선택" : "선택",
                                        accent: egg.shell.accentColor
                                    ) {
                                        onSelectEgg(egg.id)
                                    }

                                    pixelActionButton(
                                        title: "부화",
                                        accent: egg.readyToHatch ? GameBoyPalette.mediumDark : GameBoyPalette.mediumLight,
                                        filled: egg.readyToHatch
                                    ) {
                                        onHatchEgg(egg.id)
                                    }
                                    .disabled(!egg.readyToHatch)
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("고를 수 있는 동행")
                        .font(.caption.monospaced().weight(.black))
                        .tracking(1.1)
                        .foregroundStyle(GameBoyPalette.mediumDark)

                    ForEach(companions) { companion in
                        let renderState = pixelRenderState(companion)
                        HStack(alignment: .center, spacing: 12) {
                            portraitTile(accent: companion.pet.accentColor, supportAccent: companion.pet.accentColor.opacity(0.24)) {
                                PixelPetView(
                                    pet: companion.pet,
                                    pixelSize: 6.6,
                                    growthStageIndex: renderState.growthStageIndex,
                                    mutationForm: renderState.mutationForm,
                                    mutationHistory: renderState.mutationHistory,
                                    mutationVisualState: renderState.mutationVisualState
                                )
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(companion.pet.displayName)
                                    .font(.subheadline.monospaced().weight(.black))
                                    .foregroundStyle(GameBoyPalette.darkest)
                                if let form = renderState.mutationForm {
                                    Text(form.displayTitle)
                                        .font(.caption2.monospaced().weight(.black))
                                        .foregroundStyle(GameBoyPalette.mediumDark)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.68)
                                }
                                HStack(spacing: 6) {
                                    TraitChip(label: "Lv.\(companion.level)", accent: companion.pet.accentColor)
                                    TraitChip(label: "유대 \(companion.bond)", accent: GameBoyPalette.mediumLight)
                                }
                            }

                            Spacer()

                            pixelActionButton(
                                title: mainSelection?.targetID == companion.id && mainSelection?.kind == .pet ? "지금 선택" : "선택",
                                accent: companion.pet.accentColor
                            ) {
                                onSelectPet(companion.id)
                            }
                        }
                    }
                }
            }
        }
    }

    private func portraitTile<Content: View>(
        accent: Color,
        supportAccent: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(GameBoyPalette.lightest)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(GameBoyPalette.darkest, lineWidth: 2)
                )

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(GameBoyPalette.mediumLight.opacity(0.18))
                .padding(5)

            GameBoyLCDOverlay()
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(3)

            Rectangle()
                .fill(accent.opacity(0.82))
                .frame(width: 14, height: 4)
                .offset(x: -23, y: -26)

            content()
                .scaleEffect(1.06)
        }
        .frame(width: 72, height: 72)
    }

    private func pixelActionButton(
        title: String,
        accent: Color,
        filled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(.caption2.monospaced().weight(.black))
                .tracking(0.6)
                .foregroundStyle(filled ? GameBoyPalette.lightest : GameBoyPalette.darkest)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .frame(minWidth: 56)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(filled ? accent : GameBoyPalette.lightest)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(GameBoyPalette.darkest, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
