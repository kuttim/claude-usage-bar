import SwiftUI

final class UsageModel: ObservableObject {
    @Published var usage: Usage?
    @Published var error: String?
    @Published var updated: Date?
    var onRefresh: () -> Void = {}
}

func levelColor(_ pct: Double) -> Color {
    switch pct {
    case ..<70: return claudeCoral
    case ..<90: return .orange
    default: return .red
    }
}

private func resetText(_ d: Date?) -> String {
    guard let d else { return "No active window" }
    let secs = Int(d.timeIntervalSinceNow)
    guard secs > 0 else { return "Resetting…" }
    let days = secs / 86400, hrs = (secs % 86400) / 3600, mins = (secs % 3600) / 60
    let rel = days > 0 ? "\(days)d \(hrs)h" : hrs > 0 ? "\(hrs)h \(mins)m" : "\(mins)m"
    return "Resets in \(rel)"
}

struct LimitCard: View {
    let title: String
    let subtitle: String
    let limit: Limit?
    let window: TimeInterval

    var body: some View {
        let pct = limit?.utilization ?? 0
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 13, weight: .semibold))
                    Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(pct.rounded()))%")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(levelColor(pct))
            }
            UsageBar(pct: pct, elapsed: elapsedFraction(limit, window: window), height: 8)
            HStack {
                Text(resetText(limit?.resetsAt))
                Spacer()
                if let e = elapsedFraction(limit, window: window) {
                    Text("\(Int((e * 100).rounded()))% of window elapsed")
                }
            }
            .font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.primary.opacity(0.05)))
    }
}

struct PopoverView: View {
    @ObservedObject var model: UsageModel

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ClaudeMark().fill(claudeCoral).frame(width: 18, height: 18)
                Text("Claude Usage").font(.system(size: 14, weight: .semibold))
                Spacer()
                Button { model.onRefresh() } label: {
                    Image(systemName: "arrow.clockwise").font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.plain).foregroundStyle(.secondary).help("Refresh")
            }
            LimitCard(title: "Session", subtitle: "5-hour limit", limit: model.usage?.fiveHour, window: 5 * 3600)
            LimitCard(title: "Weekly", subtitle: "7-day limit", limit: model.usage?.weekly, window: 7 * 86400)
            HStack {
                if let e = model.error {
                    Label(e, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                } else if let u = model.updated {
                    Text("Updated \(u.formatted(date: .omitted, time: .shortened))").foregroundStyle(.secondary)
                }
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
            }
            .font(.system(size: 11))
        }
        .padding(16)
        .frame(width: 290)
    }
}
