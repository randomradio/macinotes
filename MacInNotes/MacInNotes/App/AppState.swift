import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    // MARK: - Published State

    @Published var isNotesRunning = false
    @Published var accessibilityEnabled = false
    @Published var currentNoteTitle: String?
    @Published var isTranscribing = false
    @Published var transcriptionProgress: Double = 0
    @Published var lastTranscriptionResult: String?
    @Published var errorMessage: String?

    // MARK: - Settings

    @AppStorage(Constants.UserDefaultsKeys.markdownEnabled)
    var markdownEnabled = true

    @AppStorage(Constants.UserDefaultsKeys.slashCommandsEnabled)
    var slashCommandsEnabled = true

    @AppStorage(Constants.UserDefaultsKeys.transcriptionLanguage)
    var transcriptionLanguage = "zh-CN"

    @AppStorage(Constants.UserDefaultsKeys.hasCompletedOnboarding)
    var hasCompletedOnboarding = false

    // MARK: - Methods

    func refreshNotesStatus() async {
        isNotesRunning = NotesService.shared.isNotesRunning()
        if isNotesRunning {
            currentNoteTitle = await NotesService.shared.getCurrentNoteTitle()
        } else {
            currentNoteTitle = nil
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
