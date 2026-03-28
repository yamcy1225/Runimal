import RunimalCore
import SwiftUI

struct PhoneCompanionRosterPanel: View {
    let mainSelection: MainCompanionSelection?
    let mainLabel: String
    let mainDetail: String
    let companions: [PetCollectionEntry]
    let eggs: [EggInventoryEntry]
    let onSelectPet: (String) -> Void
    let onSelectEgg: (String) -> Void
    let onHatchEgg: (String) -> Void

    var body: some View {
        GameSurface(title: "메인 슬롯", accent: .orange, eyebrow: "함께 달릴 동행체") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    RunimalSignalBadge(icon: "star.fill", label: mainLabel, accent: .green)
                    RunimalSignalBadge(icon: "waveform.path.ecg", label: "활성 링크", accent: .white.opacity(0.2))
                }

                if eggs.isEmpty == false {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("메인 알 후보")
                            .font(.caption.weight(.black))
                            .tracking(1.1)
                            .foregroundStyle(.orange.opacity(0.9))

                        ForEach(eggs) { egg in
                            HStack(alignment: .center, spacing: 12) {
                                portraitTile(accent: egg.shell.accentColor, supportAccent: egg.shell.particleColor) {
                                    TraceEggView(accent: egg.shell.accentColor, shell: egg.shell, pixelSize: 6.6, cracked: egg.readyToHatch)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(egg.title)
                                        .font(.subheadline.weight(.black))
                                        .foregroundStyle(.white)
                                    Text(egg.shell.scanHeadline)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.62))
                                        .lineLimit(2)
                                    RunimalProgressBar(progress: egg.progressRatio, accent: egg.shell.accentColor, height: 7)
                                    HStack(spacing: 6) {
                                        TraitChip(label: egg.shell.displayLabel, accent: egg.shell.accentColor)
                                        TraitChip(label: "\(egg.storedExperience) XP", accent: .white.opacity(0.2))
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        ForEach(egg.shell.scanLogLines.prefix(2), id: \.self) { line in
                                            Text(line)
                                                .font(.caption2.monospaced())
                                                .foregroundStyle(.white.opacity(0.48))
                                                .lineLimit(1)
                                        }
                                    }
                                }

                                Spacer()

                                VStack(spacing: 8) {
                                    Button(mainSelection?.targetID == egg.id && mainSelection?.kind == .egg ? "메인 알" : "선택") {
                                        onSelectEgg(egg.id)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(egg.shell.accentColor)

                                    Button("디코딩") {
                                        onHatchEgg(egg.id)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.green)
                                    .disabled(!egg.readyToHatch)
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("메인 펫 후보")
                        .font(.caption.weight(.black))
                        .tracking(1.1)
                        .foregroundStyle(.white.opacity(0.78))

                    ForEach(companions) { companion in
                        HStack(alignment: .center, spacing: 12) {
                            portraitTile(accent: companion.pet.accentColor, supportAccent: companion.pet.accentColor.opacity(0.24)) {
                                PixelPetView(pet: companion.pet, pixelSize: 6.6)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(companion.pet.displayName)
                                    .font(.subheadline.weight(.black))
                                    .foregroundStyle(.white)
                                HStack(spacing: 6) {
                                    TraitChip(label: "Lv.\(companion.level)", accent: companion.pet.accentColor)
                                    TraitChip(label: "유대 \(companion.bond)", accent: .white.opacity(0.2))
                                }
                            }

                            Spacer()

                            Button(mainSelection?.targetID == companion.id && mainSelection?.kind == .pet ? "메인 펫" : "선택") {
                                onSelectPet(companion.id)
                            }
                            .buttonStyle(.bordered)
                            .tint(companion.pet.accentColor)
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
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            .black.opacity(0.9),
                            accent.opacity(0.16),
                            supportAccent.opacity(0.12),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )

            Circle()
                .fill(supportAccent.opacity(0.16))
                .frame(width: 42, height: 42)
                .blur(radius: 12)

            content()
                .scaleEffect(1.06)
        }
        .frame(width: 72, height: 72)
    }
}
