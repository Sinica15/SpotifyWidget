import Foundation

struct TrackInfo {
    let name: String
    let artist: String
    let album: String
    let artworkURL: String?
    let isPlaying: Bool
    let duration: Double
    let position: Double
}

enum SpotifyBridge {

    private static let delimiter = "|||"

    static func getCurrentTrack() -> TrackInfo? {
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

        guard let output = runScript(script),
              output != "NOT_RUNNING",
              output != "STOPPED",
              output != "ERROR" else {
            return nil
        }

        let parts = output.components(separatedBy: delimiter)
        guard parts.count >= 7 else { return nil }

        return TrackInfo(
            name: parts[0],
            artist: parts[1],
            album: parts[2],
            artworkURL: (parts[3].isEmpty || parts[3] == "missing value") ? nil : parts[3],
            isPlaying: parts[6] == "PLAYING",
            duration: (Double(parts[4]) ?? 0) / 1000.0,
            position: Double(parts[5]) ?? 0
        )
    }

    static func playPause() {
        runScript(#"tell application "Spotify" to playpause"#)
    }

    static func nextTrack() {
        runScript(#"tell application "Spotify" to next track"#)
    }

    static func previousTrack() {
        runScript(#"tell application "Spotify" to previous track"#)
    }

    @discardableResult
    private static func runScript(_ source: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", source]

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        guard process.terminationStatus == 0 else { return nil }
        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
