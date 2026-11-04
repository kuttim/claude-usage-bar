import SwiftUI
import AppKit

/// Fraction (0...1) of the limit's time window that has already elapsed.
func elapsedFraction(_ limit: Limit?, window: TimeInterval) -> Double? {
    guard let r = limit?.resetsAt else { return nil }
    return min(1, max(0, 1 - r.timeIntervalSinceNow / window))
}

struct UsageBar: View {
    let pct: Double
    let elapsed: Double?
    var height: CGFloat = 4
    var track: Color = .primary.opacity(0.18)
    var tick: Color = .primary

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().fill(levelColor(pct))
                    .frame(width: max(pct > 0 ? height : 0, g.size.width * min(pct, 100) / 100))
                if let e = elapsed {
                    Rectangle().fill(tick)
                        .frame(width: 1.5, height: height + 4)
                        .offset(x: g.size.width * e - 0.75, y: 0)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(height: height + 4)
    }
}

struct MenuBarView: View {
    let usage: Usage?
    let failed: Bool
    let dark: Bool

    var body: some View {
        let fg: Color = dark ? .white : .black
        HStack(spacing: 11) {
            ClaudeMark().fill(claudeCoral).frame(width: 17, height: 17)
            if failed {
                Text("⚠︎").font(.system(size: 13, weight: .medium)).foregroundStyle(fg)
            } else {
                seg("5h", usage?.fiveHour, window: 5 * 3600, fg)
                seg("7d", usage?.weekly, window: 7 * 86400, fg)
            }
        }
        .padding(.horizontal, 2)
        .environment(\.colorScheme, dark ? .dark : .light)
    }

    private func seg(_ name: String, _ l: Limit?, window: TimeInterval, _ fg: Color) -> some View {
        let pct = l?.utilization ?? 0
        return HStack(spacing: 5) {
            Text(name).font(.system(size: 13, weight: .medium)).foregroundStyle(fg.opacity(0.65))
            UsageBar(pct: pct, elapsed: elapsedFraction(l, window: window),
                     track: fg.opacity(0.22), tick: fg.opacity(0.85))
                .frame(width: 38)
            Text("\(Int(pct.rounded()))%")
                .font(.system(size: 13, weight: .semibold)).monospacedDigit()
                .foregroundStyle(pct >= 90 ? .red : pct >= 70 ? .orange : fg)
        }
    }
}

@MainActor func menuBarImage(usage: Usage?, failed: Bool, dark: Bool) -> NSImage? {
    let r = ImageRenderer(content: MenuBarView(usage: usage, failed: failed, dark: dark))
    r.scale = NSScreen.main?.backingScaleFactor ?? 2
    let img = r.nsImage
    img?.isTemplate = false
    return img
}
