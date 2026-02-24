import SwiftUI

/// App settings/preferences view.
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var transcriptionService = TranscriptionService.shared

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            markdownTab
                .tabItem {
                    Label("Markdown", systemImage: "number")
                }

            transcriptionTab
                .tabItem {
                    Label("Transcription", systemImage: "waveform")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 480, height: 360)
    }

    // MARK: - General Tab

    private var generalTab: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: .constant(false))
                Toggle("Show in menu bar", isOn: .constant(true))
                    .disabled(true)
            }

            Section("Permissions") {
                HStack {
                    Image(systemName: appState.accessibilityEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(appState.accessibilityEnabled ? .green : .red)
                    Text("Accessibility")
                    Spacer()
                    if !appState.accessibilityEnabled {
                        Button("Open Settings") {
                            AccessibilityHelper.openAccessibilitySettings()
                        }
                        .controlSize(.small)
                    }
                }

                HStack {
                    let speechStatus = transcriptionService.authorizationStatus
                    Image(systemName: speechStatus == .authorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(speechStatus == .authorized ? .green : .red)
                    Text("Speech Recognition")
                    Spacer()
                    if speechStatus != .authorized {
                        Button("Request") {
                            Task {
                                _ = await transcriptionService.requestAuthorization()
                            }
                        }
                        .controlSize(.small)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Markdown Tab

    private var markdownTab: some View {
        Form {
            Section("Markdown Shortcuts") {
                Toggle("Enable Markdown conversion", isOn: $appState.markdownEnabled)

                if appState.markdownEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Supported syntax:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ForEach(MarkdownTrigger.allTriggers, id: \.pattern) { trigger in
                            HStack {
                                Text(trigger.pattern + " + Space")
                                    .font(.system(.body, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.15))
                                    .cornerRadius(4)

                                Image(systemName: "arrow.right")
                                    .foregroundColor(.secondary)

                                Text(trigger.format.displayName)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }

            Section("Slash Commands") {
                Toggle("Enable slash commands", isOn: $appState.slashCommandsEnabled)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Transcription Tab

    private var transcriptionTab: some View {
        Form {
            Section("Language") {
                Picker("Recognition language", selection: $appState.transcriptionLanguage) {
                    ForEach(commonLanguages, id: \.code) { lang in
                        Text(lang.name).tag(lang.code)
                    }
                }
            }

            Section("Engine") {
                HStack {
                    Image(systemName: "apple.logo")
                    VStack(alignment: .leading) {
                        Text("Apple Speech Framework")
                            .font(.subheadline)
                        Text("Built-in, free, privacy-focused. Best for short recordings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }

                HStack {
                    Image(systemName: "cloud")
                    VStack(alignment: .leading) {
                        Text("Whisper API")
                            .font(.subheadline)
                        Text("Higher accuracy, supports long audio. Requires API key.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("Coming Soon")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }
            }

            Section("Behavior") {
                Toggle("Auto-insert transcription into note", isOn: .constant(true))
                Toggle("Include timestamp with transcription", isOn: .constant(true))
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("MacInNotes")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Enhance Apple Notes with Markdown,\nslash commands, and audio transcription.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Spacer()

            Text("Built with Swift and SwiftUI")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Common Languages

    private var commonLanguages: [(code: String, name: String)] {
        [
            ("zh-CN", "Chinese (Simplified)"),
            ("zh-TW", "Chinese (Traditional)"),
            ("en-US", "English (US)"),
            ("en-GB", "English (UK)"),
            ("ja-JP", "Japanese"),
            ("ko-KR", "Korean"),
            ("fr-FR", "French"),
            ("de-DE", "German"),
            ("es-ES", "Spanish"),
            ("pt-BR", "Portuguese (Brazil)"),
            ("it-IT", "Italian"),
            ("ru-RU", "Russian"),
        ]
    }
}
