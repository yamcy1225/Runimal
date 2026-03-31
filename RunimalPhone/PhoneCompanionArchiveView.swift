import RunimalCore
import SwiftUI

struct PhoneCompanionArchiveView: View {
    let store: PhoneDashboardStore

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                summaryCard
                archiveGrid
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
    }

    private var summaryCard: some View {
        GameSurface(title: "도감 아카이브") {
            VStack(alignment: .leading, spacing: 12) {
                Text("소유했던 동행체와 보낸 기록을 한 곳에 남깁니다.")
                    .font(.footnote.monospaced())
                    .foregroundStyle(GameBoyPalette.mediumDark)

                HStack(spacing: 12) {
                    RunimalMetricTile(
                        icon: "shippingbox.fill",
                        title: "현재 보유",
                        value: "\(store.activeInventoryCompanionCount)",
                        accent: store.pet.accentColor
                    )
                    RunimalMetricTile(
                        icon: "paperplane.fill",
                        title: "보낸 기록",
                        value: "\(store.archivedCompanionCount)",
                        accent: .orange
                    )
                    RunimalMetricTile(
                        icon: "book.closed.fill",
                        title: "총 도감",
                        value: "\(store.companionArchive.count)",
                        accent: .mint
                    )
                }
            }
        }
    }

    private var archiveGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("기록된 동행체")
                .font(.headline.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.darkest)

            if store.companionArchive.isEmpty {
                GameSurface(title: "도감이 비어 있습니다", accent: GameBoyPalette.mediumLight, eyebrow: "ARCHIVE") {
                    Text("동행체를 부화시키거나 러닝으로 성장시키면 기록이 쌓입니다.")
                        .font(.footnote.monospaced())
                        .foregroundStyle(GameBoyPalette.mediumDark)
                }
            } else {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(store.companionArchive) { entry in
                        archiveCard(entry)
                    }
                }
            }
        }
    }

    private func archiveCard(_ entry: CompanionArchiveEntry) -> some View {
        return GameSurface(
            accent: entry.companion.pet.accentColor,
            eyebrow: entry.retired ? "보낸 기록" : "보유 기록"
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
                        pet: entry.companion.pet,
                        pixelSize: 8,
                        mutationForm: store.mutationForm(for: entry.companion),
                        mutationHistory: store.mutationHistory(for: entry.companion)
                    )

                    if entry.retired {
                        RunimalSignalBadge(icon: "paperplane.fill", label: "ARCHIVE", accent: .orange)
                    }
                }
                .frame(height: 108)

                Text(entry.companion.pet.displayName)
                    .font(.subheadline.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)

                if let form = store.mutationForm(for: entry.companion) {
                    Text(form.displayTitle)
                        .font(.caption2.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.mediumDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                if let lore = store.contentCatalog.companionWorldProfile(for: entry.companion.pet) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lore.fantasyLine)
                            .font(.caption2.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)
                            .lineSpacing(3)
                            .lineLimit(2)
                        Text(lore.habitatLine)
                            .font(.caption2.monospaced())
                            .foregroundStyle(GameBoyPalette.mediumDark)
                            .lineSpacing(3)
                            .lineLimit(2)
                    }
                } else {
                    Text(entry.companion.headline)
                        .font(.caption2.monospaced())
                        .foregroundStyle(GameBoyPalette.mediumDark)
                        .lineLimit(2)
                }
            }
        }
    }
}
