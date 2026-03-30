import RunimalCore
import SwiftUI

struct PhoneOfflineMapPackPanel: View {
    let packs: [OfflineMapPackSummary]
    let watchPacks: [OfflineMapPackSummary]
    let watchStoredPackIDs: Set<String>
    let transferStatus: [String: OfflineMapPackTransferStatus]
    let selectedPackID: String?
    let importStatusLabel: String
    let lastImportError: String?
    let locationStatusLabel: String
    let locationError: String?
    let accent: Color
    let onCreatePack: (OfflineMapPackSummary) -> Void
    let onCreateCurrentLocationPack: () -> Void
    let onSelectPack: (String) -> Void
    let onImportTiles: (String) -> Void
    let onSendPack: (String) -> Void
    let onRenamePack: (String, String) -> Void
    let onDeletePack: (String) -> Void

    @State private var isPresentingCreateSheet = false
    @State private var editingPack: OfflineMapPackSummary?
    @State private var inspectingPack: OfflineMapPackSummary?
    @State private var draftTitle = ""

    private var transferredCount: Int {
        let watchIDs = Set(watchPacks.map(\.id))
        return packs.filter { watchIDs.contains($0.id) }.count
    }

    private var pendingCount: Int {
        max(packs.count - transferredCount, 0)
    }

    private var healthyPackCount: Int {
        packs.filter { $0.tilesReady && $0.byteCount > 0 }.count
    }

    private var attentionPackCount: Int {
        packs.filter { $0.manifestReady && (!$0.tilesReady || $0.byteCount <= 0) }.count
    }

    var body: some View {
        GameSurface(title: "오프라인 지도", accent: accent, eyebrow: "팩 관리") {
            VStack(alignment: .leading, spacing: 12) {
                Text("iPhone에서 팩을 등록하면 watch 카탈로그로 같은 메타데이터를 넘깁니다.")
                    .font(.footnote.monospaced())
                    .foregroundStyle(GameBoyPalette.mediumDark)

                statusPill(
                    title: "MBTiles",
                    value: importStatusLabel,
                    accent: lastImportError == nil ? GameBoyPalette.mediumDark : .red
                )

                statusPill(
                    title: "현재 위치",
                    value: locationStatusLabel,
                    accent: locationError == nil ? GameBoyPalette.mediumDark : .red
                )

                if let lastImportError {
                    Text(lastImportError)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.red)
                }

                if let locationError {
                    Text(locationError)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.red)
                }

                HStack(spacing: 10) {
                    RunimalMetricTile(icon: "square.stack.3d.down.right.fill", title: "iPhone", value: "\(packs.count)개", accent: accent)
                    RunimalMetricTile(icon: "applewatch.watchface", title: "Watch", value: "\(watchPacks.count)개", accent: .cyan)
                }

                HStack(spacing: 10) {
                    statusPill(title: "전달됨", value: "\(transferredCount)개", accent: .green)
                    statusPill(title: "대기", value: "\(pendingCount)개", accent: .orange)
                }

                HStack(spacing: 10) {
                    statusPill(title: "정상", value: "\(healthyPackCount)개", accent: .green)
                    statusPill(title: "주의", value: "\(attentionPackCount)개", accent: attentionPackCount == 0 ? GameBoyPalette.mediumDark : .red)
                }

                if let latestPack = packs.first {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("최근 팩")
                            .font(.caption.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.mediumDark)
                        Text(latestPack.title)
                            .font(.headline.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)
                        Text("Z\(latestPack.minZoom)-\(latestPack.maxZoom) · 타일 \(latestPack.tileCount)개 · \(byteLabel(latestPack.byteCount))")
                            .font(.footnote.monospaced())
                            .foregroundStyle(GameBoyPalette.mediumDark)
                        Text("\(latestPack.sourceLabel) · \(latestPack.licenseLabel)")
                            .font(.caption2.monospaced())
                            .foregroundStyle(GameBoyPalette.mediumDark)
                        Text(archiveDetailLabel(for: latestPack))
                            .font(.caption2.monospaced())
                            .foregroundStyle(GameBoyPalette.mediumDark)
                        Text(packReadinessLabel(for: latestPack))
                            .font(.caption2.monospaced().weight(.black))
                            .foregroundStyle(readinessColor(for: latestPack))
                    }
                }

                if packs.isEmpty == false {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("현재 사용 팩")
                            .font(.caption.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.mediumDark)

                        ForEach(Array(packs.prefix(4))) { pack in
                            Button {
                                onSelectPack(pack.id)
                            } label: {
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(pack.title)
                                            .font(.caption.monospaced().weight(.black))
                                            .foregroundStyle(GameBoyPalette.darkest)
                                        Text("Z\(pack.minZoom)-\(pack.maxZoom) · 타일 \(pack.tileCount)")
                                            .font(.caption2.monospaced())
                                            .foregroundStyle(GameBoyPalette.mediumDark)
                                        Text("\(pack.sourceLabel) · \(pack.licenseLabel)")
                                            .font(.caption2.monospaced())
                                            .foregroundStyle(GameBoyPalette.mediumDark)
                                        Text(archiveDetailLabel(for: pack))
                                            .font(.caption2.monospaced())
                                            .foregroundStyle(GameBoyPalette.mediumDark)
                                        Text(packReadinessLabel(for: pack))
                                            .font(.caption2.monospaced().weight(.black))
                                            .foregroundStyle(readinessColor(for: pack))
                                        Text(transferStatusLabel(for: pack))
                                            .font(.caption2.monospaced())
                                            .foregroundStyle(GameBoyPalette.mediumDark)
                                    }

                                    Spacer(minLength: 0)

                                    Text(selectedPackID == pack.id ? "사용 중" : "선택")
                                        .font(.caption2.monospaced().weight(.black))
                                        .foregroundStyle(selectedPackID == pack.id ? GameBoyPalette.lightest : GameBoyPalette.darkest)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(selectedPackID == pack.id ? GameBoyPalette.mediumDark : GameBoyPalette.lightest)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                        .stroke(GameBoyPalette.darkest, lineWidth: 2)
                                                )
                                        )
                                }
                                .padding(.horizontal, 10)
                                .padding(.top, 9)
                                .padding(.bottom, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(GameBoyPalette.lightest.opacity(0.88))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(selectedPackID == pack.id ? accent : GameBoyPalette.darkest, lineWidth: 2)
                                        )
                                )
                                .overlay(alignment: .bottomTrailing) {
                                    HStack(spacing: 6) {
                                        compactActionButton(title: "상세", accent: accent) {
                                            inspectingPack = pack
                                        }
                                        compactActionButton(title: "이름", accent: GameBoyPalette.mediumDark) {
                                            editingPack = pack
                                            draftTitle = pack.title
                                        }
                                        compactActionButton(title: "파일", accent: .blue) {
                                            onImportTiles(pack.id)
                                        }
                                        compactActionButton(title: "전송", accent: .green) {
                                            onSendPack(pack.id)
                                        }
                                        compactActionButton(title: "삭제", accent: .red) {
                                            onDeletePack(pack.id)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.bottom, 8)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        onCreateCurrentLocationPack()
                    } label: {
                        Text("현재 위치 팩")
                            .font(.caption.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(GameBoyPalette.lightest)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(GameBoyPalette.darkest, lineWidth: 2)
                                    )
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        isPresentingCreateSheet = true
                    } label: {
                        Text("지도 팩 만들기")
                            .font(.caption.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.lightest)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(GameBoyPalette.mediumDark)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(GameBoyPalette.darkest, lineWidth: 2)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $isPresentingCreateSheet) {
            PhoneOfflineMapPackSheet { pack in
                onCreatePack(pack)
            }
        }
        .sheet(item: $inspectingPack) { pack in
            PhoneOfflineMapPackDetailSheet(
                pack: pack,
                isSelected: selectedPackID == pack.id,
                isStoredOnWatch: watchStoredPackIDs.contains(pack.id),
                isCatalogDelivered: watchPacks.contains(where: { $0.id == pack.id }),
                transferStatusLabel: transferStatusLabel(for: pack),
                readinessLabel: packReadinessLabel(for: pack),
                readinessColor: readinessColor(for: pack),
                queuedAt: transferStatus[pack.id]?.lastQueuedAt,
                completedAt: transferStatus[pack.id]?.lastCompletedAt,
                transferFailure: transferStatus[pack.id]?.lastError,
                onSelect: {
                    onSelectPack(pack.id)
                    inspectingPack = nil
                },
                onImportTiles: {
                    onImportTiles(pack.id)
                },
                onSend: {
                    onSendPack(pack.id)
                },
                onDelete: {
                    onDeletePack(pack.id)
                    inspectingPack = nil
                }
            )
        }
        .sheet(item: $editingPack) { pack in
            NavigationStack {
                Form {
                    Section("팩 이름") {
                        TextField("팩 이름", text: $draftTitle)
                            .textInputAutocapitalization(.words)
                    }

                    Section("현재 팩") {
                        Text(pack.title)
                            .font(.body.monospaced())
                        Text("Z\(pack.minZoom)-\(pack.maxZoom) · 타일 \(pack.tileCount)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("이름 변경")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("닫기") {
                            editingPack = nil
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("저장") {
                            onRenamePack(pack.id, draftTitle)
                            editingPack = nil
                        }
                    }
                }
            }
        }
    }

    private func compactActionButton(title: String, accent: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption2.monospaced().weight(.black))
                .foregroundStyle(title == "삭제" ? Color.white : GameBoyPalette.darkest)
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(title == "삭제" ? accent : (title == "파일" ? GameBoyPalette.mediumLight.opacity(0.9) : GameBoyPalette.mediumLight))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(GameBoyPalette.darkest, lineWidth: 2)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func packReadinessLabel(for pack: OfflineMapPackSummary) -> String {
        let formatLabel = pack.archiveFormat == .pmtiles ? "PMTiles" : "MBTiles"
        if pack.tilesReady, pack.byteCount <= 0 { return "\(formatLabel) 파일 비어 있음" }
        if watchStoredPackIDs.contains(pack.id) { return "watch 저장 완료 · \(formatLabel)" }
        if watchPacks.contains(where: { $0.id == pack.id }) { return "카탈로그 전달됨 · \(formatLabel)" }
        if pack.tilesReady { return "\(formatLabel) 연결됨" }
        if pack.manifestReady { return "manifest만 준비됨" }
        return "로컬 저장 준비 전"
    }

    private func readinessColor(for pack: OfflineMapPackSummary) -> Color {
        if pack.tilesReady, pack.byteCount <= 0 { return .red }
        if watchStoredPackIDs.contains(pack.id) { return .green }
        if watchPacks.contains(where: { $0.id == pack.id }) { return .cyan }
        if pack.tilesReady { return .green }
        if pack.manifestReady { return .orange }
        return .red
    }

    private func transferStatusLabel(for pack: OfflineMapPackSummary) -> String {
        let formatLabel = pack.archiveFormat == .pmtiles ? "PMTiles" : "MBTiles"
        if pack.tilesReady, pack.byteCount <= 0 {
            return "\(formatLabel) 파일 다시 연결 필요"
        }
        guard let status = transferStatus[pack.id] else {
            return pack.tilesReady ? "\(formatLabel) 전송 대기" : "\(formatLabel) 파일 연결 필요"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        switch status.phase {
        case .idle:
            return pack.tilesReady ? "\(formatLabel) 전송 대기" : "\(formatLabel) 파일 연결 필요"
        case .sending:
            let time = status.lastQueuedAt.map(formatter.string(from:)) ?? "--:--"
            let progress = max(status.completedFileCount, 0)
            let total = max(status.expectedFileCount, 0)
            return total > 0 ? "\(formatLabel) 전송 중 \(progress)/\(total) · \(time)" : "\(formatLabel) 전송 중 · \(time)"
        case .storedOnWatch:
            let time = status.lastCompletedAt.map(formatter.string(from:)) ?? "--:--"
            return "watch 저장 완료 · \(time)"
        case .failed:
            if let lastError = status.lastError, lastError.isEmpty == false {
                return "\(formatLabel) 전송 실패 · \(lastError)"
            }
            return "\(formatLabel) 전송 실패 · 재시도 필요"
        }
    }

    private func archiveDetailLabel(for pack: OfflineMapPackSummary) -> String {
        let formatLabel = pack.archiveFormat == .pmtiles ? "PMTiles" : "MBTiles"
        let previewLabel: String
        switch pack.archiveFormat {
        case .mbtiles:
            previewLabel = "watch 프리뷰 지원"
        case .pmtiles:
            previewLabel = "raster 프리뷰 지원"
        }
        return "\(formatLabel) · \(pack.archiveFilename) · \(byteLabel(pack.byteCount)) · \(previewLabel)"
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

    private func statusPill(title: String, value: String, accent: Color) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption2.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.mediumDark)
            Text(value)
                .font(.caption.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.darkest)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(GameBoyPalette.lightest)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(accent.opacity(0.88), lineWidth: 2)
                )
        )
    }
}

private struct PhoneOfflineMapPackSheet: View {
    private enum Preset: String, CaseIterable, Identifiable {
        case seoulCore
        case hanRiver
        case busanBeach
        case gapyeongTrail

        var id: String { rawValue }

        var title: String {
            switch self {
            case .seoulCore: return "서울 코어"
            case .hanRiver: return "한강 러닝"
            case .busanBeach: return "부산 해안"
            case .gapyeongTrail: return "가평 러닝"
            }
        }

        var boundingBox: OfflineMapBoundingBox {
            switch self {
            case .seoulCore:
                return .init(minLatitude: 37.50, minLongitude: 126.92, maxLatitude: 37.60, maxLongitude: 127.08)
            case .hanRiver:
                return .init(minLatitude: 37.49, minLongitude: 126.93, maxLatitude: 37.56, maxLongitude: 127.10)
            case .busanBeach:
                return .init(minLatitude: 35.12, minLongitude: 129.10, maxLatitude: 35.18, maxLongitude: 129.18)
            case .gapyeongTrail:
                return .init(minLatitude: 37.70, minLongitude: 127.35, maxLatitude: 37.92, maxLongitude: 127.62)
            }
        }

        var tileCount: Int {
            switch self {
            case .seoulCore: return 640
            case .hanRiver: return 520
            case .busanBeach: return 410
            case .gapyeongTrail: return 720
            }
        }

        var byteCount: Int64 {
            Int64(tileCount) * 32_000
        }
    }

    let onCreate: (OfflineMapPackSummary) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var minZoom = 14
    @State private var maxZoom = 17
    @State private var selectedPreset: Preset = .seoulCore

    var body: some View {
        NavigationStack {
            Form {
                Section("프리셋") {
                    Picker("지역", selection: $selectedPreset) {
                        ForEach(Preset.allCases) { preset in
                            Text(preset.title).tag(preset)
                        }
                    }
                    .onChange(of: selectedPreset) { _, preset in
                        if title.isEmpty {
                            title = preset.title
                        }
                    }
                }

                Section("기본 정보") {
                    TextField("팩 이름", text: $title)
                    Stepper("최소 줌 \(minZoom)", value: $minZoom, in: 12...17)
                    Stepper("최대 줌 \(maxZoom)", value: $maxZoom, in: minZoom...19)
                }
            }
            .navigationTitle("지도 팩 만들기")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        let pack = OfflineMapPackSummary(
                            title: title.isEmpty ? selectedPreset.title : title,
                            sourceLabel: "OpenStreetMap (self-built)",
                            licenseLabel: "ODbL",
                            attributionText: "© OpenStreetMap contributors",
                            boundingBox: selectedPreset.boundingBox,
                            minZoom: minZoom,
                            maxZoom: maxZoom,
                            tileCount: selectedPreset.tileCount,
                            byteCount: selectedPreset.byteCount
                        )
                        onCreate(pack)
                        dismiss()
                    }
                }
            }
            .onAppear {
                if title.isEmpty {
                    title = selectedPreset.title
                }
            }
        }
    }
}
