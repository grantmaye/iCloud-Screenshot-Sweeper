# Screenshot Sweeper technical manual

## What it does and where its authority ends

Screenshot Sweeper is a macOS 14+ Swift command-line executable. It searches the local Apple Photos library for images marked as screenshots and older than a fixed retention window. It prints a preview by default. `--delete` enables deletion through PhotoKit; a typed `DELETE` confirmation is required unless `--yes` is also supplied.

This is a real file-management tool, not a simulated deletion service. Permission to read/write Photos comes from macOS privacy controls. iCloud synchronization can propagate a deletion to other devices. The tool does not authenticate with an iCloud server API, empty Recently Deleted, or manage recovery. Review changes on a disposable test library; automated checks must never target a person's Photos library.

“Retention” means keeping items newer than a cutoff. “PhotoKit” is Apple's framework for reading and changing the Photos library. “Dry run” means no deletion request; even a dry run may ask for Photos permission and expose filenames in terminal output.

## Safe setup and verification

Use macOS 14 or newer with a Swift 6 toolchain that includes Swift Testing, normally Xcode 16+ selected with `xcode-select`. The package has no third-party dependencies, API keys, `.env` file, or database server. Build and help commands do not request Photos access:

```sh
swift --version
swift test
swift build -c release
.build/release/screenshot-sweeper --help
```

A Command Line Tools installation may compile the executable while lacking the `Testing` module required by the tests. Select an appropriate Xcode installation rather than removing tests. If Xcode reports an unaccepted license, the machine owner must review it; changing project code does not fix that environment requirement.

[Package.swift](../Package.swift) embeds [Info.plist](../Sources/ScreenshotSweeper/Info.plist) into the executable's `__TEXT,__info_plist` section. Its Photos usage description explains the access request. This is necessary privacy metadata, not a code-signing or notarization substitute. CI inspects the embedded property after a release build.

Do not use the following commands against your regular library merely to test the program. After deliberately choosing a disposable Photos library with synthetic screenshots, this is the staged walkthrough:

```sh
.build/release/screenshot-sweeper --retention 90 --limit 10
# Review dates, dimensions, and names before the next step.
.build/release/screenshot-sweeper --retention 90 --limit 10 --delete
```

The second command asks for `DELETE`. Any other input, including end-of-input, cancels. `--yes` alone remains a dry run. `--limit` selects the oldest matching candidates, not the first N arbitrary images. A second invocation performs a fresh query, so the earlier preview is not a persisted approval manifest.

## Source map and execution flow

| File | Responsibility |
| --- | --- |
| [main.swift](../Sources/ScreenshotSweeper/main.swift) | Orchestrates parse → policy → permission → fetch → preview → confirmation → deletion |
| [CLI.swift](../Sources/ScreenshotSweeperCore/CLI.swift) | Options, usage text, parser and readable validation errors |
| [RetentionPolicy.swift](../Sources/ScreenshotSweeperCore/RetentionPolicy.swift) | Fixed day enum and deterministic cutoff predicate |
| [PhotoLibraryClient.swift](../Sources/ScreenshotSweeperCore/PhotoLibraryClient.swift) | PhotoKit authorization, screenshot enumeration, deletion requests |
| [Info.plist](../Sources/ScreenshotSweeper/Info.plist) | Embedded usage description and executable identity |
| [RetentionPolicyTests.swift](../Tests/ScreenshotSweeperTests/RetentionPolicyTests.swift) | Synthetic dates and arguments; never a real library |
| [.github/workflows/ci.yml](../.github/workflows/ci.yml) | macOS tests, release build, help, embedded privacy metadata check |

`@main` provides the async entry point. Async methods can wait for macOS authorization and completion of a Photos change request without pretending those operations complete immediately. A candidate is a `Sendable` value containing a local identifier, optional creation date, pixel dimensions, and optional filename. `Sendable` declares that the value can safely cross Swift concurrency boundaries.

The client accepts `.authorized` or `.limited`. For `.notDetermined`, it requests `.readWrite` authorization and checks the result. Denied or restricted access raises a readable error. Limited access means a successful scan may cover only a subset of the library; a zero-match result never proves there are no old screenshots anywhere in iCloud.

Fetching requests image assets sorted by ascending creation date. Enumeration filters for `.photoScreenshot`, then the retention predicate, then appends a candidate. The public `PHAssetResource` API supplies the original filename; the implementation does not depend on undocumented `value(forKey: "filename")` access. Fetching resource metadata is not an image export.

Deletion fetches the listed local identifiers again and submits `PHAssetChangeRequest.deleteAssets` inside `PHPhotoLibrary.performChanges`. This uses Photos' change mechanism. The selected set may change between preview and deletion if another process edits the library. The displayed count is the candidate count, not an independently audited post-deletion total.

## Contracts and invariants

| Option/value | Contract |
| --- | --- |
| `--retention`, `-r` | Integer 30, 60, or 90; default 30 |
| `--limit` | Positive integer; absent means no count limit |
| `--delete` | Only parser flag that disables dry-run mode |
| `--yes`, `-y` | Bypasses the typed prompt only; does not turn on deletion |
| `--help`, `-h` | Prints help before creating a client or requesting access |
| Missing/invalid argument | Throws `CLIError`; main prints error and exits 1 |

The parser processes the complete argument list: `--help` combined with an invalid option can still fail parsing. Repeated options take their last supplied value. There is no positional path argument; this program does not sweep a Finder folder.

`RetentionDays` is an enum, so ordinary callers cannot create an unsupported 45-day policy. `RetentionPolicy` receives a `Calendar` and a `now` value explicitly, making tests independent of the actual date. It subtracts calendar days; this is not always exactly N × 24 elapsed hours across daylight saving changes. Main uses the current calendar and timezone.

A date must be **strictly earlier** than the cutoff to match. A date exactly at the cutoff is retained, as is a missing creation date. Photos' screenshot classification, not a filename substring, determines whether an image is in scope. No other media type is intentionally selected. The policy's date-arithmetic fallback is `now`; normal supported calendars/windows should not fail, but a future policy expansion should revisit that fallback.

## Debugging and failure labs

The deterministic suite verifies allowed windows, missing/new/old/exact-cutoff dates, default dry run, explicit deletion parsing, `--yes` without deletion, and malformed arguments. Swift Testing's parameterized invalid-argument test covers multiple inputs. CI never grants Photos permission or sends a deletion request.

Run these without touching Photos:

```sh
.build/release/screenshot-sweeper --help
.build/release/screenshot-sweeper --retention 7
.build/release/screenshot-sweeper --limit 0
.build/release/screenshot-sweeper --unknown
```

Help exits 0. The three invalid cases exit 1 before authorization, with a message describing the rejected option. For a boundary lab, edit only a test fixture date to equal `policy.cutoffDate`; expect `false`. Move it one second earlier and expect `true`.

If permission is denied during an intentionally authorized manual test, inspect System Settings → Privacy & Security → Photos for the responsible executable or terminal. Rebuilding, relocating, or signing a binary can change how macOS associates its permission. A compiled usage description alone does not prove permission works on every macOS version; real authorization/deletion remains a separate manual integration check.

If expected screenshots are absent, inspect Photos classification, creation dates, selected library, synchronization state, and limited-access status. If deletion fails, preserve the error and inspect Photos before retrying. Re-running queries can select a different set. Recovery is performed in Photos, subject to its retention and synchronization behavior; do not treat Recently Deleted as a backup.

## Tradeoffs and maintenance exercises

The core target separates pure rules from the operating-system adapter. The adapter still enumerates image assets client-side; large libraries may be slow. Filename and date previews are useful for review but sensitive in logs. There is no export manifest, progress meter, JSON contract, scheduler, signed release, or notarized installer. Those roadmap items are not shipped features.

**Exercise: add JSON previews.** Introduce a Codable output DTO with schema version, cutoff timestamp, dry-run flag, and candidate values. Keep prompts and diagnostics on stderr and records on stdout. Solution criteria: empty candidates encode as an empty array, optional fields encode consistently, and the normal preview path cannot reach deletion. Use synthetic DTOs for tests.

**Exercise: test deletion orchestration without Photos.** Extract a narrow client protocol and inject a fake that records calls. Extract confirmation into an injectable function. Solution criteria: default invocation never calls delete; empty candidates never prompt; cancellation never deletes; `--delete --yes` calls delete exactly once with the fetched identifiers. The fake must not import or call `PHPhotoLibrary`.

**Exercise: optimize fetching.** Push supported date/subtype predicates into `PHFetchOptions` only after checking PhotoKit's supported predicate keys. Keep the nil-date and exact-boundary tests, and compare old/new results on an intentionally disposable library. Apply the limit after the predicates so old non-screenshots cannot consume it.

## Interview questions with answers

- **Why native metadata instead of filenames?** Screenshot names vary by source and language; Photos maintains an explicit subtype.
- **Why accept limited authorization?** The tool can operate on visible assets, but its output must not be interpreted as a full-library inventory.
- **Why are calendar and now injected?** Tests can reproduce boundaries and timezone effects without waiting thirty days.
- **Does dry run mean no permission prompt?** No. Reading the library still requires access; it means no deletion request.
- **What does the double gate protect?** `--delete` expresses intent to mutate and typed confirmation requires reviewing that invocation, unless explicitly bypassed.
- **What is unverified by unit tests?** Real Photos permissions, iCloud synchronization, deletion/recovery, and code-signing behavior. Build success does not establish those behaviors.

Apple references: [PhotoKit](https://developer.apple.com/documentation/photos), [originalFilename](https://developer.apple.com/documentation/photos/phassetresource/originalfilename), [Photos usage description](https://developer.apple.com/documentation/bundleresources/information-property-list/nsphotolibraryusagedescription).
