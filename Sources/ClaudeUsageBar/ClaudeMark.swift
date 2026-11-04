import SwiftUI
import AppKit

let claudeCoral = Color(red: 0.851, green: 0.467, blue: 0.341)   // #D97757

/// Starburst of rounded rays, in the spirit of the Claude mark.
struct ClaudeMark: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let rays = 12
        for i in 0..<rays {
            let a = Double(i) / Double(rays) * 2 * .pi - .pi / 2
            let len = (i % 2 == 0 ? 1.0 : 0.78) * r
            let inner = r * 0.16
            p.move(to: CGPoint(x: c.x + cos(a) * inner, y: c.y + sin(a) * inner))
            p.addLine(to: CGPoint(x: c.x + cos(a) * len, y: c.y + sin(a) * len))
        }
        return p.strokedPath(StrokeStyle(lineWidth: r * 0.26, lineCap: .round))
    }
}

@MainActor func claudeMarkImage(size: CGFloat) -> NSImage {
    let view = ClaudeMark().fill(claudeCoral).frame(width: size, height: size)
    let renderer = ImageRenderer(content: view)
    renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
    let img = renderer.nsImage ?? NSImage(size: NSSize(width: size, height: size))
    img.isTemplate = false
    return img
}
