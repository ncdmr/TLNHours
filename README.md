# TLN Hours

A macOS menu bar app that shows your arrival time and a countdown to your
8h/8h30 work targets, driven by a Home Assistant `person` entity's
zone-tracking.

See [GETTING_STARTED.md](GETTING_STARTED.md) for how it works, how to set up
Home Assistant, and how to connect the app — that's the doc bundled into the
release DMG for colleagues.

## Build

```sh
brew install xcodegen   # once
xcodegen generate
xcodebuild -project TLNHours.xcodeproj -scheme TLNHours -configuration Debug build
```

Or open `TLNHours.xcodeproj` in Xcode after running `xcodegen generate`.

## Distributing to colleagues

```sh
./scripts/release.sh          # builds dist/TLNHours-<version>.dmg
./scripts/release.sh 1.1      # override the version in the filename
```

This bundles `GETTING_STARTED.md` into the DMG alongside the app. The app
isn't signed with a Developer ID (no Apple Developer Program membership), so
macOS Gatekeeper will block it as "unidentified developer" the first time
someone opens it — see GETTING_STARTED.md for the workaround.

## Mock mode (Debug builds only)

Settings has a "Developer: Simulate Work Session" section for testing without
touching HA — enable "mock mode", toggle "At work", and adjust "Hours worked"
to preview the countdown and its `+`/`-` overtime behavior.
