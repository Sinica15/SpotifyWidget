import SwiftUI

struct ContentView: View {
    var service = SpotifyService.shared

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 14) {
                AsyncImage(url: URL(string: service.artworkURL ?? "")) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                        Image(systemName: "music.note")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(service.trackName)
                        .font(.title3.bold())
                        .lineLimit(1)
                    Text(service.trackArtist)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 20) {
                        Button { service.previous() } label: {
                            Image(systemName: "backward.fill").font(.title3)
                        }
                        .buttonStyle(.plain)

                        Button { service.playPause() } label: {
                            Image(systemName: service.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)

                        Button { service.next() } label: {
                            Image(systemName: "forward.fill").font(.title3)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }

                Spacer()
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))

            Divider()

            HStack {
                Circle()
                    .fill(service.isConnected ? .green : .red)
                    .frame(width: 8, height: 8)
                Text(service.isConnected ? "Spotify connected" : "Spotify not connected")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Refresh") { service.poll() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }

            Text("App must be running for the widget to work")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(20)
        .frame(width: 420)
    }
}
