import RunimalCore
import SwiftUI

struct RoutePreviewShape: Shape {
    let points: [RoutePoint]

    func path(in rect: CGRect) -> Path {
        guard points.count > 1 else { return Path() }

        let latitudes = points.map(\.latitude)
        let longitudes = points.map(\.longitude)

        guard let minLat = latitudes.min(),
              let maxLat = latitudes.max(),
              let minLon = longitudes.min(),
              let maxLon = longitudes.max() else {
            return Path()
        }

        let latSpan = max(maxLat - minLat, 0.0001)
        let lonSpan = max(maxLon - minLon, 0.0001)
        let insetRect = rect.insetBy(dx: 12, dy: 10)

        func normalizedPoint(_ point: RoutePoint) -> CGPoint {
            let xRatio = (point.longitude - minLon) / lonSpan
            let yRatio = (point.latitude - minLat) / latSpan

            return CGPoint(
                x: insetRect.minX + insetRect.width * xRatio,
                y: insetRect.maxY - insetRect.height * yRatio
            )
        }

        var path = Path()
        path.move(to: normalizedPoint(points[0]))

        for point in points.dropFirst() {
            path.addLine(to: normalizedPoint(point))
        }

        return path
    }
}
