import Foundation
import AppKit

// MARK: - String Extensions

extension String {
    /// Returns the text before the cursor position on the current line.
    func linePrefix(at position: Int) -> String {
        let nsString = self as NSString
        guard position <= nsString.length else { return "" }

        let lineRange = nsString.lineRange(for: NSRange(location: position, length: 0))
        let prefixRange = NSRange(location: lineRange.location, length: position - lineRange.location)

        guard prefixRange.location + prefixRange.length <= nsString.length else { return "" }
        return nsString.substring(with: prefixRange)
    }

    /// Check if the string is a supported audio file extension.
    var isAudioFileExtension: Bool {
        Constants.Audio.supportedExtensions.contains(self.lowercased())
    }

    /// Escape special characters for AppleScript string literals.
    var appleScriptEscaped: String {
        self.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}

// MARK: - NSRange Extensions

extension NSRange {
    /// Create an NSRange that covers the start of the range with the given length.
    func prefix(_ length: Int) -> NSRange {
        NSRange(location: location, length: min(length, self.length))
    }
}

// MARK: - Date Extensions

extension Date {
    /// Format the date for display in transcription results.
    var transcriptionTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - URL Extensions

extension URL {
    /// Check if this URL points to a supported audio file.
    var isAudioFile: Bool {
        pathExtension.isAudioFileExtension
    }
}

// MARK: - View Extensions

import SwiftUI

extension View {
    /// Apply a conditional modifier.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
