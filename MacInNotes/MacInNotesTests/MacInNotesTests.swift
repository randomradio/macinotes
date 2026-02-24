import XCTest
@testable import MacInNotes

final class MacInNotesTests: XCTestCase {

    // MARK: - MarkdownTrigger Tests

    func testMarkdownTriggerMatchTitle() {
        let result = MarkdownTrigger.match(linePrefix: "#")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.format, .title)
    }

    func testMarkdownTriggerMatchHeading() {
        let result = MarkdownTrigger.match(linePrefix: "##")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.format, .heading)
    }

    func testMarkdownTriggerMatchSubheading() {
        let result = MarkdownTrigger.match(linePrefix: "###")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.format, .subheading)
    }

    func testMarkdownTriggerMatchChecklist() {
        let result = MarkdownTrigger.match(linePrefix: "[]")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.format, .checklist)
    }

    func testMarkdownTriggerMatchCodeBlock() {
        let result = MarkdownTrigger.match(linePrefix: "```")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.format, .monospaced)
    }

    func testMarkdownTriggerMatchBlockQuote() {
        let result = MarkdownTrigger.match(linePrefix: ">")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.format, .blockQuote)
    }

    func testMarkdownTriggerMatchDashedList() {
        let result = MarkdownTrigger.match(linePrefix: "-")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.format, .dashedList)
    }

    func testMarkdownTriggerMatchBulletList() {
        let result = MarkdownTrigger.match(linePrefix: "*")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.format, .bulletList)
    }

    func testMarkdownTriggerMatchNumberedList() {
        let result = MarkdownTrigger.match(linePrefix: "1.")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.format, .numberedList)
    }

    func testMarkdownTriggerNoMatch() {
        let result = MarkdownTrigger.match(linePrefix: "hello")
        XCTAssertNil(result)
    }

    func testMarkdownTriggerTrimsWhitespace() {
        let result = MarkdownTrigger.match(linePrefix: "  # ")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.format, .title)
    }

    func testLongestPatternMatchesFirst() {
        // "###" should match subheading, not title
        let result = MarkdownTrigger.match(linePrefix: "###")
        XCTAssertEqual(result?.format, .subheading)

        // "##" should match heading, not title
        let result2 = MarkdownTrigger.match(linePrefix: "##")
        XCTAssertEqual(result2?.format, .heading)
    }

    // MARK: - SlashCommand Tests

    func testSlashCommandMatchByName() {
        let command = SlashCommand.allCommands.first { $0.id == "title" }!
        XCTAssertTrue(command.matches(query: "title"))
        XCTAssertTrue(command.matches(query: "tit"))
        XCTAssertTrue(command.matches(query: "TITLE"))
    }

    func testSlashCommandMatchByAlias() {
        let command = SlashCommand.allCommands.first { $0.id == "title" }!
        XCTAssertTrue(command.matches(query: "h1"))
    }

    func testSlashCommandNoMatch() {
        let command = SlashCommand.allCommands.first { $0.id == "title" }!
        XCTAssertFalse(command.matches(query: "xyz"))
    }

    func testAllCommandsHaveUniqueIDs() {
        let ids = SlashCommand.allCommands.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Slash command IDs must be unique")
    }

    // MARK: - TranscriptionResult Tests

    func testTranscriptionResultFormattedForInsertion() {
        let result = TranscriptionResult(
            audioFileName: "test.m4a",
            text: "Hello, world!",
            language: "en-US",
            duration: 5.0
        )

        let formatted = result.formattedForInsertion
        XCTAssertTrue(formatted.contains("Hello, world!"))
        XCTAssertTrue(formatted.contains("Transcription"))
    }

    // MARK: - String Extension Tests

    func testLinePrefixAtPosition() {
        let text = "Hello\nWorld\nFoo"
        let prefix = text.linePrefix(at: 8)
        XCTAssertEqual(prefix, "Wo")
    }

    func testIsAudioFileExtension() {
        XCTAssertTrue("m4a".isAudioFileExtension)
        XCTAssertTrue("mp3".isAudioFileExtension)
        XCTAssertTrue("wav".isAudioFileExtension)
        XCTAssertFalse("txt".isAudioFileExtension)
        XCTAssertFalse("pdf".isAudioFileExtension)
    }

    func testAppleScriptEscaped() {
        let input = "He said \"hello\""
        let escaped = input.appleScriptEscaped
        XCTAssertEqual(escaped, "He said \\\"hello\\\"")
    }

    // MARK: - AudioAttachment Tests

    func testAudioAttachmentDisplayName() {
        let attachment = AudioAttachment(id: "1", fileName: "Recording.m4a", fileExtension: "m4a")
        XCTAssertEqual(attachment.displayName, "Recording")
    }

    func testAudioAttachmentIconName() {
        let m4a = AudioAttachment(id: "1", fileName: "a.m4a", fileExtension: "m4a")
        XCTAssertEqual(m4a.iconName, "waveform")

        let mp3 = AudioAttachment(id: "2", fileName: "b.mp3", fileExtension: "mp3")
        XCTAssertEqual(mp3.iconName, "music.note")

        let wav = AudioAttachment(id: "3", fileName: "c.wav", fileExtension: "wav")
        XCTAssertEqual(wav.iconName, "waveform.circle")
    }

    // MARK: - URL Extension Tests

    func testURLIsAudioFile() {
        XCTAssertTrue(URL(fileURLWithPath: "/tmp/test.m4a").isAudioFile)
        XCTAssertTrue(URL(fileURLWithPath: "/tmp/test.mp3").isAudioFile)
        XCTAssertFalse(URL(fileURLWithPath: "/tmp/test.txt").isAudioFile)
    }

    // MARK: - NotesFormat Tests

    func testNotesFormatDisplayNames() {
        XCTAssertEqual(NotesFormat.title.displayName, "Title")
        XCTAssertEqual(NotesFormat.heading.displayName, "Heading")
        XCTAssertEqual(NotesFormat.subheading.displayName, "Subheading")
        XCTAssertEqual(NotesFormat.monospaced.displayName, "Monospaced")
        XCTAssertEqual(NotesFormat.checklist.displayName, "Checklist")
        XCTAssertEqual(NotesFormat.bulletList.displayName, "Bulleted List")
        XCTAssertEqual(NotesFormat.numberedList.displayName, "Numbered List")
        XCTAssertEqual(NotesFormat.blockQuote.displayName, "Block Quote")
    }
}
