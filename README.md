# Spotify Widget for macOS

A lightweight macOS Notification Center widget that displays the currently playing track from Spotify with playback controls.

## Screenshots

<p>
  <img src="imgs/photo_2026-02-19 23.26.42.jpeg" width="360" />
  <img src="imgs/photo_2026-02-19 23.26.43.jpeg" width="360" />
</p>

## Features

- Shows track name, artist, and album artwork
- Play/pause, next, and previous controls directly from the widget
- Available in small and medium sizes
- Runs as a background app (menu bar icon)

## Requirements

- macOS 14.0+
- Xcode 15+
- Spotify desktop app
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Setup

```bash
brew install xcodegen
xcodegen generate
open SpotifyWidget.xcodeproj
```

Build and run the **SpotifyWidgetApp** scheme in Xcode (`Cmd+R`), then add the widget via Notification Center → Edit Widgets → Spotify.

## How it works

The host app polls Spotify via AppleScript every 10 seconds and writes track data to a shared plist. The widget extension reads this data and displays it. Widget buttons send AppleScript commands directly to Spotify.
