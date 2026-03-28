import RunimalCore
import SwiftUI

struct HatchFragmentBurstView: View {
    let shell: EggShellType
    let active: Bool
    let completed: Bool
    var pixelSize: CGFloat = 10

    @State private var drift = false

    var body: some View {
        ZStack {
            ForEach(Array(fragmentLayout.enumerated()), id: \.offset) { _, fragment in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(fragment.color)
                    .frame(width: fragment.size.width, height: fragment.size.height)
                    .position(fragment.origin)
                    .offset(x: active ? fragment.travel.width : 0, y: active ? fragment.travel.height : 0)
                    .rotationEffect(.degrees(active ? fragment.rotation : 0))
                    .opacity(fragmentOpacity)
                    .scaleEffect(completed ? 0.42 : (active ? 1.08 : 0.7))
            }
        }
        .frame(width: 280, height: 320)
        .allowsHitTesting(false)
        .onAppear {
            drift = true
        }
        .animation(.easeInOut(duration: 0.32).repeatForever(autoreverses: true), value: drift)
    }

    private var fragmentOpacity: Double {
        if completed { return 0 }
        return active ? 0.92 : 0
    }

    private var fragmentLayout: [FragmentNode] {
        let accent = shell.accentColor
        let particle = shell.particleColor
        let tint = shell.shellTint

        return [
            FragmentNode(origin: CGPoint(x: 122, y: 82), travel: CGSize(width: -48, height: -36), rotation: -18, size: CGSize(width: pixelSize * 1.4, height: pixelSize * 0.9), color: particle),
            FragmentNode(origin: CGPoint(x: 156, y: 76), travel: CGSize(width: 44, height: -42), rotation: 22, size: CGSize(width: pixelSize * 1.2, height: pixelSize * 1.0), color: accent),
            FragmentNode(origin: CGPoint(x: 102, y: 134), travel: CGSize(width: -62, height: -12), rotation: -26, size: CGSize(width: pixelSize * 1.0, height: pixelSize * 0.8), color: tint),
            FragmentNode(origin: CGPoint(x: 182, y: 138), travel: CGSize(width: 60, height: -18), rotation: 30, size: CGSize(width: pixelSize * 1.1, height: pixelSize * 0.9), color: particle),
            FragmentNode(origin: CGPoint(x: 108, y: 184), travel: CGSize(width: -58, height: 24), rotation: -30, size: CGSize(width: pixelSize * 1.5, height: pixelSize * 0.9), color: accent),
            FragmentNode(origin: CGPoint(x: 180, y: 188), travel: CGSize(width: 62, height: 26), rotation: 32, size: CGSize(width: pixelSize * 1.5, height: pixelSize * 0.9), color: tint),
            FragmentNode(origin: CGPoint(x: 136, y: 222), travel: CGSize(width: -12, height: 58), rotation: -14, size: CGSize(width: pixelSize * 0.9, height: pixelSize * 1.4), color: particle),
            FragmentNode(origin: CGPoint(x: 160, y: 228), travel: CGSize(width: 18, height: 60), rotation: 16, size: CGSize(width: pixelSize * 0.9, height: pixelSize * 1.5), color: accent)
        ]
    }
}

private struct FragmentNode {
    let origin: CGPoint
    let travel: CGSize
    let rotation: Double
    let size: CGSize
    let color: Color
}
