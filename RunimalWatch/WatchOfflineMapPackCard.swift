import RunimalCore
import SwiftUI

struct WatchOfflineMapPackCard: View {
    let packs: [OfflineMapPackSummary]
    let selectedPackID: String?
    let storedPackIDs: Set<String>
    let accent: Color

    var body: some View {
        GameSurface(title: "지도", accent: accent, compact: true) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("수신된 팩")
                        .font(.caption2.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.mediumDark)
                    Spacer()
                    Text("\(packs.count)개")
                        .font(.caption.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.darkest)
                }

                HStack {
                    Text("로컬 저장")
                        .font(.caption2.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.mediumDark)
                    Spacer()
                    Text("\(storedPackIDs.count)개")
                        .font(.caption.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.darkest)
                }

                if packs.isEmpty {
                    Text("아직 받은 오프라인 지도 팩이 없습니다.")
                        .font(.caption2.monospaced())
                        .foregroundStyle(GameBoyPalette.mediumDark)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    if let selectedPack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("현재 팩")
                                .font(.caption2.monospaced().weight(.black))
                                .foregroundStyle(GameBoyPalette.mediumDark)
                            Text(selectedPack.title)
                                .font(.caption.monospaced().weight(.black))
                                .foregroundStyle(GameBoyPalette.darkest)
                            Text("Z\(selectedPack.minZoom)-\(selectedPack.maxZoom)")
                                .font(.caption2.monospaced())
                                .foregroundStyle(GameBoyPalette.mediumDark)
                        }
                        .padding(.bottom, 4)
                    }

                    ForEach(Array(packs.prefix(3))) { pack in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(pack.title)
                                if selectedPackID == pack.id {
                                    Text("LIVE")
                                        .font(.caption2.monospaced().weight(.black))
                                        .foregroundStyle(GameBoyPalette.lightest)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                .fill(GameBoyPalette.mediumDark)
                                        )
                                }
                                if storedPackIDs.contains(pack.id) {
                                    Text("LOCAL")
                                        .font(.caption2.monospaced().weight(.black))
                                        .foregroundStyle(GameBoyPalette.darkest)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                .fill(GameBoyPalette.mediumLight)
                                        )
                                }
                            }
                            .font(.caption.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)
                            Text("Z\(pack.minZoom)-\(pack.maxZoom) · 타일 \(pack.tileCount)")
                                .font(.caption2.monospaced())
                                .foregroundStyle(GameBoyPalette.mediumDark)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private var selectedPack: OfflineMapPackSummary? {
        guard let selectedPackID else { return packs.first }
        return packs.first(where: { $0.id == selectedPackID }) ?? packs.first
    }
}
