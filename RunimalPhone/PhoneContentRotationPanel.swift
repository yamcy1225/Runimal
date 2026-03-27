import RunimalCore
import SwiftUI

struct PhoneContentRotationPanel: View {
    let entries: [ContentRotationEntry]

    var body: some View {
        GameSurface(title: "Field Rotation") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entry.title)
                                .foregroundStyle(.white)
                            Spacer()
                            TraitChip(label: entry.reward, accent: .mint.opacity(0.72))
                        }
                        Text(entry.detail)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }
            }
        }
    }
}
