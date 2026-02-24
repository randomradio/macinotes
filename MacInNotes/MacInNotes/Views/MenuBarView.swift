import SwiftUI

/// The main menu bar popover view showing app status and quick actions.
struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var transcriptionService = TranscriptionService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerSection

            Divider()

            // Notes Status
            notesStatusSection

            Divider()

            // Quick Actions
            quickActionsSection

            Divider()

            // Transcription Section
            transcriptionSection

            Divider()

            // Footer
            footerSection
        }
        .padding(.vertical, 8)
        .frame(width: 320)
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack {
            Image(systemName: "note.text")
                .font(.title2)
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("MacInNotes")
                    .font(.headline)
                Text("v1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status indicator
            Circle()
                .fill(appState.accessibilityEnabled ? Color.green : Color.red)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var notesStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: appState.isNotesRunning ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundColor(appState.isNotesRunning ? .green : .secondary)
                Text(appState.isNotesRunning ? "Notes is running" : "Notes is not running")
                    .font(.subheadline)
            }

            if let noteTitle = appState.currentNoteTitle, !noteTitle.isEmpty {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.secondary)
                    Text(noteTitle)
                        .font(.subheadline)
                        .lineLimit(1)
                }
            }

            if !appState.accessibilityEnabled {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Accessibility permission required")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .onTapGesture {
                    AccessibilityHelper.openAccessibilitySettings()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Features")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 4)

            ToggleRow(
                icon: "number",
                title: "Markdown Shortcuts",
                isOn: Binding(
                    get: { appState.markdownEnabled },
                    set: { appState.markdownEnabled = $0 }
                )
            )

            ToggleRow(
                icon: "slash.circle",
                title: "Slash Commands",
                isOn: Binding(
                    get: { appState.slashCommandsEnabled },
                    set: { appState.slashCommandsEnabled = $0 }
                )
            )
        }
        .padding(.vertical, 4)
    }

    private var transcriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transcription")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 4)

            switch transcriptionService.state {
            case .idle:
                Button(action: startTranscription) {
                    HStack {
                        Image(systemName: "waveform")
                        Text("Transcribe Audio in Current Note")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .disabled(!appState.isNotesRunning)

            case .preparing:
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Preparing...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)

            case .transcribing(let progress):
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Transcribing...")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    ProgressView(value: progress)

                    Button("Cancel") {
                        transcriptionService.cancelTranscription()
                    }
                    .font(.caption)
                }
                .padding(.horizontal, 16)

            case .completed(let result):
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Transcription complete")
                            .font(.subheadline)
                    }
                    Text(result.text.prefix(100) + (result.text.count > 100 ? "..." : ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)

                    Button("Insert into Note") {
                        insertTranscription(result)
                    }
                    .font(.caption)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(.horizontal, 16)

            case .failed(let message):
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Transcription failed")
                            .font(.subheadline)
                    }
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 4)
    }

    private var footerSection: some View {
        HStack {
            Button(action: openSettings) {
                HStack {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .font(.subheadline)
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: quitApp) {
                HStack {
                    Text("Quit")
                    Image(systemName: "power")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func startTranscription() {
        Task {
            let attachments = await AudioDetectionService.shared.detectAudioAttachments()
            guard let firstAudio = attachments.first else {
                await MainActor.run {
                    appState.errorMessage = "No audio attachments found in the current note."
                }
                return
            }

            do {
                let audioURL = try await AudioDetectionService.shared.exportAudioFile(attachment: firstAudio)
                _ = try await transcriptionService.transcribe(
                    audioURL: audioURL,
                    language: appState.transcriptionLanguage
                )
            } catch {
                await MainActor.run {
                    appState.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func insertTranscription(_ result: TranscriptionResult) {
        Task {
            let success = await NotesService.shared.appendToCurrentNote(text: result.formattedForInsertion)
            if !success {
                await MainActor.run {
                    appState.errorMessage = "Failed to insert transcription into note."
                }
            }
        }
    }

    private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Toggle Row

private struct ToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.secondary)
            Text(title)
                .font(.subheadline)
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 2)
    }
}
