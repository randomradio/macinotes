# NotesPlus

A macOS native app that enhances Apple Notes with Markdown shortcuts, slash commands, and audio transcription.

## Features

### Markdown Shortcuts
Type Markdown syntax at the start of a line followed by Space to auto-convert:

| Input | Result |
|-------|--------|
| `#` + Space | Title |
| `##` + Space | Heading |
| `###` + Space | Subheading |
| `[]` + Space | Checklist |
| `` ``` `` + Space | Monospaced |
| `>` + Space | Block Quote |
| `-` + Space | Dashed List |
| `*` + Space | Bulleted List |
| `1.` + Space | Numbered List |

### Slash Commands
Type `/` at the start of a line to open the command menu:

- `/title` or `/h1` — Large title
- `/heading` or `/h2` — Heading
- `/subheading` or `/h3` — Subheading
- `/code` — Monospaced block
- `/checklist` — Checklist item
- `/table` — Insert table
- `/divider` — Horizontal divider
- `/timestamp` — Current date/time

### Audio Transcription
Transcribe audio attachments in your notes to editable text using Apple Speech Framework:

- Detects audio attachments (.m4a, .mp3, .wav, etc.)
- Supports Chinese, English, Japanese, Korean, and many more languages
- Results are automatically inserted below the audio in your note

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac
- Accessibility permission (required for Markdown/slash commands)
- Speech Recognition permission (required for transcription)

## Building

### Prerequisites

- Xcode 15.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (for generating the Xcode project)

### Setup

```bash
# Install XcodeGen if needed
brew install xcodegen

# Generate the Xcode project
cd NotesPlus
xcodegen generate

# Open in Xcode
open NotesPlus.xcodeproj
```

Then build and run with `Cmd+R` in Xcode.

### Without XcodeGen

You can also create a new Xcode project manually:

1. Create a new macOS App project in Xcode (SwiftUI, Swift)
2. Copy all files from `NotesPlus/` into the project
3. Add `Info.plist` and `NotesPlus.entitlements` to the target
4. Set deployment target to macOS 13.0

## Architecture

```
NotesPlus/
├── App/
│   ├── NotesPlusApp.swift          # SwiftUI App entry point
│   ├── AppDelegate.swift           # Menu bar setup, service lifecycle
│   └── AppState.swift              # Global observable state
├── Models/
│   ├── SlashCommand.swift          # Command definitions
│   ├── MarkdownTrigger.swift       # Markdown syntax patterns
│   ├── TranscriptionResult.swift   # Transcription data model
│   └── KeyboardEvent.swift         # Keyboard event types
├── Services/
│   ├── NotesService.swift          # Apple Notes integration (AX + AppleScript)
│   ├── KeyboardMonitor.swift       # Global keyboard event tap
│   ├── MarkdownService.swift       # Markdown → Notes format conversion
│   ├── SlashCommandService.swift   # Slash command menu and execution
│   ├── TranscriptionService.swift  # Apple Speech Framework wrapper
│   └── AudioDetectionService.swift # Audio attachment detection
├── Views/
│   ├── MenuBarView.swift           # Status bar popover
│   ├── SettingsView.swift          # Preferences window
│   ├── SlashCommandPopoverView.swift
│   ├── OnboardingView.swift        # First-run permission setup
│   └── TranscriptionView.swift     # Transcription management
├── Utilities/
│   ├── Constants.swift             # App-wide constants
│   ├── AccessibilityHelper.swift   # Permission management
│   └── Extensions.swift            # Swift extensions
└── Resources/
    ├── Info.plist
    ├── NotesPlus.entitlements
    └── Assets.xcassets/
```

## Technical Notes

- **Menu bar app**: Runs as a status bar item (`LSUIElement = true`), no dock icon
- **Accessibility API**: Uses `AXUIElement` to read/write text in the Notes editor
- **AppleScript**: Used for note metadata, audio attachment detection, and format application via System Events
- **Keyboard monitoring**: Global `CGEventTap` (listen-only) to detect Markdown triggers and slash commands
- **Speech Framework**: `SFSpeechRecognizer` with `SFSpeechURLRecognitionRequest` for file-based transcription

## License

Copyright 2026 NotesPlus. All rights reserved.
