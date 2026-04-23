import SwiftUI

struct WatchViewportProfile: Equatable {
    enum Kind: Equatable {
        case ultra49
        case series46
        case compact
    }

    let kind: Kind
    let captureCanvasSize: CGSize
    let horizontalGuard: CGFloat
    let topGuard: CGFloat
    let bottomGuard: CGFloat
    let runtimeInsets: EdgeInsets
    let runtimeOffset: CGSize

    static func resolve(
        containerSize: CGSize,
        safeAreaInsets: EdgeInsets = .init(),
        captureDeviceName: String? = ProcessInfo.processInfo.environment["RUNIMAL_WATCH_CAPTURE_DEVICE_NAME"]
    ) -> WatchViewportProfile {
        let maxDimension = max(containerSize.width, containerSize.height)
        let normalizedDeviceName = captureDeviceName?.lowercased() ?? ""

        if normalizedDeviceName.contains("ultra") || maxDimension >= 254 {
            return WatchViewportProfile(
                kind: .ultra49,
                captureCanvasSize: CGSize(width: 211, height: 257),
                horizontalGuard: max(9, safeAreaInsets.leading, safeAreaInsets.trailing),
                topGuard: max(10, safeAreaInsets.top + 4),
                bottomGuard: max(15, safeAreaInsets.bottom + 7),
                runtimeInsets: EdgeInsets(top: 4, leading: 4, bottom: 8, trailing: 4),
                runtimeOffset: CGSize(width: -3, height: -2)
            )
        }

        if normalizedDeviceName.contains("46mm") || normalizedDeviceName.contains("series 11") || maxDimension >= 246 {
            return WatchViewportProfile(
                kind: .series46,
                captureCanvasSize: CGSize(width: 208, height: 248),
                horizontalGuard: max(8, safeAreaInsets.leading, safeAreaInsets.trailing),
                topGuard: max(8, safeAreaInsets.top + 3),
                bottomGuard: max(12, safeAreaInsets.bottom + 6),
                runtimeInsets: EdgeInsets(top: 4, leading: 4, bottom: 8, trailing: 4),
                runtimeOffset: CGSize(width: -2, height: -1)
            )
        }

        return WatchViewportProfile(
            kind: .compact,
            captureCanvasSize: CGSize(width: max(containerSize.width, 192), height: max(containerSize.height, 230)),
            horizontalGuard: max(8, safeAreaInsets.leading, safeAreaInsets.trailing),
            topGuard: max(9, safeAreaInsets.top + 4),
            bottomGuard: max(16, safeAreaInsets.bottom + 7),
            runtimeInsets: EdgeInsets(top: 4, leading: 4, bottom: 8, trailing: 4),
            runtimeOffset: CGSize(width: 0, height: 0)
        )
    }

    func visibleRect(in containerSize: CGSize, safeAreaInsets: EdgeInsets = .init()) -> CGRect {
        let leftInset = max(horizontalGuard, safeAreaInsets.leading)
        let rightInset = max(horizontalGuard, safeAreaInsets.trailing)
        let topInset = max(topGuard, safeAreaInsets.top)
        let bottomInset = max(bottomGuard, safeAreaInsets.bottom)

        return CGRect(
            x: leftInset,
            y: topInset,
            width: max(containerSize.width - leftInset - rightInset, 120),
            height: max(containerSize.height - topInset - bottomInset, 140)
        )
    }

    func runtimeRect(in containerSize: CGSize) -> CGRect {
        let visible = visibleRect(in: containerSize)
        let leadingInset = max(visible.minX - runtimeInsets.leading, 0)
        let topInset = max(visible.minY - runtimeInsets.top, 0)
        let trailingInset = max(containerSize.width - visible.maxX - runtimeInsets.trailing, 0)
        let bottomInset = max(containerSize.height - visible.maxY - runtimeInsets.bottom, 0)

        let width = max(containerSize.width - leadingInset - trailingInset, 120)
        let height = max(containerSize.height - topInset - bottomInset, 140)
        let shiftedX = min(max(leadingInset + runtimeOffset.width, 0), max(containerSize.width - width, 0))
        let shiftedY = min(max(topInset + runtimeOffset.height, 0), max(containerSize.height - height, 0))

        return CGRect(
            x: shiftedX,
            y: shiftedY,
            width: width,
            height: height
        )
    }
}
