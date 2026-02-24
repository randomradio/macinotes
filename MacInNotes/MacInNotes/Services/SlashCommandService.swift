import AppKit
import SwiftUI

/// Service responsible for handling slash command detection and execution.
final class SlashCommandService {
    static let shared = SlashCommandService()

    private var commandWindow: NSWindow?
    private let notesService = NotesService.shared
    private let markdownService = MarkdownService.shared

    private init() {}

    // MARK: - Command Menu

    /// Show the slash command picker menu at the specified screen position.
    func showCommandMenu(at position: NSPoint) {
        guard AppState.shared.slashCommandsEnabled else { return }

        // Close existing command window
        dismissCommandMenu()

        let commandView = SlashCommandPopoverView(
            commands: SlashCommand.allCommands,
            onSelect: { [weak self] command in
                self?.execute(command)
                self?.dismissCommandMenu()
            },
            onDismiss: { [weak self] in
                self?.dismissCommandMenu()
            }
        )

        let hostingView = NSHostingView(rootView: commandView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 260, height: 340)

        let window = NSPanel(
            contentRect: NSRect(x: position.x, y: position.y - 340, width: 260, height: 340),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        window.orderFrontRegardless()

        self.commandWindow = window

        // Auto-dismiss after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.dismissCommandMenu()
        }
    }

    func dismissCommandMenu() {
        commandWindow?.close()
        commandWindow = nil
    }

    // MARK: - Command Execution

    /// Execute a slash command.
    func execute(_ command: SlashCommand) {
        // First, remove the "/" character that triggered the command
        removeSlashPrefix()

        switch command.action {
        case .insertFormat(let format):
            markdownService.applyFormat(format)

        case .insertTable(let rows, let columns):
            insertTable(rows: rows, columns: columns)

        case .insertDivider:
            insertDivider()

        case .insertTimestamp:
            insertTimestamp()
        }
    }

    // MARK: - Private Actions

    private func removeSlashPrefix() {
        guard let lineInfo = notesService.getCurrentLineText() else { return }

        // Find the "/" in the current line and remove it
        if let slashRange = lineInfo.text.range(of: "/") {
            let offset = lineInfo.text.distance(from: lineInfo.text.startIndex, to: slashRange.lowerBound)
            let range = NSRange(location: lineInfo.range.location + offset, length: 1)
            notesService.replaceText(in: range, with: "")
        }
    }

    private func insertTable(rows: Int, columns: Int) {
        // Apple Notes supports tables via AppleScript
        let script = """
        tell application "System Events"
            tell process "Notes"
                click menu item "Table" of menu "Format" of menu bar 1
            end tell
        end tell
        """
        DispatchQueue.global(qos: .userInteractive).async {
            var error: NSDictionary?
            let appleScript = NSAppleScript(source: script)
            appleScript?.executeAndReturnError(&error)
        }
    }

    private func insertDivider() {
        let divider = "————————————————"
        notesService.insertTextAtCursor(divider)
    }

    private func insertTimestamp() {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        let timestamp = formatter.string(from: Date())
        notesService.insertTextAtCursor(timestamp)
    }
}
