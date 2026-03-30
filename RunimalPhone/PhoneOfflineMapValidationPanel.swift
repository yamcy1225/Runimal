import RunimalCore
import SwiftUI

struct PhoneOfflineMapValidationPanel: View {
    let selectedPack: OfflineMapPackSummary?
    let isStoredOnWatch: Bool
    let transferStatusLabel: String
    let accent: Color
    let onOpenDetail: () -> Void
    let onImportTiles: () -> Void
    let onSend: () -> Void

    var body: some View {
        GameSurface(title: "지도 검증 준비", accent: accent, eyebrow: "오프라인 QA") {
            VStack(alignment: .leading, spacing: 8) {
                if let selectedPack {
                    detailLine("현재 팩", selectedPack.title)
                    detailLine("포맷", selectedPack.archiveFormat.rawValue.uppercased())
                    detailLine("로컬 파일", selectedPack.tilesReady && selectedPack.byteCount > 0 ? "준비 완료" : "파일 연결 필요")
                    detailLine("watch 저장", isStoredOnWatch ? "완료" : "아직 없음")
                    detailLine("전송 상태", transferStatusLabel)
                    Text(nextActionLabel(for: selectedPack))
                        .font(.caption2.monospaced())
                        .foregroundStyle(GameBoyPalette.mediumDark)

                    HStack(spacing: 10) {
                        actionButton("상세", fill: GameBoyPalette.lightest, foreground: GameBoyPalette.darkest, action: onOpenDetail)
                        actionButton("파일 연결", fill: GameBoyPalette.lightest, foreground: GameBoyPalette.darkest, action: onImportTiles)
                        actionButton("전송", fill: GameBoyPalette.mediumDark, foreground: GameBoyPalette.lightest, action: onSend)
                    }
                } else {
                    Text("선택된 지도 팩이 없습니다. 먼저 팩을 만들고 파일을 연결해야 실기 검증이 가능합니다.")
                        .font(.caption2.monospaced())
                        .foregroundStyle(GameBoyPalette.mediumDark)
                }
            }
        }
    }

    private func nextActionLabel(for pack: OfflineMapPackSummary) -> String {
        if pack.tilesReady == false || pack.byteCount <= 0 {
            return "다음 단계: \(pack.archiveFormat.rawValue.uppercased()) 파일을 연결하세요."
        }
        if isStoredOnWatch == false {
            return "다음 단계: watch로 전송해 실제 프리뷰를 확인하세요."
        }
        return "다음 단계: watch 지도 페이지에서 현재 위치/타일 프리뷰를 실기 검증하세요."
    }

    private func detailLine(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.caption.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.mediumDark)
                .frame(width: 62, alignment: .leading)
            Text(value)
                .font(.caption.monospaced())
                .foregroundStyle(GameBoyPalette.darkest)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func actionButton(_ title: String, fill: Color, foreground: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.monospaced().weight(.black))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(fill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(GameBoyPalette.darkest, lineWidth: 2)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
