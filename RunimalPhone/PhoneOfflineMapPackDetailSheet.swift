import RunimalCore
import SwiftUI

struct PhoneOfflineMapPackDetailSheet: View {
    let pack: OfflineMapPackSummary
    let isSelected: Bool
    let isStoredOnWatch: Bool
    let isCatalogDelivered: Bool
    let transferStatusLabel: String
    let readinessLabel: String
    let readinessColor: Color
    let queuedAt: Date?
    let completedAt: Date?
    let transferFailure: String?
    let onSelect: () -> Void
    let onImportTiles: () -> Void
    let onSend: () -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    GameSurface(title: "팩 상세", accent: readinessColor, eyebrow: pack.archiveFormat.rawValue.uppercased()) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(pack.title)
                                .font(.headline.monospaced().weight(.black))
                                .foregroundStyle(GameBoyPalette.darkest)
                            Text(statusLine)
                                .font(.caption.monospaced())
                                .foregroundStyle(GameBoyPalette.mediumDark)
                            Text(readinessLabel)
                                .font(.caption.monospaced().weight(.black))
                                .foregroundStyle(readinessColor)
                            Text(transferStatusLabel)
                                .font(.caption2.monospaced())
                                .foregroundStyle(GameBoyPalette.mediumDark)
                        }
                    }

                    metricRow

                    GameSurface(title: "파일", accent: GameBoyPalette.mediumDark) {
                        VStack(alignment: .leading, spacing: 6) {
                            detailLine("포맷", pack.archiveFormat.rawValue.uppercased())
                            detailLine("파일명", pack.archiveFilename)
                            detailLine("용량", byteLabel(pack.byteCount))
                            detailLine("출처", pack.sourceLabel)
                            detailLine("라이선스", pack.licenseLabel)
                            detailLine("저작권", pack.attributionText)
                        }
                    }

                    GameSurface(title: "범위", accent: GameBoyPalette.mediumDark) {
                        VStack(alignment: .leading, spacing: 6) {
                            detailLine("줌", "Z\(pack.minZoom)-\(pack.maxZoom)")
                            detailLine("타일", "\(pack.tileCount)개")
                            detailLine("위도", "\(format(pack.boundingBox.minLatitude)) ~ \(format(pack.boundingBox.maxLatitude))")
                            detailLine("경도", "\(format(pack.boundingBox.minLongitude)) ~ \(format(pack.boundingBox.maxLongitude))")
                        }
                    }

                    GameSurface(title: "Watch 상태", accent: isStoredOnWatch ? .green : .orange) {
                        VStack(alignment: .leading, spacing: 6) {
                            detailLine("카탈로그", isCatalogDelivered ? "전달됨" : "미전달")
                            detailLine("로컬 저장", isStoredOnWatch ? "완료" : "아직 없음")
                            detailLine("선택", isSelected ? "사용 중" : "대기")
                            detailLine("큐 등록", queuedAt.map(timeLabel) ?? "기록 없음")
                            detailLine("저장 완료", completedAt.map(timeLabel) ?? "기록 없음")
                            if let transferFailure, transferFailure.isEmpty == false {
                                detailLine("전송 오류", transferFailure)
                            }
                        }
                    }

                    actionRow
                }
                .padding(16)
            }
            .background(GameBoyPalette.lightest.ignoresSafeArea())
            .navigationTitle("지도 팩")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var statusLine: String {
        let previewSupport = pack.archiveFormat == .mbtiles ? "watch 프리뷰 지원" : "raster 프리뷰 지원"
        return "\(previewSupport) · \(isSelected ? "현재 사용 중" : "대기 중")"
    }

    private var metricRow: some View {
        HStack(spacing: 10) {
            RunimalMetricTile(icon: "shippingbox.fill", title: "파일", value: pack.archiveFormat.rawValue.uppercased(), accent: GameBoyPalette.mediumDark)
            RunimalMetricTile(icon: "memorychip.fill", title: "용량", value: byteLabel(pack.byteCount), accent: readinessColor)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            actionButton(isSelected ? "사용 중" : "선택", fill: isSelected ? GameBoyPalette.mediumDark : GameBoyPalette.lightest, foreground: isSelected ? GameBoyPalette.lightest : GameBoyPalette.darkest, action: onSelect)
            actionButton("파일", fill: GameBoyPalette.mediumLight, foreground: GameBoyPalette.darkest, action: onImportTiles)
            actionButton("전송", fill: GameBoyPalette.mediumLight, foreground: GameBoyPalette.darkest, action: onSend)
            actionButton("삭제", fill: .red, foreground: .white, action: onDelete)
        }
    }

    private func actionButton(_ title: String, fill: Color, foreground: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.monospaced().weight(.black))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
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

    private func detailLine(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.caption.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.mediumDark)
                .frame(width: 58, alignment: .leading)
            Text(value)
                .font(.caption.monospaced())
                .foregroundStyle(GameBoyPalette.darkest)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func byteLabel(_ bytes: Int64) -> String {
        if bytes >= 1_000_000 {
            return String(format: "%.1fMB", Double(bytes) / 1_000_000)
        }
        if bytes >= 1_000 {
            return String(format: "%.0fKB", Double(bytes) / 1_000)
        }
        return "\(bytes)B"
    }

    private func format(_ value: Double) -> String {
        String(format: "%.5f", value)
    }

    private func timeLabel(_ value: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: value)
    }
}
