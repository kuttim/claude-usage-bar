import SwiftUI
import AppKit

/// Renders README screenshots from sample data: `ClaudeUsageBar --render <dir>`.
@MainActor func renderScreenshots(to dir: String) {
    let sample = Usage(
        fiveHour: Limit(utilization: 42, resetsAt: Date().addingTimeInterval(2 * 3600 + 10 * 60)),
        weekly: Limit(utilization: 63, resetsAt: Date().addingTimeInterval(3 * 86400 + 4 * 3600)))
    let hot = Usage(
        fiveHour: Limit(utilization: 93, resetsAt: Date().addingTimeInterval(40 * 60)),
        weekly: Limit(utilization: 74, resetsAt: Date().addingTimeInterval(86400)))

    func save<V: View>(_ view: V, _ name: String) {
        let r = ImageRenderer(content: view)
        r.scale = 3
        guard let img = r.nsImage, let tiff = img.tiffRepresentation,
              let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else { return }
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? png.write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
    }

    func strip(_ u: Usage, dark: Bool) -> some View {
        MenuBarView(usage: u, failed: false, dark: dark)
            .padding(.horizontal, 18).frame(height: 30)
            .background(RoundedRectangle(cornerRadius: 8).fill(dark ? Color(white: 0.13) : Color(white: 0.93)))
            .padding(10)
    }

    func card(_ u: Usage, dark: Bool) -> some View {
        let m = UsageModel()
        m.usage = u
        m.updated = Date()
        return PopoverView(model: m)
            .background(RoundedRectangle(cornerRadius: 14).fill(dark ? Color(white: 0.14) : Color.white))
            .environment(\.colorScheme, dark ? .dark : .light)
            .padding(16)
    }

    save(strip(sample, dark: true), "menubar-dark")
    save(strip(sample, dark: false), "menubar-light")
    save(strip(hot, dark: true), "menubar-warning")
    save(card(sample, dark: true), "popover-dark")
    save(card(sample, dark: false), "popover-light")
}
