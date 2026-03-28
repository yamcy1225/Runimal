import RunimalCore
import SwiftUI

struct HatchInterferenceBackdropView: View {
    let shell: EggShellType
    let phase: HatchBackdropPhase

    @State private var drift = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.04, blue: 0.07),
                    Color(red: 0.01, green: 0.02, blue: 0.04),
                    shell.accentColor.opacity(phase == .interference ? 0.10 : 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [shell.particleColor.opacity(phase == .complete ? 0.18 : 0.10), .clear],
                center: .center,
                startRadius: 30,
                endRadius: 320
            )

            scanGrid

            if phase == .interference {
                interferenceNoise
            }
        }
        .ignoresSafeArea()
        .onAppear {
            drift = true
        }
        .animation(.linear(duration: 0.2).repeatForever(autoreverses: true), value: drift)
    }

    private var scanGrid: some View {
        GeometryReader { geometry in
            Path { path in
                let size = geometry.size
                stride(from: 0.0, through: size.width, by: 24).forEach { x in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                stride(from: 0.0, through: size.height, by: 24).forEach { y in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
            }
            .stroke(.white.opacity(phase == .interference ? 0.13 : 0.06), lineWidth: 0.5)
            .offset(x: drift ? 2 : -2, y: drift ? -1 : 1)
        }
    }

    private var interferenceNoise: some View {
        ZStack {
            Rectangle()
                .fill(.white.opacity(0.08))
                .blendMode(.screen)

            VStack(spacing: 10) {
                ForEach(0..<18, id: \.self) { index in
                    Rectangle()
                        .fill(index.isMultiple(of: 2) ? .white.opacity(0.08) : .clear)
                        .frame(height: 6)
                        .offset(x: drift ? 4 : -4)
                }
            }
        }
        .ignoresSafeArea()
    }
}

enum HatchBackdropPhase {
    case idle
    case decoding
    case interference
    case complete
}
