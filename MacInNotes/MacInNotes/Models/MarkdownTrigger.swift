import Foundation

/// Represents a Markdown syntax trigger that converts to a Notes format.
struct MarkdownTrigger {
    let pattern: String
    let format: NotesFormat

    /// All supported Markdown triggers.
    /// Matched against the beginning of the current line when the user presses Space.
    static let allTriggers: [MarkdownTrigger] = [
        MarkdownTrigger(pattern: "#", format: .title),
        MarkdownTrigger(pattern: "##", format: .heading),
        MarkdownTrigger(pattern: "###", format: .subheading),
        MarkdownTrigger(pattern: "[]", format: .checklist),
        MarkdownTrigger(pattern: "```", format: .monospaced),
        MarkdownTrigger(pattern: ">", format: .blockQuote),
        MarkdownTrigger(pattern: "-", format: .dashedList),
        MarkdownTrigger(pattern: "*", format: .bulletList),
        MarkdownTrigger(pattern: "1.", format: .numberedList),
    ]

    /// Find the matching trigger for a given line prefix.
    /// Triggers are sorted longest-first so "###" matches before "#".
    static func match(linePrefix: String) -> MarkdownTrigger? {
        let trimmed = linePrefix.trimmingCharacters(in: .whitespaces)
        // Sort by pattern length descending to match longest first
        return allTriggers
            .sorted { $0.pattern.count > $1.pattern.count }
            .first { trimmed == $0.pattern }
    }
}
