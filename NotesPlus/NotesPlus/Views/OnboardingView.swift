import SwiftUI

/// First-run onboarding view that guides users through permission setup.
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @Environment(\.dismiss) private var dismiss

    private let steps = [
        OnboardingStep(
            icon: "hand.wave",
            title: "Welcome to NotesPlus",
            description: "Enhance Apple Notes with Markdown shortcuts, slash commands, and audio transcription.",
            actionLabel: nil
        ),
        OnboardingStep(
            icon: "lock.shield",
            title: "Accessibility Permission",
            description: "NotesPlus needs Accessibility access to read and format text in Apple Notes. This is required for Markdown shortcuts and slash commands to work.",
            actionLabel: "Open Accessibility Settings"
        ),
        OnboardingStep(
            icon: "waveform",
            title: "Speech Recognition",
            description: "To transcribe audio recordings in your notes, NotesPlus needs permission to use Speech Recognition. This is optional — you can enable it later.",
            actionLabel: "Enable Speech Recognition"
        ),
        OnboardingStep(
            icon: "checkmark.circle",
            title: "You're All Set!",
            description: "NotesPlus is ready. Look for the icon in your menu bar. Open Apple Notes and start typing Markdown or slash commands!",
            actionLabel: nil
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 24)

            Spacer()

            // Step content
            VStack(spacing: 20) {
                Image(systemName: steps[currentStep].icon)
                    .font(.system(size: 56))
                    .foregroundColor(.accentColor)
                    .frame(height: 70)

                Text(steps[currentStep].title)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(steps[currentStep].description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)

                // Permission action button
                if let actionLabel = steps[currentStep].actionLabel {
                    Button(action: performStepAction) {
                        Text(actionLabel)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.top, 8)
                }

                // Permission status
                if currentStep == 1 {
                    HStack {
                        Image(systemName: appState.accessibilityEnabled ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundColor(appState.accessibilityEnabled ? .green : .orange)
                        Text(appState.accessibilityEnabled ? "Permission granted" : "Permission not yet granted")
                            .font(.caption)
                            .foregroundColor(appState.accessibilityEnabled ? .green : .orange)
                    }
                }
            }

            Spacer()

            // Navigation buttons
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if currentStep < steps.count - 1 {
                    Button(currentStep == 0 ? "Get Started" : "Next") {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Done") {
                        appState.hasCompletedOnboarding = true
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .frame(width: 520, height: 460)
    }

    private func performStepAction() {
        switch currentStep {
        case 1:
            AccessibilityHelper.openAccessibilitySettings()
        case 2:
            Task {
                _ = await TranscriptionService.shared.requestAuthorization()
            }
        default:
            break
        }
    }
}

// MARK: - Onboarding Step Model

private struct OnboardingStep {
    let icon: String
    let title: String
    let description: String
    let actionLabel: String?
}
