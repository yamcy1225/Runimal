import RunimalCore
import SwiftUI

private struct InventoryHatchCinematicPayload: Identifiable {
    let egg: EggInventoryEntry
    let pet: PetCollectionEntry

    var id: String { egg.id }
}

struct PhoneInventoryView: View {
    let store: PhoneDashboardStore
    @State private var hatchResult: InventoryHatchCinematicPayload?

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                watchReadyCard
                eggSection
                companionSection
            }
            .padding(20)
        }
        .background(
            ZStack {
                GameBoyPalette.lightest
                    .ignoresSafeArea()
                GameBoyLCDOverlay()
                    .ignoresSafeArea()
            }
        )
        .fullScreenCover(item: $hatchResult) { payload in
            HatchCinematicView(egg: payload.egg, pet: payload.pet) {
                hatchResult = nil
            }
        }
    }

    private var watchReadyCard: some View {
        GameSurface(title: "워치로 들고 나갈 대상") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(store.watchAccentColor.opacity(0.18))
                            .frame(width: 90, height: 90)
                            .blur(radius: 8)

                        if store.watchSelection?.kind == .egg {
                            TraceEggView(
                                accent: store.watchAccentColor,
                                shell: store.watchEgg?.shell,
                                pixelSize: 9,
                                cracked: store.watchEgg?.readyToHatch == true,
                                resonance: store.mainEggResonance
                            )
                        } else {
                            PixelPetView(
                                pet: store.watchPet?.pet ?? store.featuredCompanion.pet,
                                pixelSize: 9,
                                seasonalLayers: store.watchSelection?.kind == .pet ? store.seasonalLayers : []
                            )
                        }
                    }
                    .frame(width: 96, height: 96)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.watchSelectionLabel)
                            .font(.title3.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)
                        Text(store.watchSelectionDetail)
                            .font(.footnote.monospaced())
                            .foregroundStyle(GameBoyPalette.mediumDark)
                            .lineLimit(3)

                        HStack(spacing: 8) {
                            TraitChip(
                                label: store.watchSelection?.kind == .egg ? "알" : "동행체",
                                accent: store.watchAccentColor
                            )
                            TraitChip(
                                label: "워치 동기화 대상",
                                accent: GameBoyPalette.mediumLight
                            )
                        }
                    }
                }

                HStack(spacing: 12) {
                    RunimalMetricTile(
                        icon: "shippingbox.fill",
                        title: "동행체",
                        value: "\(store.activeInventoryCompanionCount)",
                        accent: store.pet.accentColor
                    )
                    RunimalMetricTile(
                        icon: "sparkles",
                        title: "알",
                        value: "\(store.eggInventory.count)",
                        accent: .mint
                    )
                    RunimalMetricTile(
                        icon: "book.closed.fill",
                        title: "도감",
                        value: "\(store.companionArchive.count)",
                        accent: .orange
                    )
                }
            }
        }
    }

    private var eggSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                "알",
                detail: "현재 가지고 있는 알만 보여줍니다.",
                support: "선택하면 워치 첫 화면이 이 알 기준으로 바뀝니다."
            )

            if store.eggInventory.isEmpty {
                emptyCard("아직 가진 알이 없습니다", detail: "러닝 코어로 새 알을 만들면 여기에 들어옵니다.")
            } else {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(store.eggInventory) { egg in
                        GameSurface(
                            accent: egg.shell.accentColor,
                            eyebrow: store.watchSelection?.kind == .egg && store.watchSelection?.targetID == egg.id ? "워치 선택됨" : "보유 중"
                        ) {
                            VStack(alignment: .leading, spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(GameBoyPalette.lightest)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(GameBoyPalette.darkest, lineWidth: 2)
                                        )
                                    TraceEggView(
                                        accent: egg.shell.accentColor,
                                        shell: egg.shell,
                                        pixelSize: 7.6,
                                        cracked: egg.readyToHatch,
                                        resonance: min(max(egg.progressRatio, 0.18), 1)
                                    )
                                }
                                .frame(height: 102)

                                Text(egg.title)
                                    .font(.subheadline.monospaced().weight(.black))
                                    .foregroundStyle(GameBoyPalette.darkest)

                                HStack(spacing: 6) {
                                    TraitChip(label: egg.shell.displayLabel, accent: egg.shell.accentColor)
                                    TraitChip(label: "\(egg.storedExperience) XP", accent: GameBoyPalette.mediumLight)
                                }

                                RunimalProgressBar(progress: egg.progressRatio, accent: egg.shell.accentColor, height: 7)

                                Text(egg.readyToHatch ? "바로 부화 가능" : egg.shell.hatchHint)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(GameBoyPalette.mediumDark)
                                    .lineLimit(2)

                                HStack(spacing: 8) {
                                    inventoryButton(
                                        title: store.watchSelection?.kind == .egg && store.watchSelection?.targetID == egg.id ? "선택됨" : "워치로",
                                        accent: egg.shell.accentColor,
                                        filled: true,
                                        disabled: store.watchSelection?.kind == .egg && store.watchSelection?.targetID == egg.id
                                    ) {
                                        store.selectEggForWatch(egg.id)
                                    }

                                    inventoryButton(
                                        title: "부화",
                                        accent: GameBoyPalette.mediumLight,
                                        filled: false,
                                        disabled: !egg.readyToHatch
                                    ) {
                                        handleHatch(egg.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var companionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                "동행체",
                detail: "현재 함께 데리고 나갈 후보만 남깁니다.",
                support: "선택 버튼 하나로 워치 첫 화면 대상을 바꿉니다."
            )

            if store.collection.isEmpty {
                emptyCard("현재 가진 동행체가 없습니다", detail: "알을 부화시키면 여기서 바로 선택할 수 있습니다.")
            } else {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(store.collection) { entry in
                        GameSurface(
                            accent: entry.pet.accentColor,
                            eyebrow: store.watchSelection?.kind == .pet && store.watchSelection?.targetID == entry.id ? "워치 선택됨" : "보유 중"
                        ) {
                            VStack(alignment: .leading, spacing: 12) {
                                ZStack(alignment: .topTrailing) {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(GameBoyPalette.lightest)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(GameBoyPalette.darkest, lineWidth: 2)
                                        )

                                    PixelPetView(
                                        pet: entry.pet,
                                        pixelSize: 8,
                                        seasonalLayers: store.watchSelection?.kind == .pet && store.watchSelection?.targetID == entry.id ? store.seasonalLayers : []
                                    )

                                    if store.watchSelection?.kind == .pet && store.watchSelection?.targetID == entry.id {
                                        RunimalSignalBadge(icon: "star.fill", label: "WATCH", accent: .green)
                                    }
                                }
                                .frame(height: 106)

                                Text(entry.pet.displayName)
                                    .font(.subheadline.monospaced().weight(.black))
                                    .foregroundStyle(GameBoyPalette.darkest)

                                HStack(spacing: 6) {
                                    TraitChip(label: "Lv.\(entry.level)", accent: entry.pet.accentColor)
                                    TraitChip(label: "\(entry.totalDistanceKm.formatted(.number.precision(.fractionLength(1))))km", accent: GameBoyPalette.mediumLight)
                                }

                                Text(entry.headline)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(GameBoyPalette.mediumDark)
                                    .lineLimit(2)

                                inventoryButton(
                                    title: store.watchSelection?.kind == .pet && store.watchSelection?.targetID == entry.id ? "선택됨" : "워치로",
                                    accent: entry.pet.accentColor,
                                    filled: true,
                                    disabled: store.watchSelection?.kind == .pet && store.watchSelection?.targetID == entry.id
                                ) {
                                    store.selectCompanionForWatch(entry.id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String, detail: String, support: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.monospaced().weight(.black))
                .tracking(1.2)
                .foregroundStyle(GameBoyPalette.mediumDark)
            Text(detail)
                .font(.headline.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.darkest)
            Text(support)
                .font(.footnote.monospaced())
                .foregroundStyle(GameBoyPalette.mediumDark)
        }
    }

    private func emptyCard(_ title: String, detail: String) -> some View {
        GameSurface(title: title, accent: GameBoyPalette.mediumLight, eyebrow: "비어 있음") {
            Text(detail)
                .font(.footnote.monospaced())
                .foregroundStyle(GameBoyPalette.mediumDark)
        }
    }

    private func inventoryButton(
        title: String,
        accent: Color,
        filled: Bool,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.monospaced().weight(.black))
                .foregroundStyle(filled ? GameBoyPalette.lightest : GameBoyPalette.darkest)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(filled ? accent : GameBoyPalette.lightest)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(GameBoyPalette.darkest, lineWidth: 2)
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.78 : 1)
    }

    private func handleHatch(_ eggID: String) {
        guard let egg = store.eggInventory.first(where: { $0.id == eggID }) else { return }
        guard let pet = store.hatchEgg(eggID) else { return }
        hatchResult = InventoryHatchCinematicPayload(egg: egg, pet: pet)
    }
}
