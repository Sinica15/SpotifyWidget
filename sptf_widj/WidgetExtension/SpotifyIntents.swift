import AppIntents
import WidgetKit

struct PlayPauseIntent: AppIntent {
    static var title: LocalizedStringResource = "Play/Pause Spotify"
    static var description = IntentDescription("Toggle play/pause in Spotify")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        SpotifyBridge.playPause()
        try? await Task.sleep(for: .milliseconds(500))
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct NextTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Track"
    static var description = IntentDescription("Skip to next track in Spotify")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        SpotifyBridge.nextTrack()
        try? await Task.sleep(for: .milliseconds(1000))
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct PreviousTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous Track"
    static var description = IntentDescription("Go to previous track in Spotify")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        SpotifyBridge.previousTrack()
        try? await Task.sleep(for: .milliseconds(1000))
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct SpotifyWidgetConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Spotify Now Playing"
    static var description = IntentDescription("Shows currently playing track from Spotify")
}
