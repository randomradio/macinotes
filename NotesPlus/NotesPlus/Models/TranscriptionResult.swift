import Foundation

/// Result of an audio transcription operation.
struct TranscriptionResult: Identifiable {
    let id: UUID
    let audioFileName: String
    let text: String
    let language: String
    let duration: TimeInterval
    let timestamp: Date
    let confidence: Double

    init(
        id: UUID = UUID(),
        audioFileName: String,
        text: String,
        language: String,
        duration: TimeInterval,
        timestamp: Date = Date(),
        confidence: Double = 0
    ) {
        self.id = id
        self.audioFileName = audioFileName
        self.text = text
        self.language = language
        self.duration = duration
        self.timestamp = timestamp
        self.confidence = confidence
    }

    /// Formatted text ready for insertion into Notes.
    var formattedForInsertion: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        return """
        --- Transcription (\(dateFormatter.string(from: timestamp))) ---
        \(text)
        ---
        """
    }
}

/// Represents the current state of a transcription task.
enum TranscriptionState: Equatable {
    case idle
    case preparing
    case transcribing(progress: Double)
    case completed(TranscriptionResult)
    case failed(String)

    static func == (lhs: TranscriptionState, rhs: TranscriptionState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.preparing, .preparing): return true
        case (.transcribing(let a), .transcribing(let b)): return a == b
        case (.completed(let a), .completed(let b)): return a.id == b.id
        case (.failed(let a), .failed(let b)): return a == b
        default: return false
        }
    }
}
