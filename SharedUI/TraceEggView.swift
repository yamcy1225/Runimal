import SwiftUI

struct TraceEggView: View {
    let accent: Color
    var pixelSize: CGFloat = 10
    var cracked: Bool = false

    @State private var drifting = false
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accent.opacity(glowPulse ? 0.34 : 0.18), .clear],
                        center: .center,
                        startRadius: pixelSize,
                        endRadius: pixelSize * 5.8
                    )
                )
                .frame(width: 10.2 * pixelSize, height: 10.2 * pixelSize)

            Circle()
                .stroke(accent.opacity(0.28), style: StrokeStyle(lineWidth: max(1, pixelSize * 0.18), dash: [4, 5]))
                .frame(width: 9.1 * pixelSize, height: 9.1 * pixelSize)
                .rotationEffect(.degrees(drifting ? 8 : -8))

            pixelLayer(shellPixels, color: .white.opacity(0.92))
            pixelLayer(shellShadePixels, color: accent.opacity(0.55))
            pixelLayer(corePixels, color: accent.opacity(0.94), inset: pixelSize * 0.18)

            if cracked {
                pixelLayer(crackPixels, color: .black.opacity(0.68), inset: pixelSize * 0.25)
                pixelLayer(sparkPixels, color: .white.opacity(0.95), inset: pixelSize * 0.4)
            }
        }
        .frame(width: 10 * pixelSize, height: 10 * pixelSize)
        .offset(y: drifting ? -pixelSize * 0.28 : pixelSize * 0.12)
        .rotationEffect(.degrees(drifting ? 1.6 : -1.8))
        .shadow(color: accent.opacity(0.34), radius: 18, y: 12)
        .overlay(alignment: .bottom) {
            RoundedRectangle(cornerRadius: pixelSize)
                .fill(.black.opacity(0.24))
                .frame(width: 5.8 * pixelSize, height: pixelSize * 0.7)
                .blur(radius: 6)
                .offset(y: pixelSize * 1.7)
        }
        .onAppear {
            drifting = true
            glowPulse = true
        }
        .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: drifting)
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: glowPulse)
    }

    private func pixelLayer(_ pixels: [(Int, Int)], color: Color, inset: CGFloat = 0) -> some View {
        ForEach(Array(pixels.enumerated()), id: \.offset) { _, point in
            Rectangle()
                .fill(color)
                .frame(width: pixelSize - inset, height: pixelSize - inset)
                .position(
                    x: CGFloat(point.0) * pixelSize + pixelSize / 2,
                    y: CGFloat(point.1) * pixelSize + pixelSize / 2
                )
        }
    }

    private var shellPixels: [(Int, Int)] {
        [
            (4, 0), (5, 0),
            (3, 1), (4, 1), (5, 1), (6, 1),
            (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2),
            (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3),
            (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4),
            (2, 5), (3, 5), (4, 5), (5, 5), (6, 5), (7, 5),
            (3, 6), (4, 6), (5, 6), (6, 6),
            (4, 7), (5, 7)
        ]
    }

    private var shellShadePixels: [(Int, Int)] {
        [(3, 2), (6, 2), (2, 4), (7, 4), (3, 6), (6, 6)]
    }

    private var corePixels: [(Int, Int)] {
        [(4, 2), (5, 2), (4, 3), (5, 3), (4, 4), (5, 4)]
    }

    private var crackPixels: [(Int, Int)] {
        [(4, 1), (4, 2), (5, 3), (4, 4), (5, 5), (5, 6)]
    }

    private var sparkPixels: [(Int, Int)] {
        [(2, 1), (7, 1), (1, 4), (8, 4)]
    }
}
