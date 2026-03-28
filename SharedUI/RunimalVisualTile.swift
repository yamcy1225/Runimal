import SwiftUI

struct RunimalMetricTile: View {
    let icon: String
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(accent.opacity(0.16))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(.white)
            }

            Text(title.uppercased())
                .font(.caption2.weight(.black))
                .tracking(1.0)
                .foregroundStyle(.white.opacity(0.48))

            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

struct RunimalSignalBadge: View {
    let icon: String
    let label: String
    let accent: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.caption2.weight(.black))
            Text(label.uppercased())
                .font(.caption2.weight(.black))
                .tracking(0.8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(accent.opacity(0.14))
                .overlay(
                    Capsule()
                        .stroke(accent.opacity(0.32), lineWidth: 1)
                )
        )
        .foregroundStyle(.white.opacity(0.94))
    }
}
