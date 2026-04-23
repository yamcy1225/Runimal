import AppKit
import Foundation

let outputDir = URL(fileURLWithPath: "/Users/heobella/jaw-bot-4/apps/runimal-apple/demo/frames", isDirectory: true)
let phoneImageURL = URL(fileURLWithPath: "/Users/heobella/jaw-bot-4/screenshots/runimal-phone-current.png")
let watchImageURL = URL(fileURLWithPath: "/Users/heobella/jaw-bot-4/screenshots/runimal-watch-current.png")

try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

let canvasSize = NSSize(width: 1280, height: 720)
let background = NSColor(calibratedRed: 5 / 255, green: 7 / 255, blue: 13 / 255, alpha: 1)
let surface = NSColor(calibratedRed: 18 / 255, green: 24 / 255, blue: 39 / 255, alpha: 1)
let accent = NSColor(calibratedRed: 1, green: 107 / 255, blue: 53 / 255, alpha: 1)
let muted = NSColor(calibratedWhite: 0.82, alpha: 1)

let titleFont = NSFont.systemFont(ofSize: 50, weight: .bold)
let headingFont = NSFont.systemFont(ofSize: 32, weight: .bold)
let bodyFont = NSFont.systemFont(ofSize: 24, weight: .medium)
let smallFont = NSFont.systemFont(ofSize: 20, weight: .regular)

func paragraph(_ alignment: NSTextAlignment = .left, lineHeight: CGFloat = 1.15) -> NSMutableParagraphStyle {
    let style = NSMutableParagraphStyle()
    style.alignment = alignment
    style.lineBreakMode = .byWordWrapping
    style.minimumLineHeight = bodyFont.pointSize * lineHeight
    style.maximumLineHeight = bodyFont.pointSize * lineHeight
    return style
}

func drawText(_ text: String, rect: NSRect, font: NSFont, color: NSColor, alignment: NSTextAlignment = .left, lineHeight: CGFloat = 1.15) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph(alignment, lineHeight: lineHeight),
    ]
    NSString(string: text).draw(in: rect, withAttributes: attrs)
}

func scaledRect(for image: NSImage, in target: NSRect) -> NSRect {
    let imageSize = image.size
    let widthRatio = target.width / imageSize.width
    let heightRatio = target.height / imageSize.height
    let scale = min(widthRatio, heightRatio)
    let scaledSize = NSSize(width: imageSize.width * scale, height: imageSize.height * scale)
    return NSRect(
        x: target.midX - scaledSize.width / 2,
        y: target.midY - scaledSize.height / 2,
        width: scaledSize.width,
        height: scaledSize.height
    )
}

func drawCard(_ rect: NSRect) {
    let path = NSBezierPath(roundedRect: rect, xRadius: 24, yRadius: 24)
    surface.setFill()
    path.fill()
}

func save(_ image: NSImage, name: String) throws {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "frame-save", code: 1)
    }

    try png.write(to: outputDir.appendingPathComponent(name))
}

func render(_ drawing: (NSRect) -> Void) -> NSImage {
    let image = NSImage(size: canvasSize)
    image.lockFocus()
    background.setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: canvasSize)).fill()
    drawing(NSRect(origin: .zero, size: canvasSize))
    image.unlockFocus()
    return image
}

let titleFrame = render { bounds in
    drawText("Runimal Demo", rect: NSRect(x: 0, y: 390, width: bounds.width, height: 70), font: titleFont, color: .white, alignment: .center)
    drawText("Post-run mock on iPhone and Apple Watch", rect: NSRect(x: 0, y: 330, width: bounds.width, height: 40), font: bodyFont, color: accent, alignment: .center)
}

let principleFrame = render { bounds in
    drawCard(NSRect(x: 80, y: 100, width: 1120, height: 520))
    drawText("Motion should exist, but it must explain reward", rect: NSRect(x: 120, y: 520, width: 1000, height: 60), font: headingFont, color: .white)
    drawText("• Start and finish need visible state change\n• Hatch result should land with weight\n• Growth progress should move, not just update text\n• Idle loops stay subtle on watch", rect: NSRect(x: 120, y: 250, width: 1000, height: 220), font: bodyFont, color: muted, lineHeight: 1.35)
}

let phoneFrame = render { _ in
    drawCard(NSRect(x: 70, y: 60, width: 1140, height: 600))
    drawText("Mock test: run completed, reward synced to phone", rect: NSRect(x: 110, y: 590, width: 1020, height: 44), font: headingFont, color: .white)
    drawText("Home now shows the active pet and post-run state from the simulated watch session.", rect: NSRect(x: 110, y: 550, width: 980, height: 36), font: smallFont, color: accent)

    if let phoneImage = NSImage(contentsOf: phoneImageURL) {
        let target = NSRect(x: 230, y: 110, width: 820, height: 410)
        let rect = scaledRect(for: phoneImage, in: target)
        phoneImage.draw(in: rect)
    }
}

let watchFrame = render { _ in
    drawCard(NSRect(x: 140, y: 70, width: 1000, height: 580))
    drawText("Watch companion in simulator", rect: NSRect(x: 180, y: 590, width: 900, height: 44), font: headingFont, color: .white)
    drawText("The watch surface stays glanceable while keeping pet identity and live state visible.", rect: NSRect(x: 180, y: 550, width: 860, height: 36), font: smallFont, color: accent)

    if let watchImage = NSImage(contentsOf: watchImageURL) {
        let target = NSRect(x: 380, y: 140, width: 520, height: 340)
        let rect = scaledRect(for: watchImage, in: target)
        watchImage.draw(in: rect)
    }
}

let summaryFrame = render { bounds in
    drawText("Mock test completed", rect: NSRect(x: 0, y: 460, width: bounds.width, height: 60), font: titleFont, color: .white, alignment: .center)
    drawText("Phone launch OK", rect: NSRect(x: 0, y: 360, width: bounds.width, height: 40), font: bodyFont, color: accent, alignment: .center)
    drawText("Watch launch OK", rect: NSRect(x: 0, y: 310, width: bounds.width, height: 40), font: bodyFont, color: accent, alignment: .center)
    drawText("Reward sync path and growth journal verified", rect: NSRect(x: 0, y: 230, width: bounds.width, height: 40), font: bodyFont, color: muted, alignment: .center)
}

try save(titleFrame, name: "frame-01-title.png")
try save(principleFrame, name: "frame-02-principle.png")
try save(phoneFrame, name: "frame-03-phone.png")
try save(watchFrame, name: "frame-04-watch.png")
try save(summaryFrame, name: "frame-05-summary.png")

print(outputDir.path)
