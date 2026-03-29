import Observation
import RunimalCore

@MainActor
@Observable
final class WatchOfflineMapPackCatalog {
    var packs: [OfflineMapPackSummary] = []
    var selectedPackID: String?

    func replace(with packs: [OfflineMapPackSummary], selectedPackID: String?) {
        self.packs = packs
        self.selectedPackID = selectedPackID
    }
}
