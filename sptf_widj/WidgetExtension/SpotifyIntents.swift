import AppIntents
import WidgetKit

struct PlayPauseIntent: AppIntent {
    static var title: LocalizedStringResource = "Play/Pause Spotify"
    static var description = IntentDescription("Toggle play/pause in Spotify")

    func perform() async throws -> some IntentResult {
        runAppleScript(#"tell application "Spotify" to playpause"#)
        try? await Task.sleep(for: .milliseconds(400))
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct NextTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Track"
    static var description = IntentDescription("Skip to next track in Spotify")

    func perform() async throws -> some IntentResult {
        runAppleScript(#"tell application "Spotify" to next track"#)
        try? await Task.sleep(for: .milliseconds(600))
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct PreviousTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous Track"
    static var description = IntentDescription("Go to previous track in Spotify")

    func perform() async throws -> some IntentResult {
        runAppleScript(#"tell application "Spotify" to previous track"#)
        try? await Task.sleep(for: .milliseconds(600))
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct SpotifyWidgetConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Spotify Now Playing"
    static var description = IntentDescription("Shows currently playing track from Spotify")
}

private func runAppleScript(_ source: String) {
    var error: NSDictionary?
    guard let script = NSAppleScript(source: source) else { return }
    script.executeAndReturnError(&error)
}
