import SwiftUI

@main
struct NotesPlusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(appState)
        }

        Window("Onboarding", id: "onboarding") {
            OnboardingView()
                .environmentObject(appState)
                .frame(width: 520, height: 460)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
