import SwiftUI

struct RunimalMetricTile: View {
    let icon: String
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Rectangle()
                    .fill(GameBoyPalette.mediumLight)
                    .frame(width: 34, height: 34)
                    .overlay(
                        Rectangle()
                            .stroke(GameBoyPalette.darkest, lineWidth: 1)
                    )

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(GameBoyPalette.darkest)
            }

            Text(title.uppercased())
                .font(.caption2.monospaced().weight(.black))
                .tracking(0.9)
                .foregroundStyle(GameBoyPalette.mediumDark)

            Text(value)
                .font(.headline.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.darkest)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(GameBoyPalette.lightest)
                GameBoyLCDOverlay()
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(GameBoyPalette.darkest, lineWidth: 1.5)
        )
        .overlay(alignment: .topLeading) {
            Rectangle()
                .fill(accent.opacity(0.82))
                .frame(width: 16, height: 4)
                .padding(6)
        }
    }
}

struct RunimalSignalBadge: View {
    let icon: String
    let label: String
    let accent: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2.weight(.black))
            Text(label.uppercased())
                .font(.caption2.monospaced().weight(.black))
                .tracking(0.8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(GameBoyPalette.lightest)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(GameBoyPalette.darkest, lineWidth: 1)
                )
        )
        .foregroundStyle(GameBoyPalette.darkest)
        .overlay(alignment: .topLeading) {
            Rectangle()
                .fill(accent.opacity(0.78))
                .frame(width: 12, height: 3)
                .padding(4)
        }
    }
}
