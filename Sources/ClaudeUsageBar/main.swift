import AppKit
import SwiftUI

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let model = UsageModel()
    private let popover = NSPopover()
    private var timer: Timer?
    private var appearanceObs: NSKeyValueObservation?

    func applicationDidFinishLaunching(_ notification: Notification) {
        model.onRefresh = { [weak self] in self?.refresh() }
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PopoverView(model: model))

        if let b = item.button {
            b.target = self
            b.action = #selector(toggle)
        }
        appearanceObs = item.button?.observe(\.effectiveAppearance) { [weak self] _, _ in
            DispatchQueue.main.async { self?.render() }
        }
        render()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in self?.refresh() }
    }

    @objc func toggle() {
        guard let b = item.button else { return }
        if popover.isShown { popover.performClose(nil) } else {
            popover.show(relativeTo: b.bounds, of: b, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    func refresh() {
        Task { @MainActor in
            do {
                model.usage = try await UsageClient.fetch()
                model.error = nil
                model.updated = Date()
            } catch {
                model.error = "\(error)"
            }
            render()
        }
    }

    private func render() {
        guard let b = item.button else { return }
        let dark = b.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        b.image = menuBarImage(usage: model.usage, failed: model.usage == nil && model.error != nil, dark: dark)
        b.imagePosition = .imageOnly
    }
}

MainActor.assumeIsolated {
    if let i = CommandLine.arguments.firstIndex(of: "--render"), i + 1 < CommandLine.arguments.count {
        renderScreenshots(to: CommandLine.arguments[i + 1])
        exit(0)
    }
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
