import Foundation

/// App-wide constants.
enum Constants {
    /// App metadata.
    enum App {
        static let name = "NotesPlus"
        static let version = "1.0.0"
        static let bundleIdentifier = "com.notesplus.app"
        static let minimumMacOSVersion = "13.0"
    }

    /// UserDefaults keys.
    enum UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let markdownEnabled = "markdownEnabled"
        static let slashCommandsEnabled = "slashCommandsEnabled"
        static let transcriptionLanguage = "transcriptionLanguage"
        static let launchAtLogin = "launchAtLogin"
        static let autoInsertTranscription = "autoInsertTranscription"
        static let includeTimestamp = "includeTimestamp"
    }

    /// Apple Notes bundle identifier.
    enum Notes {
        static let bundleIdentifier = "com.apple.Notes"
    }

    /// Supported audio formats for transcription.
    enum Audio {
        static let supportedExtensions = ["m4a", "mp3", "wav", "aac", "caf", "aiff"]
        static let tempDirectoryName = "NotesPlus_Audio"
    }

    /// Default transcription settings.
    enum Transcription {
        static let defaultLanguage = "zh-CN"
        static let maxDurationAppleSpeech: TimeInterval = 60 // ~1 minute limit for Apple Speech
    }
}
