import Foundation
import Speech
import AVFoundation
import Combine

/// Service that handles audio transcription using Apple's Speech Framework.
final class TranscriptionService: ObservableObject {
    static let shared = TranscriptionService()

    @Published var state: TranscriptionState = .idle
    @Published var availableLanguages: [Locale] = []

    private var recognitionTask: SFSpeechRecognitionTask?

    private init() {
        loadAvailableLanguages()
    }

    // MARK: - Authorization

    /// Request speech recognition authorization from the user.
    func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    /// Check the current authorization status.
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus {
        SFSpeechRecognizer.authorizationStatus()
    }

    // MARK: - Transcription

    /// Transcribe an audio file at the given URL.
    /// - Parameters:
    ///   - url: Path to the audio file (.m4a, .mp3, .wav, etc.)
    ///   - language: BCP 47 language identifier (e.g., "zh-CN", "en-US")
    /// - Returns: The transcription result.
    func transcribe(audioURL url: URL, language: String) async throws -> TranscriptionResult {
        // Validate file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw TranscriptionError.fileNotFound
        }

        // Check authorization
        let status = await requestAuthorization()
        guard status == .authorized else {
            throw TranscriptionError.notAuthorized
        }

        // Create recognizer for the specified language
        let locale = Locale(identifier: language)
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw TranscriptionError.languageNotSupported(language)
        }

        // Get audio duration
        let duration = try await getAudioDuration(url: url)

        // Update state
        await MainActor.run {
            self.state = .preparing
        }

        // Create recognition request
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = true
        request.taskHint = .dictation

        // If available on macOS 14+, enable on-device recognition for privacy
        if #available(macOS 14, *) {
            request.requiresOnDeviceRecognition = false // Set true if device supports it
        }

        return try await withCheckedThrowingContinuation { continuation in
            var bestTranscription = ""
            var totalConfidence: Float = 0
            var segmentCount = 0

            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                if let error = error {
                    self?.updateState(.failed(error.localizedDescription))
                    continuation.resume(throwing: TranscriptionError.recognitionFailed(error.localizedDescription))
                    return
                }

                guard let result = result else { return }

                bestTranscription = result.bestTranscription.formattedString

                // Calculate progress based on segments
                for segment in result.bestTranscription.segments {
                    totalConfidence += segment.confidence
                    segmentCount += 1
                }

                // Estimate progress
                let progress = min(Double(result.bestTranscription.segments.count) / max(duration / 2.0, 1.0), 0.99)
                self?.updateState(.transcribing(progress: progress))

                if result.isFinal {
                    let avgConfidence = segmentCount > 0 ? Double(totalConfidence / Float(segmentCount)) : 0

                    let transcriptionResult = TranscriptionResult(
                        audioFileName: url.lastPathComponent,
                        text: bestTranscription,
                        language: language,
                        duration: duration,
                        confidence: avgConfidence
                    )

                    self?.updateState(.completed(transcriptionResult))
                    continuation.resume(returning: transcriptionResult)
                }
            }
        }
    }

    /// Cancel the current transcription task.
    func cancelTranscription() {
        recognitionTask?.cancel()
        recognitionTask = nil
        updateState(.idle)
    }

    // MARK: - Language Support

    /// Reload the list of available speech recognition languages.
    func loadAvailableLanguages() {
        let supportedLocales = SFSpeechRecognizer.supportedLocales()
        availableLanguages = Array(supportedLocales).sorted {
            ($0.identifier) < ($1.identifier)
        }
    }

    /// Get the display name for a language identifier.
    func displayName(for languageCode: String) -> String {
        let locale = Locale(identifier: languageCode)
        return Locale.current.localizedString(forIdentifier: locale.identifier) ?? languageCode
    }

    // MARK: - Private Helpers

    private func getAudioDuration(url: URL) async throws -> TimeInterval {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        return CMTimeGetSeconds(duration)
    }

    private func updateState(_ newState: TranscriptionState) {
        Task { @MainActor in
            self.state = newState
        }
    }
}

// MARK: - Errors

enum TranscriptionError: LocalizedError {
    case fileNotFound
    case notAuthorized
    case languageNotSupported(String)
    case recognitionFailed(String)
    case audioExportFailed

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Audio file not found."
        case .notAuthorized:
            return "Speech recognition is not authorized. Please enable it in System Settings > Privacy & Security > Speech Recognition."
        case .languageNotSupported(let lang):
            return "Language '\(lang)' is not supported for speech recognition on this device."
        case .recognitionFailed(let reason):
            return "Transcription failed: \(reason)"
        case .audioExportFailed:
            return "Failed to export audio from the note."
        }
    }
}
