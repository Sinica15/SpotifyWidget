import WidgetKit
import SwiftUI
import AppIntents
import AppKit

// MARK: - Timeline Entry

struct NowPlayingEntry: TimelineEntry {
    let date: Date
    let trackInfo: TrackInfo?
    let artworkData: Data?

    static var placeholder: NowPlayingEntry {
        NowPlayingEntry(
            date: Date(),
            trackInfo: TrackInfo(
                name: "Track Name",
                artist: "Artist",
                album: "Album",
                artworkURL: nil,
                isPlaying: true,
                duration: 240,
                position: 60
            ),
            artworkData: nil
        )
    }

    static var empty: NowPlayingEntry {
        NowPlayingEntry(date: Date(), trackInfo: nil, artworkData: nil)
    }
}

// MARK: - Timeline Provider

struct NowPlayingProvider: AppIntentTimelineProvider {
    typealias Entry = NowPlayingEntry
    typealias Intent = SpotifyWidgetConfigIntent

    static let suiteName = "com.sptfwidj.shared"

    func placeholder(in context: Context) -> NowPlayingEntry {
        .placeholder
    }

    func snapshot(for configuration: SpotifyWidgetConfigIntent, in context: Context) async -> NowPlayingEntry {
        await fetchEntry()
    }

    func timeline(for configuration: SpotifyWidgetConfigIntent, in context: Context) async -> Timeline<NowPlayingEntry> {
        let entry = await fetchEntry()
        let interval: TimeInterval = entry.trackInfo != nil ? 15 : 30
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(interval)))
    }

    private func fetchEntry() async -> NowPlayingEntry {
        let plistPath = NSHomeDirectory() + "/Library/Preferences/com.sptfwidj.shared.plist"

        guard let plist = NSDictionary(contentsOfFile: plistPath) as? [String: Any],
              let data = plist["trackData"] as? [String: Any],
              let name = data["name"] as? String,
              let artist = data["artist"] as? String else {
            return .empty
        }

        let artworkURLString: String? = {
            let url = data["artworkURL"] as? String ?? ""
            return (url.isEmpty || url == "missing value") ? nil : url
        }()

        let trackInfo = TrackInfo(
            name: name,
            artist: artist,
            album: data["album"] as? String ?? "",
            artworkURL: artworkURLString,
            isPlaying: data["isPlaying"] as? Bool ?? false,
            duration: data["duration"] as? Double ?? 0,
            position: data["position"] as? Double ?? 0
        )

        var artworkData: Data?
        if let urlString = trackInfo.artworkURL, let url = URL(string: urlString) {
            var request = URLRequest(url: url)
            request.timeoutInterval = 5
            artworkData = try? await URLSession.shared.data(for: request).0
        }

        return NowPlayingEntry(date: Date(), trackInfo: trackInfo, artworkData: artworkData)
    }
}

// MARK: - Widget Definition

struct NowPlayingWidget: Widget {
    let kind: String = "NowPlayingWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SpotifyWidgetConfigIntent.self,
            provider: NowPlayingProvider()
        ) { entry in
            NowPlayingEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Spotify Now Playing")
        .description("Current Spotify track with playback controls")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Entry View

struct NowPlayingEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: NowPlayingEntry

    var body: some View {
        switch family {
        case .systemMedium:
            MediumNowPlayingView(entry: entry)
        default:
            SmallNowPlayingView(entry: entry)
        }
    }
}

// MARK: - Medium Widget View

struct MediumNowPlayingView: View {
    let entry: NowPlayingEntry

    var body: some View {
        if let track = entry.trackInfo {
            HStack(spacing: 14) {
                ArtworkView(data: entry.artworkData, size: 80)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)

                VStack(alignment: .leading, spacing: 6) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.name)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)

                        Text(track.artist)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    HStack(spacing: 24) {
                        Button(intent: PreviousTrackIntent()) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.plain)

                        Button(intent: PlayPauseIntent()) {
                            Image(systemName: track.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 22))
                        }
                        .buttonStyle(.plain)

                        Button(intent: NextTrackIntent()) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(14)
        } else {
            EmptyStateView()
        }
    }
}

// MARK: - Small Widget View

struct SmallNowPlayingView: View {
    let entry: NowPlayingEntry

    var body: some View {
        if let track = entry.trackInfo {
            VStack(spacing: 6) {
                ArtworkView(data: entry.artworkData, size: nil)
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .clipped()

                VStack(spacing: 2) {
                    Text(track.name)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)

                    Text(track.artist)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 18) {
                    Button(intent: PreviousTrackIntent()) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)

                    Button(intent: PlayPauseIntent()) {
                        Image(systemName: track.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)

                    Button(intent: NextTrackIntent()) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "music.note")
                    .font(.system(size: 32))
                    .foregroundStyle(.tertiary)
                Text("Spotify")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Shared Components

struct ArtworkView: View {
    let data: Data?
    let size: CGFloat?

    var body: some View {
        if let data, let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size != nil ? 12 : 8, style: .continuous))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: size != nil ? 12 : 8, style: .continuous)
                    .fill(Color.gray.opacity(0.2))
                Image(systemName: "music.note")
                    .font(.system(size: (size ?? 80) * 0.35))
                    .foregroundStyle(.secondary)
            }
            .frame(width: size, height: size)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "music.note")
                    .font(.system(size: 28))
                    .foregroundStyle(.tertiary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Nothing playing")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Open Spotify")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(14)
    }
}
