import RunimalCore
import SwiftUI

struct PhoneSignedCloudPanel: View {
    let items: [CloudValidationState]

    var body: some View {
        GameSurface(title: "Signed Cloud Check") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.title)
                                .foregroundStyle(.white)
                            Spacer()
                            TraitChip(label: item.success ? "OK" : "CHECK", accent: item.success ? .green.opacity(0.72) : .orange.opacity(0.72))
                        }
                        Text(item.detail)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }
            }
        }
    }
}
