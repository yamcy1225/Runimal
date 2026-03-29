import Foundation
import RunimalCore

extension PhoneDashboardStore {
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
            try offlineMaps.importMBTiles(from: url, into: id)
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
