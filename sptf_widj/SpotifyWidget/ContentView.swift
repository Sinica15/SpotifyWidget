import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.tv")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("Spotify Widget")
                .font(.title2.bold())

            Text("Add the widget to Notification Center\nvia Edit Widgets, then close this app.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .padding(.top, 4)
        }
        .padding(30)
        .frame(width: 380)
    }
}
