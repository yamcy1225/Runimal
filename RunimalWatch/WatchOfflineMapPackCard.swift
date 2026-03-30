import RunimalCore
import SwiftUI

struct WatchOfflineMapPackCard: View {
    let packs: [OfflineMapPackSummary]
    let selectedPackID: String?
    let storedPackIDs: Set<String>
    let storage: WatchOfflineMapPackStorage
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
                            Text("\(selectedPack.archiveFormat.rawValue.uppercased()) · Z\(selectedPack.minZoom)-\(selectedPack.maxZoom)")
                                .font(.caption2.monospaced())
                                .foregroundStyle(GameBoyPalette.mediumDark)
                            Text(statusLabel(for: selectedPack))
                                .font(.caption2.monospaced().weight(.black))
                                .foregroundStyle(statusColor(for: selectedPack))
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
                            Text("\(pack.archiveFormat.rawValue.uppercased()) · Z\(pack.minZoom)-\(pack.maxZoom) · 타일 \(pack.tileCount)")
                                .font(.caption2.monospaced())
                                .foregroundStyle(GameBoyPalette.mediumDark)
                            Text(statusLabel(for: pack))
                                .font(.caption2.monospaced().weight(.black))
                                .foregroundStyle(statusColor(for: pack))
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

    private func statusLabel(for pack: OfflineMapPackSummary) -> String {
        switch availabilityStatus(for: pack) {
        case .ready:
            return "미리보기 가능"
        case .missingManifest:
            return "manifest 없음"
        case .invalidManifest:
            return "manifest 오류"
        case .missingArchive:
            return "지도 파일 없음"
        case .emptyArchive:
            return "지도 파일 비어 있음"
        }
    }

    private func statusColor(for pack: OfflineMapPackSummary) -> Color {
        switch availabilityStatus(for: pack) {
        case .ready:
            return .green
        case .missingArchive:
            return .orange
        case .missingManifest, .invalidManifest, .emptyArchive:
            return .red
        }
    }

    private func availabilityStatus(for pack: OfflineMapPackSummary) -> WatchOfflineMapPackStorage.PackAvailabilityStatus {
        storage.availabilityStatus(for: pack.id)
    }
}
