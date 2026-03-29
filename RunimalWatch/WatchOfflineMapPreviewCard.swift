import RunimalCore
import SwiftUI

struct WatchOfflineMapPreviewCard: View {
    let selectedPack: OfflineMapPackSummary?
    let isStoredLocally: Bool
    let storage: WatchOfflineMapPackStorage
    let route: [RoutePoint]
    let accent: Color

    @State private var tileReader = WatchMBTilesTileReader()
    @State private var zoomLevel: Int?
    @State private var followsHeading = false
    @State private var autoZoomEnabled = true

    var body: some View {
        GameSurface(title: "지도", accent: accent, compact: true) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(selectedPack?.title ?? "팩 없음")
                        .font(.caption.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.darkest)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    if isStoredLocally {
                        statusBadge("LOCAL", fill: GameBoyPalette.mediumLight)
                    }
                    if route.isEmpty == false {
                        statusBadge("LIVE", fill: GameBoyPalette.mediumDark, foreground: GameBoyPalette.lightest)
                    }
                }

                if let selectedPack {
                    HStack(spacing: 6) {
                        mapButton(followsHeading ? "HDG" : "N") {
                            followsHeading.toggle()
                        }

                        mapButton("−") {
                            autoZoomEnabled = false
                            let currentZoom = zoomLevel ?? effectiveZoomLevel
                            self.zoomLevel = max(currentZoom - 1, selectedPack.minZoom)
                        }

                        mapButton(autoZoomEnabled ? "AUTO" : "Z\(effectiveZoomLevel)") {
                            autoZoomEnabled.toggle()
                            if autoZoomEnabled {
                                zoomLevel = nil
                            } else {
                                zoomLevel = effectiveZoomLevel
                            }
                        }

                        mapButton("+") {
                            autoZoomEnabled = false
                            let currentZoom = zoomLevel ?? effectiveZoomLevel
                            self.zoomLevel = min(currentZoom + 1, selectedPack.maxZoom)
                        }
                    }
                }

                GeometryReader { proxy in
                    let side = min(proxy.size.width, proxy.size.height)
                    let frame = CGRect(origin: .zero, size: CGSize(width: side, height: side))

                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(GameBoyPalette.lightest.opacity(0.92))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(GameBoyPalette.darkest, lineWidth: 2)
                            )

                        ZStack {
                            if let previewImage = tileReader.previewImage {
                                Image(uiImage: previewImage)
                                    .resizable()
                                    .interpolation(.none)
                                    .scaledToFill()
                                    .frame(width: side, height: side)
                                    .clipped()
                                    .overlay {
                                        Rectangle()
                                            .fill(GameBoyPalette.lightest.opacity(0.18))
                                    }
                            }

                            GameBoyLCDOverlay()
                                .opacity(0.34)

                            mapGrid

                            if let domain = drawingDomain {
                                Path { path in
                                    guard let first = normalizedPoint(for: displayRoute.first, in: domain, frame: frame) else { return }
                                    path.move(to: first)
                                    for point in displayRoute.dropFirst() {
                                        guard let next = normalizedPoint(for: point, in: domain, frame: frame) else { continue }
                                        path.addLine(to: next)
                                    }
                                }
                                .stroke(accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                                if let last = normalizedPoint(for: displayRoute.last, in: domain, frame: frame) {
                                    mapHeadingMarker
                                        .rotationEffect(.degrees(followsHeading ? 0 : routeHeadingDegrees))
                                        .position(last)
                                }
                            } else {
                                Text(isStoredLocally ? tileReader.statusLabel : "팩 필요")
                                    .font(.caption2.monospaced().weight(.black))
                                    .foregroundStyle(GameBoyPalette.mediumDark)
                            }
                        }
                        .rotationEffect(.degrees(followsHeading ? -routeHeadingDegrees : 0))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .frame(width: side, height: side)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                .frame(height: 108)

                if let selectedPack {
                    Text("Z\(selectedPack.minZoom)-\(selectedPack.maxZoom) · 타일 \(selectedPack.tileCount)")
                        .font(.caption2.monospaced())
                        .foregroundStyle(GameBoyPalette.mediumDark)
                } else {
                    Text("iPhone에서 지도 팩을 선택하면 이 필드가 활성화됩니다.")
                        .font(.caption2.monospaced())
                        .foregroundStyle(GameBoyPalette.mediumDark)
                }
            }
        }
        .task(id: tileReloadToken) {
            syncZoomLevel()
            tileReader.loadPreviewTile(
                for: selectedPack,
                storage: storage,
                centerPoint: cameraCenterPoint,
                zoomOverride: autoZoomEnabled ? nil : zoomLevel
            )
        }
    }

    private var tileReloadToken: String {
        let centerToken = cameraCenterPoint.map { "\($0.latitude)-\($0.longitude)" } ?? "none"
        return "\(selectedPack?.id ?? "none")-\(isStoredLocally)-\(centerToken)-\(effectiveZoomLevel)-\(autoZoomEnabled)-\(followsHeading)"
    }

    private var effectiveZoomLevel: Int {
        if autoZoomEnabled {
            return autoZoomLevel
        }
        if let zoomLevel { return zoomLevel }
        return autoZoomLevel
    }

    private var displayRoute: [RoutePoint] {
        guard route.count >= 3 else { return route }

        return route.enumerated().map { index, point in
            let start = max(index - 1, 0)
            let end = min(index + 1, route.count - 1)
            let window = route[start...end]
            let latitude = window.map(\.latitude).reduce(0, +) / Double(window.count)
            let longitude = window.map(\.longitude).reduce(0, +) / Double(window.count)
            let altitude = window.map(\.altitude).reduce(0, +) / Double(window.count)
            return RoutePoint(
                latitude: latitude,
                longitude: longitude,
                altitude: altitude,
                timestamp: point.timestamp
            )
        }
    }

    private var cameraCenterPoint: RoutePoint? {
        let tail = Array(displayRoute.suffix(5))
        guard tail.isEmpty == false else { return route.last }
        let latitude = tail.map(\.latitude).reduce(0, +) / Double(tail.count)
        let longitude = tail.map(\.longitude).reduce(0, +) / Double(tail.count)
        let altitude = tail.map(\.altitude).reduce(0, +) / Double(tail.count)
        return RoutePoint(
            latitude: latitude,
            longitude: longitude,
            altitude: altitude,
            timestamp: tail.last?.timestamp ?? Date()
        )
    }

    private var autoZoomLevel: Int {
        guard let selectedPack else { return 0 }
        guard displayRoute.count >= 2 else { return selectedPack.maxZoom }

        let latitudes = displayRoute.map(\.latitude)
        let longitudes = displayRoute.map(\.longitude)
        guard let minLatitude = latitudes.min(),
              let maxLatitude = latitudes.max(),
              let minLongitude = longitudes.min(),
              let maxLongitude = longitudes.max() else {
            return selectedPack.maxZoom
        }

        let routeLatitudeSpan = max(maxLatitude - minLatitude, 0.00005)
        let routeLongitudeSpan = max(maxLongitude - minLongitude, 0.00005)

        for zoom in stride(from: selectedPack.maxZoom, through: selectedPack.minZoom, by: -1) {
            guard let domain = tileWindowDomain(for: zoom) else { continue }
            let latitudeCapacity = max(domain.maxLatitude - domain.minLatitude, 0.00005)
            let longitudeCapacity = max(domain.maxLongitude - domain.minLongitude, 0.00005)
            if routeLatitudeSpan / latitudeCapacity <= 0.58,
               routeLongitudeSpan / longitudeCapacity <= 0.58 {
                return zoom
            }
        }

        return selectedPack.minZoom
    }

    private var drawingDomain: OfflineMapBoundingBox? {
        if let tileWindowDomain {
            return tileWindowDomain
        }

        if let selectedPack {
            return selectedPack.boundingBox
        }

        guard route.isEmpty == false else { return nil }
        let latitudes = route.map(\.latitude)
        let longitudes = route.map(\.longitude)
        guard let minLatitude = latitudes.min(),
              let maxLatitude = latitudes.max(),
              let minLongitude = longitudes.min(),
              let maxLongitude = longitudes.max() else { return nil }
        return OfflineMapBoundingBox(
            minLatitude: minLatitude,
            minLongitude: minLongitude,
            maxLatitude: maxLatitude,
            maxLongitude: maxLongitude
        )
    }

    private var tileWindowDomain: OfflineMapBoundingBox? {
        tileWindowDomain(for: effectiveZoomLevel)
    }

    private func tileWindowDomain(for zoomLevel: Int) -> OfflineMapBoundingBox? {
        guard let selectedPack else { return nil }

        let centerLatitude = cameraCenterPoint?.latitude
            ?? (selectedPack.boundingBox.minLatitude + selectedPack.boundingBox.maxLatitude) / 2
        let centerLongitude = cameraCenterPoint?.longitude
            ?? (selectedPack.boundingBox.minLongitude + selectedPack.boundingBox.maxLongitude) / 2

        let centerTile = tileXY(latitude: centerLatitude, longitude: centerLongitude, zoom: zoomLevel)
        let worldTileCount = 1 << zoomLevel
        let topTileY = centerTile.y - 1
        let bottomTileY = centerTile.y + 2
        guard topTileY >= 0, bottomTileY <= worldTileCount else {
            return selectedPack.boundingBox
        }

        let minLongitude = tileXToLongitude(centerTile.x - 1, zoom: zoomLevel)
        let maxLongitude = tileXToLongitude(centerTile.x + 2, zoom: zoomLevel)
        let maxLatitude = tileYToLatitude(centerTile.y - 1, zoom: zoomLevel)
        let minLatitude = tileYToLatitude(centerTile.y + 2, zoom: zoomLevel)

        return OfflineMapBoundingBox(
            minLatitude: minLatitude,
            minLongitude: minLongitude,
            maxLatitude: maxLatitude,
            maxLongitude: maxLongitude
        )
    }

    private var mapGrid: some View {
        Canvas { context, size in
            let spacing = max(size.width / 5, 12)
            var grid = Path()

            stride(from: spacing, to: size.width, by: spacing).forEach { x in
                grid.move(to: CGPoint(x: x, y: 0))
                grid.addLine(to: CGPoint(x: x, y: size.height))
            }

            stride(from: spacing, to: size.height, by: spacing).forEach { y in
                grid.move(to: CGPoint(x: 0, y: y))
                grid.addLine(to: CGPoint(x: size.width, y: y))
            }

            context.stroke(grid, with: .color(GameBoyPalette.mediumLight.opacity(0.7)), lineWidth: 1)
        }
    }

    private func normalizedPoint(
        for point: RoutePoint?,
        in domain: OfflineMapBoundingBox,
        frame: CGRect
    ) -> CGPoint? {
        guard let point else { return nil }
        let longitudeSpan = max(domain.maxLongitude - domain.minLongitude, 0.0001)
        let latitudeSpan = max(domain.maxLatitude - domain.minLatitude, 0.0001)

        let x = ((point.longitude - domain.minLongitude) / longitudeSpan) * frame.width
        let y = (1 - ((point.latitude - domain.minLatitude) / latitudeSpan)) * frame.height
        return CGPoint(x: x, y: y)
    }

    private var mapHeadingMarker: some View {
        ZStack {
            Circle()
                .fill(GameBoyPalette.lightest)
                .frame(width: 14, height: 14)
            TriangleMarker()
                .fill(GameBoyPalette.darkest)
                .frame(width: 10, height: 10)
                .rotationEffect(.degrees(routeHeadingDegrees))
        }
    }

    private var routeHeadingDegrees: Double {
        guard route.count >= 2 else { return 0 }
        let previous = route[route.count - 2]
        let current = route[route.count - 1]
        let deltaLongitude = current.longitude - previous.longitude
        let deltaLatitude = current.latitude - previous.latitude
        return atan2(deltaLongitude, deltaLatitude) * 180 / .pi
    }

    private func tileXY(latitude: Double, longitude: Double, zoom: Int) -> (x: Int, y: Int) {
        let lat = min(max(latitude, -85.05112878), 85.05112878)
        let lon = min(max(longitude, -180), 180)
        let scale = Double(1 << zoom)
        let x = Int(((lon + 180) / 360 * scale).rounded(.down))
        let latitudeRadians = lat * .pi / 180
        let mercator = log(tan(.pi / 4 + latitudeRadians / 2))
        let y = Int(((1 - mercator / .pi) / 2 * scale).rounded(.down))
        return (
            x: min(max(x, 0), Int(scale - 1)),
            y: min(max(y, 0), Int(scale - 1))
        )
    }

    private func tileXToLongitude(_ x: Int, zoom: Int) -> Double {
        let scale = Double(1 << zoom)
        return (Double(x) / scale) * 360 - 180
    }

    private func tileYToLatitude(_ y: Int, zoom: Int) -> Double {
        let scale = Double(1 << zoom)
        let mercator = .pi * (1 - 2 * Double(y) / scale)
        return atan(sinh(mercator)) * 180 / .pi
    }

    private func syncZoomLevel() {
        guard let selectedPack else {
            zoomLevel = nil
            return
        }
        if autoZoomEnabled {
            zoomLevel = nil
            return
        }
        if let zoomLevel {
            self.zoomLevel = min(max(zoomLevel, selectedPack.minZoom), selectedPack.maxZoom)
        } else {
            zoomLevel = autoZoomLevel
        }
    }

    private func statusBadge(_ text: String, fill: Color, foreground: Color = GameBoyPalette.darkest) -> some View {
        Text(text)
            .font(.caption2.monospaced().weight(.black))
            .foregroundStyle(foreground)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(fill)
            )
    }

    private func mapButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption2.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.lightest)
                .frame(minWidth: 24, minHeight: 20)
                .padding(.horizontal, title.count > 2 ? 5 : 0)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(GameBoyPalette.mediumDark)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct TriangleMarker: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY * 0.72))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
