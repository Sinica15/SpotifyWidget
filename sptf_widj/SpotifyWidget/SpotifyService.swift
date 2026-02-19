import Foundation
import Observation
import WidgetKit

@Observable
class SpotifyService {
    static let shared = SpotifyService()
    static let suiteName = "com.sptfwidj.shared"

    var trackName: String = "—"
    var trackArtist: String = ""
    var isPlaying: Bool = false
    var artworkURL: String?
    var isConnected: Bool = false

    private var timer: Timer?

    func start() {
        poll()
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.poll()
        }

        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(forName: .init("com.sptfwidj.playpause"), object: nil, queue: .main) { [weak self] _ in
            self?.executeCommand(#"tell application "Spotify" to playpause"#, delay: 0.3)
        }
        dnc.addObserver(forName: .init("com.sptfwidj.next"), object: nil, queue: .main) { [weak self] _ in
            self?.executeCommand(#"tell application "Spotify" to next track"#, delay: 0.5)
        }
        dnc.addObserver(forName: .init("com.sptfwidj.previous"), object: nil, queue: .main) { [weak self] _ in
            self?.executeCommand(#"tell application "Spotify" to previous track"#, delay: 0.5)
        }
    }

    private func executeCommand(_ script: String, delay: TimeInterval) {
        runAppleScript(script)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.poll()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func playPause() {
        runAppleScript(#"tell application "Spotify" to playpause"#)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.poll()
        }
    }

    func next() {
        runAppleScript(#"tell application "Spotify" to next track"#)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.poll()
        }
    }

    func previous() {
        runAppleScript(#"tell application "Spotify" to previous track"#)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.poll()
        }
    }

    func poll() {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                try
                    if player state is stopped then
                        return "STOPPED"
                    end if
                    set trackName to name of current track
                    set trackArtist to artist of current track
                    set trackAlbum to album of current track
                    try
                        set artURL to artwork url of current track
                    on error
                        set artURL to ""
                    end try
                    set trackDur to duration of current track
                    set trackPos to player position
                    if player state is playing then
                        set pState to "PLAYING"
                    else
                        set pState to "PAUSED"
                    end if
                    return trackName & "|||" & trackArtist & "|||" & trackAlbum & "|||" & artURL & "|||" & (trackDur as string) & "|||" & (trackPos as string) & "|||" & pState
                on error
                    return "ERROR"
                end try
            end tell
        else
            return "NOT_RUNNING"
        end if
        """

        guard let output = runAppleScript(script),
              output != "NOT_RUNNING",
              output != "STOPPED",
              output != "ERROR" else {
            writeToWidgetContainer(nil)
            DispatchQueue.main.async {
                self.isConnected = false
                self.trackName = "—"
                self.trackArtist = ""
                self.isPlaying = false
                self.artworkURL = nil
            }
            return
        }

        let parts = output.components(separatedBy: "|||")
        guard parts.count >= 7 else { return }

        let name = parts[0]
        let artist = parts[1]
        let album = parts[2]
        let artURL = parts[3]
        let playing = parts[6] == "PLAYING"

        let data: [String: Any] = [
            "name": name,
            "artist": artist,
            "album": album,
            "artworkURL": artURL,
            "isPlaying": playing,
            "duration": (Double(parts[4]) ?? 0) / 1000.0,
            "position": Double(parts[5]) ?? 0,
            "timestamp": Date().timeIntervalSince1970
        ]

        writeToWidgetContainer(data)

        DispatchQueue.main.async {
            self.isConnected = true
            self.trackName = name
            self.trackArtist = artist
            self.isPlaying = playing
            self.artworkURL = (artURL.isEmpty || artURL == "missing value") ? nil : artURL
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    private func writeToWidgetContainer(_ trackData: [String: Any]?) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let prefsDir = home
            .appendingPathComponent("Library/Containers/com.sptfwidj.app.widget/Data/Library/Preferences")
        let plistURL = prefsDir.appendingPathComponent("com.sptfwidj.shared.plist")

        if let trackData {
            try? FileManager.default.createDirectory(at: prefsDir, withIntermediateDirectories: true)
            let wrapper: NSDictionary = ["trackData": trackData]
            wrapper.write(to: plistURL, atomically: true)
        } else {
            try? FileManager.default.removeItem(at: plistURL)
        }
    }

    @discardableResult
    private func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let result = script.executeAndReturnError(&error)
        if error != nil { return nil }
        return result.stringValue
    }
}
