import SwiftUI

struct HatchBurstView: View {
    let accent: Color
    var scale: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(accent.opacity(0.38), lineWidth: 2)
                .frame(width: 86 * scale, height: 86 * scale)

            Circle()
                .stroke(accent.opacity(0.24), style: StrokeStyle(lineWidth: 5, dash: [4, 6]))
                .frame(width: 112 * scale, height: 112 * scale)

            Circle()
                .fill(accent.opacity(0.12))
                .frame(width: 64 * scale, height: 64 * scale)
                .blur(radius: 10)
        }
    }
}
