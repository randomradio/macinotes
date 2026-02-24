import Foundation
import AppKit

/// Service responsible for detecting audio attachments in Apple Notes.
final class AudioDetectionService {
    static let shared = AudioDetectionService()

    private let supportedAudioExtensions = ["m4a", "mp3", "wav", "aac", "caf", "aiff"]

    private init() {}

    // MARK: - Detection

    /// Check if the current note contains audio attachments.
    func detectAudioAttachments() async -> [AudioAttachment] {
        let script = """
        tell application "Notes"
            try
                set theNote to selection
                if theNote is not {} then
                    set theAttachments to attachments of item 1 of theNote
                    set audioInfo to ""
                    repeat with att in theAttachments
                        set attName to name of att
                        set attID to id of att
                        set audioInfo to audioInfo & attName & "|" & attID & "\\n"
                    end repeat
                    return audioInfo
                end if
            end try
            return ""
        end tell
        """

        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else { return [] }

        let result = appleScript.executeAndReturnError(&error)
        guard let resultString = result?.stringValue, !resultString.isEmpty else { return [] }

        return parseAttachments(resultString)
    }

    /// Export a specific audio attachment to a temporary file.
    func exportAudioFile(attachment: AudioAttachment) async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("NotesPlus_Audio", isDirectory: true)

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let outputURL = tempDir.appendingPathComponent(attachment.fileName)

        // If already exported, return existing file
        if FileManager.default.fileExists(atPath: outputURL.path) {
            return outputURL
        }

        // Use AppleScript to attempt to export the attachment
        // Note: Direct audio export from Notes is limited; this uses a workaround
        let script = """
        tell application "Notes"
            try
                set theNote to selection
                if theNote is not {} then
                    set theAttachments to attachments of item 1 of theNote
                    repeat with att in theAttachments
                        if name of att is "\(attachment.fileName)" then
                            -- Attempt to access the attachment data
                            return POSIX path of (att as alias)
                        end if
                    end repeat
                end if
            end try
            return ""
        end tell
        """

        let resultPath = await runAppleScript(script)

        if let path = resultPath, !path.isEmpty {
            let sourceURL = URL(fileURLWithPath: path)
            try FileManager.default.copyItem(at: sourceURL, to: outputURL)
            return outputURL
        }

        throw TranscriptionError.audioExportFailed
    }

    /// Clean up temporary audio files.
    func cleanupTemporaryFiles() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("NotesPlus_Audio", isDirectory: true)

        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Private Helpers

    private func parseAttachments(_ raw: String) -> [AudioAttachment] {
        raw.components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .compactMap { line -> AudioAttachment? in
                let parts = line.components(separatedBy: "|")
                guard parts.count >= 2 else { return nil }

                let fileName = parts[0].trimmingCharacters(in: .whitespaces)
                let id = parts[1].trimmingCharacters(in: .whitespaces)

                let ext = (fileName as NSString).pathExtension.lowercased()
                guard supportedAudioExtensions.contains(ext) else { return nil }

                return AudioAttachment(id: id, fileName: fileName, fileExtension: ext)
            }
    }

    private func runAppleScript(_ source: String) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                let script = NSAppleScript(source: source)
                let result = script?.executeAndReturnError(&error)
                continuation.resume(returning: result?.stringValue)
            }
        }
    }
}

// MARK: - AudioAttachment Model

struct AudioAttachment: Identifiable, Hashable {
    let id: String
    let fileName: String
    let fileExtension: String

    var displayName: String {
        (fileName as NSString).deletingPathExtension
    }

    var iconName: String {
        switch fileExtension {
        case "m4a", "aac": return "waveform"
        case "mp3": return "music.note"
        case "wav", "aiff": return "waveform.circle"
        default: return "speaker.wave.2"
        }
    }
}
