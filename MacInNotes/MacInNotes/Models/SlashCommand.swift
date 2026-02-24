import Foundation

/// Represents a slash command that can be triggered by typing "/" in Notes.
struct SlashCommand: Identifiable, Hashable {
    let id: String
    let name: String
    let aliases: [String]
    let description: String
    let icon: String
    let action: CommandAction

    enum CommandAction: Hashable {
        case insertFormat(NotesFormat)
        case insertTable(rows: Int, columns: Int)
        case insertDivider
        case insertTimestamp
    }

    func matches(query: String) -> Bool {
        let lowered = query.lowercased()
        if name.lowercased().contains(lowered) { return true }
        return aliases.contains { $0.lowercased().contains(lowered) }
    }

    static func == (lhs: SlashCommand, rhs: SlashCommand) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Apple Notes supported formatting types.
enum NotesFormat: String, Hashable {
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

    var displayName: String {
        switch self {
        case .title: return "Title"
        case .heading: return "Heading"
        case .subheading: return "Subheading"
        case .body: return "Body"
        case .monospaced: return "Monospaced"
        case .bulletList: return "Bulleted List"
        case .dashedList: return "Dashed List"
        case .numberedList: return "Numbered List"
        case .checklist: return "Checklist"
        case .blockQuote: return "Block Quote"
        }
    }
}

// MARK: - Predefined Commands

extension SlashCommand {
    static let allCommands: [SlashCommand] = [
        SlashCommand(
            id: "title",
            name: "Title",
            aliases: ["h1"],
            description: "Create a large title",
            icon: "textformat.size.larger",
            action: .insertFormat(.title)
        ),
        SlashCommand(
            id: "heading",
            name: "Heading",
            aliases: ["h2"],
            description: "Create a heading",
            icon: "textformat.size",
            action: .insertFormat(.heading)
        ),
        SlashCommand(
            id: "subheading",
            name: "Subheading",
            aliases: ["h3"],
            description: "Create a subheading",
            icon: "textformat.size.smaller",
            action: .insertFormat(.subheading)
        ),
        SlashCommand(
            id: "code",
            name: "Code",
            aliases: ["monospaced", "mono"],
            description: "Create a monospaced code block",
            icon: "chevron.left.forwardslash.chevron.right",
            action: .insertFormat(.monospaced)
        ),
        SlashCommand(
            id: "checklist",
            name: "Checklist",
            aliases: ["todo", "task"],
            description: "Create a checklist item",
            icon: "checklist",
            action: .insertFormat(.checklist)
        ),
        SlashCommand(
            id: "bullet",
            name: "Bullet List",
            aliases: ["list", "ul"],
            description: "Create a bulleted list",
            icon: "list.bullet",
            action: .insertFormat(.bulletList)
        ),
        SlashCommand(
            id: "numbered",
            name: "Numbered List",
            aliases: ["ol", "ordered"],
            description: "Create a numbered list",
            icon: "list.number",
            action: .insertFormat(.numberedList)
        ),
        SlashCommand(
            id: "quote",
            name: "Block Quote",
            aliases: ["blockquote"],
            description: "Create a block quote",
            icon: "text.quote",
            action: .insertFormat(.blockQuote)
        ),
        SlashCommand(
            id: "table",
            name: "Table",
            aliases: [],
            description: "Insert a table",
            icon: "tablecells",
            action: .insertTable(rows: 3, columns: 3)
        ),
        SlashCommand(
            id: "divider",
            name: "Divider",
            aliases: ["hr", "line"],
            description: "Insert a horizontal divider",
            icon: "minus",
            action: .insertDivider
        ),
        SlashCommand(
            id: "timestamp",
            name: "Timestamp",
            aliases: ["date", "now"],
            description: "Insert current date and time",
            icon: "clock",
            action: .insertTimestamp
        ),
    ]
}
