import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()

    private let notesService = NotesService.shared
    private let keyboardMonitor = KeyboardMonitor.shared
    private let markdownService = MarkdownService.shared
    private let slashCommandService = SlashCommandService.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBarItem()
        checkFirstLaunch()
        startServices()

        // Hide dock icon — this is a menu bar app
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        keyboardMonitor.stop()
    }

    // MARK: - Status Bar

    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "MacInNotes")
            button.action = #selector(togglePopover)
            button.target = self
        }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(AppState.shared)
        )
        self.popover = popover
    }

    @objc private func togglePopover() {
        guard let popover = popover, let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

            // Refresh Notes connection status
            Task {
                await AppState.shared.refreshNotesStatus()
            }
        }
    }

    // MARK: - First Launch

    private func checkFirstLaunch() {
        let hasLaunched = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding)
        if !hasLaunched {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "onboarding" }) {
                    window.makeKeyAndOrderFront(nil)
                } else {
                    NSApp.sendAction(Selector(("showOnboarding:")), to: nil, from: nil)
                }
            }
        }
    }

    // MARK: - Services

    private func startServices() {
        guard AccessibilityHelper.isAccessibilityEnabled() else {
            AppState.shared.accessibilityEnabled = false
            return
        }

        AppState.shared.accessibilityEnabled = true

        // Start monitoring Notes app
        notesService.startMonitoring()

        // Start keyboard monitoring for Markdown and slash commands
        keyboardMonitor.start()

        // Subscribe to keyboard events
        keyboardMonitor.onKeyEvent
            .sink { [weak self] event in
                self?.handleKeyEvent(event)
            }
            .store(in: &cancellables)
    }

    private func handleKeyEvent(_ event: KeyboardEvent) {
        switch event {
        case .spaceAfterMarkdown(let trigger, let lineRange):
            markdownService.processMarkdownTrigger(trigger, lineRange: lineRange)

        case .slashTyped(let position):
            slashCommandService.showCommandMenu(at: position)

        case .commandSelected(let command):
            slashCommandService.execute(command)
        }
    }
}
