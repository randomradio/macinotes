import SwiftUI

/// Floating popover that displays slash commands for quick insertion.
struct SlashCommandPopoverView: View {
    let commands: [SlashCommand]
    let onSelect: (SlashCommand) -> Void
    let onDismiss: () -> Void

    @State private var searchText = ""
    @State private var selectedIndex = 0

    private var filteredCommands: [SlashCommand] {
        if searchText.isEmpty {
            return commands
        }
        return commands.filter { $0.matches(query: searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search commands...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .onSubmit {
                        if let command = filteredCommands[safe: selectedIndex] {
                            onSelect(command)
                        }
                    }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Command list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filteredCommands.enumerated()), id: \.element.id) { index, command in
                            CommandRow(
                                command: command,
                                isSelected: index == selectedIndex
                            )
                            .id(command.id)
                            .onTapGesture {
                                onSelect(command)
                            }
                            .onHover { hovering in
                                if hovering {
                                    selectedIndex = index
                                }
                            }
                        }
                    }
                }
                .onChange(of: selectedIndex) { newIndex in
                    if let command = filteredCommands[safe: newIndex] {
                        withAnimation {
                            proxy.scrollTo(command.id, anchor: .center)
                        }
                    }
                }
            }

            if filteredCommands.isEmpty {
                VStack {
                    Text("No matching commands")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .frame(width: 260, height: 340)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .onKeyPress(phases: .down) { press in
            handleKeyPress(press)
        }
    }

    private func handleKeyPress(_ press: KeyPress) -> KeyPress.Result {
        switch press.key {
        case .upArrow:
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
            return .handled

        case .downArrow:
            if selectedIndex < filteredCommands.count - 1 {
                selectedIndex += 1
            }
            return .handled

        case .escape:
            onDismiss()
            return .handled

        case .return:
            if let command = filteredCommands[safe: selectedIndex] {
                onSelect(command)
            }
            return .handled

        default:
            return .ignored
        }
    }
}

// MARK: - Command Row

private struct CommandRow: View {
    let command: SlashCommand
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: command.icon)
                .font(.body)
                .frame(width: 24)
                .foregroundColor(isSelected ? .white : .accentColor)

            VStack(alignment: .leading, spacing: 1) {
                Text(command.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)

                Text(command.description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }

            Spacer()

            if !command.aliases.isEmpty {
                Text("/" + command.aliases.first!)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(
                        (isSelected ? Color.white.opacity(0.2) : Color.gray.opacity(0.1))
                    )
                    .cornerRadius(3)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor : Color.clear)
        .contentShape(Rectangle())
    }
}

// MARK: - Safe Array Access

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
