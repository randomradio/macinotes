import SwiftUI

/// Detailed transcription view for managing audio transcription from notes.
struct TranscriptionView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var transcriptionService = TranscriptionService.shared
    @State private var audioAttachments: [AudioAttachment] = []
    @State private var transcriptionResults: [TranscriptionResult] = []
    @State private var isScanning = false

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Audio Transcription")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: scanForAudio) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Scan Note")
                    }
                }
                .disabled(!appState.isNotesRunning || isScanning)
            }

            // Audio attachments list
            if audioAttachments.isEmpty {
                emptyState
            } else {
                audioList
            }

            // Transcription progress
            if case .transcribing(let progress) = transcriptionService.state {
                VStack(spacing: 8) {
                    ProgressView(value: progress)
                    HStack {
                        Text("Transcribing...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
            }

            // Results
            if !transcriptionResults.isEmpty {
                resultsList
            }
        }
        .padding()
        .onAppear {
            scanForAudio()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.slash")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("No audio attachments found")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if !appState.isNotesRunning {
                Text("Open Apple Notes to get started")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }

    // MARK: - Audio List

    private var audioList: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Found \(audioAttachments.count) audio file(s)")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(audioAttachments) { attachment in
                HStack {
                    Image(systemName: attachment.iconName)
                        .foregroundColor(.accentColor)

                    Text(attachment.displayName)
                        .font(.subheadline)
                        .lineLimit(1)

                    Spacer()

                    Button("Transcribe") {
                        transcribeAttachment(attachment)
                    }
                    .controlSize(.small)
                    .disabled(transcriptionService.state != .idle)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(6)
            }
        }
    }

    // MARK: - Results List

    private var resultsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transcriptions")
                .font(.subheadline)
                .fontWeight(.medium)

            ForEach(transcriptionResults) { result in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(result.audioFileName)
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                        Text(String(format: "%.0f%%", result.confidence * 100))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Text(result.text)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(5)

                    HStack {
                        Button("Copy") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(result.text, forType: .string)
                        }
                        .controlSize(.mini)

                        Button("Insert into Note") {
                            Task {
                                _ = await NotesService.shared.appendToCurrentNote(
                                    text: result.formattedForInsertion
                                )
                            }
                        }
                        .controlSize(.mini)
                    }
                }
                .padding(10)
                .background(Color.green.opacity(0.05))
                .cornerRadius(6)
            }
        }
    }

    // MARK: - Actions

    private func scanForAudio() {
        isScanning = true
        Task {
            audioAttachments = await AudioDetectionService.shared.detectAudioAttachments()
            isScanning = false
        }
    }

    private func transcribeAttachment(_ attachment: AudioAttachment) {
        Task {
            do {
                let audioURL = try await AudioDetectionService.shared.exportAudioFile(attachment: attachment)
                let result = try await transcriptionService.transcribe(
                    audioURL: audioURL,
                    language: appState.transcriptionLanguage
                )
                transcriptionResults.append(result)
            } catch {
                await MainActor.run {
                    appState.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
