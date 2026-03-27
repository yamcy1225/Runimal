import SwiftUI

struct PhoneCloudValidationPanel: View {
    let headline: String

    var body: some View {
        GameSurface(title: "Cloud Validation") {
            Text(headline)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
        }
    }
}
