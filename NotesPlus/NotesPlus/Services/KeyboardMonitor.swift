import AppKit
import Combine
import Carbon.HIToolbox

/// Monitors global keyboard events for Markdown triggers and slash commands.
final class KeyboardMonitor {
    static let shared = KeyboardMonitor()

    let onKeyEvent = PassthroughSubject<KeyboardEvent, Never>()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var currentLineBuffer = ""
    private let notesService = NotesService.shared

    private init() {}

    // MARK: - Start / Stop

    func start() {
        guard eventTap == nil else { return }

        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        // Create event tap
        let callback: CGEventTapCallBack = { proxy, type, event, refcon -> Unmanaged<CGEvent>? in
            guard let refcon = refcon else {
                return Unmanaged.passRetained(event)
            }

            let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon).takeUnretainedValue()

            // Re-enable tap if it was disabled
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let tap = monitor.eventTap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
                return Unmanaged.passRetained(event)
            }

            // Only process when Notes is frontmost
            guard monitor.isNotesFrontmost() else {
                return Unmanaged.passRetained(event)
            }

            monitor.processKeyEvent(event)
            return Unmanaged.passRetained(event)
        }

        let refcon = Unmanaged.passUnretained(self).toOpaque()

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: refcon
        )

        guard let tap = eventTap else {
            print("[KeyboardMonitor] Failed to create event tap. Accessibility permission required.")
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        print("[KeyboardMonitor] Started monitoring keyboard events.")
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        currentLineBuffer = ""

        print("[KeyboardMonitor] Stopped monitoring keyboard events.")
    }

    // MARK: - Event Processing

    private func processKeyEvent(_ event: CGEvent) {
        guard let nsEvent = NSEvent(cgEvent: event) else { return }

        let keyCode = nsEvent.keyCode
        let characters = nsEvent.characters ?? ""

        // Handle Space key — check for Markdown triggers
        if keyCode == UInt16(kVK_Space) {
            checkMarkdownTrigger()
            return
        }

        // Handle Return/Enter — reset line buffer
        if keyCode == UInt16(kVK_Return) {
            currentLineBuffer = ""
            return
        }

        // Handle Delete — trim buffer
        if keyCode == UInt16(kVK_Delete) {
            if !currentLineBuffer.isEmpty {
                currentLineBuffer.removeLast()
            }
            return
        }

        // Handle "/" character — check for slash command trigger
        if characters == "/" {
            checkSlashCommandTrigger()
        }

        // Append to line buffer
        currentLineBuffer += characters
    }

    private func checkMarkdownTrigger() {
        let trimmed = currentLineBuffer.trimmingCharacters(in: .whitespaces)

        guard let trigger = MarkdownTrigger.match(linePrefix: trimmed) else {
            return
        }

        // Get the actual line info from the text area
        guard let lineInfo = notesService.getCurrentLineText() else { return }

        onKeyEvent.send(.spaceAfterMarkdown(trigger: trigger, lineRange: lineInfo.range))

        // Reset buffer after trigger
        currentLineBuffer = ""
    }

    private func checkSlashCommandTrigger() {
        let trimmed = currentLineBuffer.trimmingCharacters(in: .whitespaces)

        // Slash should be at the start of a line or after whitespace
        guard trimmed.isEmpty else { return }

        // Get cursor screen position for popover placement
        let mouseLocation = NSEvent.mouseLocation
        onKeyEvent.send(.slashTyped(position: mouseLocation))
    }

    // MARK: - Helpers

    private func isNotesFrontmost() -> Bool {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return false }
        return frontApp.bundleIdentifier == "com.apple.Notes"
    }
}
