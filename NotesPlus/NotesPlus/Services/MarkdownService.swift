import AppKit
import Combine

/// Service that detects Markdown syntax input and converts it to Apple Notes formatting.
final class MarkdownService {
    static let shared = MarkdownService()

    private let notesService = NotesService.shared

    private init() {}

    /// Process a detected Markdown trigger, replacing the syntax with the appropriate Notes format.
    func processMarkdownTrigger(_ trigger: MarkdownTrigger, lineRange: NSRange) {
        guard AppState.shared.markdownEnabled else { return }

        // Remove the Markdown syntax characters from the line
        let syntaxLength = trigger.pattern.count + 1 // +1 for the trailing space
        let replaceRange = NSRange(location: lineRange.location, length: syntaxLength)

        // Clear the Markdown syntax text
        notesService.replaceText(in: replaceRange, with: "")

        // Apply the Notes format using AppleScript
        applyFormat(trigger.format)
    }

    /// Apply a Notes format to the current line using keyboard shortcuts.
    /// Apple Notes uses specific key commands for formatting.
    func applyFormat(_ format: NotesFormat) {
        switch format {
        case .title:
            simulateFormatShortcut(.title)
        case .heading:
            simulateFormatShortcut(.heading)
        case .subheading:
            simulateFormatShortcut(.subheading)
        case .body:
            simulateFormatShortcut(.body)
        case .monospaced:
            simulateFormatShortcut(.monospaced)
        case .bulletList:
            simulateFormatShortcut(.bulletList)
        case .dashedList:
            simulateFormatShortcut(.dashedList)
        case .numberedList:
            simulateFormatShortcut(.numberedList)
        case .checklist:
            simulateFormatShortcut(.checklist)
        case .blockQuote:
            simulateFormatShortcut(.blockQuote)
        }
    }

    // MARK: - Format Shortcuts

    /// Apple Notes formatting keyboard shortcuts.
    private enum FormatShortcut {
        case title
        case heading
        case subheading
        case body
        case monospaced
        case bulletList
        case dashedList
        case numberedList
        case checklist
        case blockQuote

        /// The keyboard shortcut for this format in Apple Notes.
        /// Uses Format menu actions via AppleScript.
        var appleScriptCommand: String {
            switch self {
            case .title:
                return """
                tell application "System Events"
                    tell process "Notes"
                        click menu item "Title" of menu "Format" of menu bar 1
                    end tell
                end tell
                """
            case .heading:
                return """
                tell application "System Events"
                    tell process "Notes"
                        click menu item "Heading" of menu "Format" of menu bar 1
                    end tell
                end tell
                """
            case .subheading:
                return """
                tell application "System Events"
                    tell process "Notes"
                        click menu item "Subheading" of menu "Format" of menu bar 1
                    end tell
                end tell
                """
            case .body:
                return """
                tell application "System Events"
                    tell process "Notes"
                        click menu item "Body" of menu "Format" of menu bar 1
                    end tell
                end tell
                """
            case .monospaced:
                return """
                tell application "System Events"
                    tell process "Notes"
                        click menu item "Monospaced" of menu "Format" of menu bar 1
                    end tell
                end tell
                """
            case .bulletList:
                return """
                tell application "System Events"
                    tell process "Notes"
                        click menu item "Bulleted List" of menu "Format" of menu bar 1
                    end tell
                end tell
                """
            case .dashedList:
                return """
                tell application "System Events"
                    tell process "Notes"
                        click menu item "Dashed List" of menu "Format" of menu bar 1
                    end tell
                end tell
                """
            case .numberedList:
                return """
                tell application "System Events"
                    tell process "Notes"
                        click menu item "Numbered List" of menu "Format" of menu bar 1
                    end tell
                end tell
                """
            case .checklist:
                return """
                tell application "System Events"
                    tell process "Notes"
                        click menu item "Checklist" of menu "Format" of menu bar 1
                    end tell
                end tell
                """
            case .blockQuote:
                return """
                tell application "System Events"
                    tell process "Notes"
                        click menu item "Block Quote" of menu "Format" of menu bar 1
                    end tell
                end tell
                """
            }
        }
    }

    private func simulateFormatShortcut(_ shortcut: FormatShortcut) {
        DispatchQueue.global(qos: .userInteractive).async {
            var error: NSDictionary?
            let script = NSAppleScript(source: shortcut.appleScriptCommand)
            script?.executeAndReturnError(&error)

            if let error = error {
                print("[MarkdownService] Failed to apply format: \(error)")
            }
        }
    }
}
