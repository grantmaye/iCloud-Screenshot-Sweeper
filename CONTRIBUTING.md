# Contributing

Contributions are welcome.

## Development

1. Install Xcode command line tools.
2. Run `swift test`.
3. Keep deletion behavior conservative and testable.

## Pull Requests

- Include tests for CLI or retention logic changes.
- Keep Photos library changes behind explicit user intent.
- Update the README when user-facing behavior changes.

## Local Testing

Start with dry runs:

```sh
swift run screenshot-sweeper --retention 30
```

Only test deletion on a library where you are comfortable moving matching screenshots to Recently Deleted.
