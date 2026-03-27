import RunimalCore
import SwiftUI

struct MacDeviceQAPanel: View {
    let checklist: [DeviceQACheckItem]

    var body: some View {
        GameSurface(title: "Device QA Checklist") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(checklist) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .foregroundStyle(.white)
                        Text(item.detail)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }
            }
        }
    }
}
