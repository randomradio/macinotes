import Foundation

/// Events emitted by the keyboard monitor.
enum KeyboardEvent {
    /// User pressed Space after typing a Markdown trigger at the start of a line.
    case spaceAfterMarkdown(trigger: MarkdownTrigger, lineRange: NSRange)

    /// User typed "/" at the start of a line or after whitespace.
    case slashTyped(position: NSPoint)

    /// User selected a command from the slash command menu.
    case commandSelected(SlashCommand)
}
