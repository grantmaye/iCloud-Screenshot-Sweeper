# iCloud Screenshot Sweeper

A small macOS command line tool that finds Apple Photos screenshots older than 30, 60, or 90 days and optionally moves them to Recently Deleted.

The tool works locally against the Photos library visible on your Mac. If iCloud Photos is enabled, that includes iCloud Photos items synced to the local Photos library. Apple does not provide a public iCloud Photos server API for third-party deletion, so this project uses the native Photos framework and the user's explicit Photos permission.

## Features

- Finds screenshots using Apple Photos metadata instead of filename guessing.
- Supports fixed retention windows: 30, 60, or 90 days.
- Defaults to dry-run mode and prints exactly what would be deleted.
- Requires an explicit `--delete` flag before changing the library.
- Prompts for `DELETE` unless `--yes` is provided.
- Moves assets to Recently Deleted, so they can still be recovered in Photos.
- Includes tests for retention and CLI parsing logic.

## Requirements

- macOS 14 or newer
- Xcode command line tools
- Photos permission for the built executable
- iCloud Photos enabled in Photos if you want synced iCloud items included

## Install

Clone the repository and build with Swift Package Manager:

```sh
swift build -c release
```

Run the release binary:

```sh
.build/release/screenshot-sweeper --help
```

You can also copy the binary somewhere on your `PATH`:

```sh
cp .build/release/screenshot-sweeper /usr/local/bin/screenshot-sweeper
```

## Usage

Preview screenshots older than 30 days:

```sh
screenshot-sweeper --retention 30
```

Preview screenshots older than 60 days:

```sh
screenshot-sweeper --retention 60
```

Move screenshots older than 90 days to Recently Deleted:

```sh
screenshot-sweeper --retention 90 --delete
```

Skip the confirmation prompt:

```sh
screenshot-sweeper --retention 30 --delete --yes
```

Limit the number of matches processed:

```sh
screenshot-sweeper --retention 60 --limit 100
```

## Safety Model

This project is intentionally conservative:

1. It never deletes by default.
2. It only accepts 30, 60, or 90 day retention windows.
3. It only targets assets that Photos marks as screenshots.
4. It moves assets to Recently Deleted instead of permanently destroying them.
5. It prints matching assets before deletion.

Always run a dry run first:

```sh
screenshot-sweeper --retention 90
```

Then review the output before adding `--delete`.

## Photos Permission

The first run may trigger the macOS Photos privacy prompt. If access is denied:

1. Open System Settings.
2. Go to Privacy & Security.
3. Open Photos.
4. Enable access for the terminal app or signed binary you used to run the tool.

Limited Photos access can restrict what the tool sees. For full-library cleanup, grant full Photos access.

## Development

Run tests:

```sh
swift test
```

Run from source:

```sh
swift run screenshot-sweeper --retention 30
```

Build release:

```sh
swift build -c release
```

## Roadmap

- Homebrew formula.
- Optional JSON output for scripting.
- LaunchAgent example for scheduled dry runs.
- Signed and notarized release builds.

## License

MIT
