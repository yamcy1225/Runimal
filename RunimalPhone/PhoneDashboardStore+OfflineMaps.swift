import Foundation
import RunimalCore
import CoreLocation

extension PhoneDashboardStore {
    func createOfflineMapPackNearCurrentLocation(radiusKilometers: Double = 6, minZoom: Int = 12, maxZoom: Int = 16) {
        currentLocation.requestCurrentLocation { [weak self] location in
            guard let self else { return }
            guard let location else {
                self.telemetry.log("offline_map_pack_current_location_failed", detail: self.currentLocation.lastError ?? "unknown")
                return
            }

            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            let latDelta = radiusKilometers / 111.0
            let lonDivider = max(cos(latitude * .pi / 180.0), 0.2)
            let lonDelta = radiusKilometers / (111.0 * lonDivider)
            let estimatedTiles = max((maxZoom - minZoom + 1) * 180, 360)

            let pack = OfflineMapPackSummary(
                title: "현재 위치",
                sourceLabel: "OpenStreetMap (self-built)",
                licenseLabel: "ODbL",
                attributionText: "© OpenStreetMap contributors",
                boundingBox: OfflineMapBoundingBox(
                    minLatitude: latitude - latDelta,
                    minLongitude: longitude - lonDelta,
                    maxLatitude: latitude + latDelta,
                    maxLongitude: longitude + lonDelta
                ),
                minZoom: minZoom,
                maxZoom: maxZoom,
                tileCount: estimatedTiles,
                byteCount: Int64(estimatedTiles) * 32_000
            )

            self.registerOfflineMapPack(pack)
            self.telemetry.log("offline_map_pack_created_current_location", detail: "\(latitude),\(longitude)")
        }
    }

    func sendOfflineMapPackFiles(id: String) {
        let urls = offlineMaps.payloadURLs(for: id)
        connectivity.queueOfflineMapPackFiles(packID: id, urls: urls)
    }

    func renameOfflineMapPack(id: String, title: String) {
        offlineMaps.renamePack(id: id, title: title)
        connectivity.pushOfflineMapPackCatalog(offlineMaps.packs)
        connectivity.pushSelectedOfflineMapPackID(offlineMaps.selectedPackID)
        sendOfflineMapPackFiles(id: id)
        telemetry.log("offline_map_pack_renamed", detail: "\(id):\(title)")
    }

    func importOfflineMapPackTiles(from url: URL, for id: String) {
        do {
            try offlineMaps.importTileArchive(from: url, into: id)
            connectivity.pushOfflineMapPackCatalog(offlineMaps.packs)
            connectivity.pushSelectedOfflineMapPackID(offlineMaps.selectedPackID)
            sendOfflineMapPackFiles(id: id)
            telemetry.log("offline_map_pack_tiles_imported", detail: id)
        } catch {
            offlineMaps.markImportFailed(error.localizedDescription)
            telemetry.log("offline_map_pack_tiles_import_failed", detail: error.localizedDescription)
        }
    }

    func deleteOfflineMapPack(id: String) {
        offlineMaps.deletePack(id: id)
        connectivity.pushOfflineMapPackCatalog(offlineMaps.packs)
        connectivity.pushSelectedOfflineMapPackID(offlineMaps.selectedPackID)
        telemetry.log("offline_map_pack_deleted", detail: id)
    }
}
