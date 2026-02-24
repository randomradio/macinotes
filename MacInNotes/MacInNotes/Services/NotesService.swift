import AppKit
import Combine

/// Service responsible for communicating with Apple Notes via AppleScript and Accessibility API.
final class NotesService {
    static let shared = NotesService()

    private var notesObserver: NSObjectProtocol?
    private let notesAppBundleID = "com.apple.Notes"

    private init() {}

    // MARK: - Notes App Detection

    /// Check if Apple Notes is currently running.
    func isNotesRunning() -> Bool {
        NSRunningApplication.runningApplications(withBundleIdentifier: notesAppBundleID).first != nil
    }

    /// Start monitoring Notes app launch/quit.
    func startMonitoring() {
        let workspace = NSWorkspace.shared

        workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier == self?.notesAppBundleID else { return }
            Task { @MainActor in
                AppState.shared.isNotesRunning = true
            }
        }

        workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier == self?.notesAppBundleID else { return }
            Task { @MainActor in
                AppState.shared.isNotesRunning = false
                AppState.shared.currentNoteTitle = nil
            }
        }

        // Set initial state
        Task { @MainActor in
            AppState.shared.isNotesRunning = isNotesRunning()
        }
    }

    // MARK: - AppleScript Integration

    /// Get the title of the currently selected note.
    func getCurrentNoteTitle() async -> String? {
        let script = """
        tell application "Notes"
            try
                set theNote to selection
                if theNote is not {} then
                    return name of item 1 of theNote
                end if
            end try
            return ""
        end tell
        """
        return await runAppleScript(script)
    }

    /// Get the body content of the currently selected note.
    func getCurrentNoteBody() async -> String? {
        let script = """
        tell application "Notes"
            try
                set theNote to selection
                if theNote is not {} then
                    return plaintext of item 1 of theNote
                end if
            end try
            return ""
        end tell
        """
        return await runAppleScript(script)
    }

    /// Get a list of all note titles in the default account.
    func getAllNoteTitles() async -> [String] {
        let script = """
        tell application "Notes"
            try
                set noteTitles to {}
                repeat with aNote in notes of default account
                    set end of noteTitles to name of aNote
                end repeat
                return noteTitles
            end try
            return {}
        end tell
        """
        guard let result = await runAppleScript(script) else { return [] }
        return result.components(separatedBy: ", ")
    }

    /// Append text to the currently selected note.
    func appendToCurrentNote(text: String) async -> Bool {
        let escapedText = text.replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")

        let script = """
        tell application "Notes"
            try
                set theNote to selection
                if theNote is not {} then
                    set theBody to body of item 1 of theNote
                    set body of item 1 of theNote to theBody & "<br>" & "\(escapedText)"
                    return "success"
                end if
            end try
            return "failed"
        end tell
        """
        let result = await runAppleScript(script)
        return result == "success"
    }

    /// Export audio attachments from the current note to a temporary directory.
    func exportAudioAttachments() async -> [URL] {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacInNotes_Audio", isDirectory: true)

        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let script = """
        tell application "Notes"
            try
                set theNote to selection
                if theNote is not {} then
                    set theAttachments to attachments of item 1 of theNote
                    set audioFiles to {}
                    repeat with att in theAttachments
                        set attName to name of att
                        if attName ends with ".m4a" or attName ends with ".mp3" or attName ends with ".wav" or attName ends with ".aac" then
                            set end of audioFiles to attName
                        end if
                    end repeat
                    return audioFiles as text
                end if
            end try
            return ""
        end tell
        """

        guard let result = await runAppleScript(script), !result.isEmpty else {
            return []
        }

        let fileNames = result.components(separatedBy: ", ")
        return fileNames.compactMap { name in
            let url = tempDir.appendingPathComponent(name)
            return FileManager.default.fileExists(atPath: url.path) ? url : nil
        }
    }

    // MARK: - Accessibility API Integration

    /// Get the AXUIElement for the Notes text editor.
    func getNotesTextArea() -> AXUIElement? {
        guard let notesApp = NSRunningApplication.runningApplications(
            withBundleIdentifier: notesAppBundleID
        ).first else {
            return nil
        }

        let appElement = AXUIElementCreateApplication(notesApp.processIdentifier)
        return findTextArea(in: appElement)
    }

    /// Get the currently selected text in Notes.
    func getSelectedText() -> String? {
        guard let textArea = getNotesTextArea() else { return nil }

        var selectedText: AnyObject?
        let result = AXUIElementCopyAttributeValue(textArea, kAXSelectedTextAttribute as CFString, &selectedText)

        guard result == .success, let text = selectedText as? String else {
            return nil
        }
        return text
    }

    /// Get the text of the current line in the Notes editor.
    func getCurrentLineText() -> (text: String, range: NSRange)? {
        guard let textArea = getNotesTextArea() else { return nil }

        // Get full text value
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(textArea, kAXValueAttribute as CFString, &value) == .success,
              let fullText = value as? String else {
            return nil
        }

        // Get cursor position
        var selectedRange: AnyObject?
        guard AXUIElementCopyAttributeValue(textArea, kAXSelectedTextRangeAttribute as CFString, &selectedRange) == .success else {
            return nil
        }

        var range = CFRange(location: 0, length: 0)
        guard AXValueGetValue(selectedRange as! AXValue, .cfRange, &range) else {
            return nil
        }

        let cursorPosition = range.location
        let nsString = fullText as NSString

        // Find line boundaries
        let lineRange = nsString.lineRange(for: NSRange(location: cursorPosition, length: 0))
        let lineText = nsString.substring(with: lineRange)

        return (lineText, lineRange)
    }

    /// Insert text at the current cursor position via Accessibility API.
    func insertTextAtCursor(_ text: String) {
        guard let textArea = getNotesTextArea() else { return }
        AXUIElementSetAttributeValue(textArea, kAXSelectedTextAttribute as CFString, text as CFTypeRef)
    }

    /// Replace text in the given range via Accessibility API.
    func replaceText(in range: NSRange, with text: String) {
        guard let textArea = getNotesTextArea() else { return }

        // Set the selection range
        var cfRange = CFRange(location: range.location, length: range.length)
        guard let rangeValue = AXValueCreate(.cfRange, &cfRange) else { return }

        AXUIElementSetAttributeValue(textArea, kAXSelectedTextRangeAttribute as CFString, rangeValue)

        // Replace selected text
        AXUIElementSetAttributeValue(textArea, kAXSelectedTextAttribute as CFString, text as CFTypeRef)
    }

    // MARK: - Private Helpers

    private func runAppleScript(_ source: String) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                let script = NSAppleScript(source: source)
                let result = script?.executeAndReturnError(&error)

                if let error = error {
                    print("[NotesService] AppleScript error: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: result?.stringValue)
            }
        }
    }

    /// Recursively find the text area AXUIElement in the Notes window.
    private func findTextArea(in element: AXUIElement) -> AXUIElement? {
        var role: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)

        if let roleStr = role as? String, roleStr == kAXTextAreaRole as String {
            return element
        }

        var children: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &children)

        guard let childrenArray = children as? [AXUIElement] else { return nil }

        for child in childrenArray {
            if let textArea = findTextArea(in: child) {
                return textArea
            }
        }

        return nil
    }
}
