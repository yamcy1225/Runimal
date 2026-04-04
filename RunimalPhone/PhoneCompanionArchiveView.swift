import RunimalCore
import SwiftUI

struct PhoneCompanionArchiveView: View {
    let store: PhoneDashboardStore
    @State private var selectedEntry: CompanionArchiveEntry?

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
        .sheet(item: $selectedEntry) { entry in
            let renderState = store.pixelRenderState(for: entry.companion)
            PhonePetDetailPanel(
                companion: entry.companion,
                mutationForm: renderState.mutationForm,
                mutationHistory: renderState.mutationHistory,
                mutationVisualState: renderState.mutationVisualState,
                growthStageIndex: renderState.growthStageIndex,
                mutationEvidence: store.mutationEvidence(for: entry.companion),
                worldProfile: store.worldProfile(for: entry.companion),
                speciesIdentity: store.speciesIdentity(for: entry.companion),
                variantNarrative: store.variantNarrative(for: entry.companion),
                worldStatus: store.worldStatus(for: entry.companion),
                narrativeSummary: store.narrativeSummary(for: entry.companion),
                nextEpisodeFocus: store.nextEpisodeFocus(for: entry.companion),
                progress: RunimalCompanionGrowthEngine.evolutionProgress(
                    for: store.progress.growthRecord(for: entry.companion.id),
                    species: entry.companion.pet.species
                ),
                activeEffects: store.activeWeeklyEffects,
                season: store.weeklyBoard.season
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var summaryCard: some View {
        GameSurface(title: "도감 아카이브") {
            VStack(alignment: .leading, spacing: 12) {
                Text("함께했던 동행과 보낸 기록을 한 곳에 남깁니다.")
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
            Text("기록된 동행")
                .font(.headline.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.darkest)

            if store.companionArchive.isEmpty {
                GameSurface(title: "도감이 비어 있습니다", accent: GameBoyPalette.mediumLight, eyebrow: "ARCHIVE") {
                    Text("동행을 부화시키거나 러닝으로 성장시키면 기록이 쌓입니다.")
                        .font(.footnote.monospaced())
                        .foregroundStyle(GameBoyPalette.mediumDark)
                }
            }

            if store.companionArchive.isEmpty == false {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(store.companionArchive) { entry in
                        archiveCard(entry)
                    }
                }
            }

            if store.archivePreviewEntries.isEmpty == false {
                previewSection
            }
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("유아기 5종 미리보기")
                .font(.headline.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.darkest)

            Text("실제 보유와 별개로, 유아기 기본 디자인을 종별로 확인하는 카드입니다.")
                .font(.footnote.monospaced())
                .foregroundStyle(GameBoyPalette.mediumDark)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(store.archivePreviewEntries) { entry in
                    archiveCard(entry)
                }
            }
        }
    }

    private func archiveCard(_ entry: CompanionArchiveEntry) -> some View {
        let renderState = store.pixelRenderState(for: entry)
        return GameSurface(
            accent: entry.companion.pet.accentColor,
            eyebrow: entry.preview ? "유아기 미리보기" : (entry.retired ? "보낸 기록" : "보유 기록")
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
                        growthStageIndex: renderState.growthStageIndex,
                        mutationForm: renderState.mutationForm,
                        mutationHistory: renderState.mutationHistory,
                        mutationVisualState: renderState.mutationVisualState
                    )

                    if entry.retired {
                        RunimalSignalBadge(icon: "paperplane.fill", label: "ARCHIVE", accent: .orange)
                    }
                }
                .frame(height: 108)

                HStack(alignment: .center, spacing: 8) {
                    Text(entry.companion.pet.displayName)
                        .font(.subheadline.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.darkest)

                    Spacer(minLength: 0)

                    if entry.preview {
                        RunimalSignalBadge(icon: "eye.fill", label: "PREVIEW", accent: .mint)
                    }
                }

                if let form = renderState.mutationForm {
                    Text(form.displayTitle)
                        .font(.caption2.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.mediumDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                } else if entry.preview {
                    Text("유아기 기본형")
                        .font(.caption2.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.mediumDark)
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

                if entry.preview {
                    Text("보관함 확인용 카드")
                        .font(.caption2.monospaced())
                        .foregroundStyle(GameBoyPalette.mediumDark)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(GameBoyPalette.lightest)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(GameBoyPalette.darkest, lineWidth: 1.5)
                        )
                } else {
                    detailButton(for: entry)
                }
            }
        }
    }

    private func detailButton(for entry: CompanionArchiveEntry) -> some View {
        Button {
            selectedEntry = entry
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "book.closed")
                    .font(.caption.monospaced())
                Text("상세 보기")
                    .font(.caption.monospaced().weight(.black))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.black))
            }
            .foregroundStyle(GameBoyPalette.darkest)
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(GameBoyPalette.mediumLight.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(GameBoyPalette.darkest, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(entry.companion.pet.displayName) 상세 보기")
    }
}
