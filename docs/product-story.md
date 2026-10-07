# Screenshot Sweeper product story

## The recurring problem

Screenshots often serve a brief purpose: capture a confirmation, remember an interface, or share a visual detail. After that purpose ends they can remain mixed with photographs. This project offers a small, inspectable command-line workflow for reviewing old screenshots according to a fixed age policy.

Its intended audience is a technically comfortable macOS user who understands Photos permissions, iCloud synchronization, and backups. It is not an iCloud web service or unattended enterprise retention system. The repository does not establish actual users, a business history, measured storage savings, or production deployment.

## A clearly hypothetical scenario

Imagine Alex, a fictional designer, using a disposable demonstration Photos library containing synthetic screenshot images. Alex wants to review screenshots older than ninety days without searching by filename or scrolling through every photograph. Alex builds the tool, reads `--help`, and previews at most ten old screenshots. The list includes dates and dimensions, making the selection easier to inspect.

Before this workflow, Alex manually repeats the same search and age comparison. Afterward, one command applies a consistent policy and shows the oldest matches. Only after review does Alex request deletion and type `DELETE`. Photos handles the change and its Recently Deleted workflow. This story illustrates intended use; it is not a report of a real person's cleanup or a promise that every selected screenshot is disposable.

## Value grounded in implementation

- [CLI.swift](../Sources/ScreenshotSweeperCore/CLI.swift) makes preview the default and restricts retention choices to 30, 60, or 90 days.
- [RetentionPolicy.swift](../Sources/ScreenshotSweeperCore/RetentionPolicy.swift) keeps missing-date and exact-cutoff items out of the candidate set.
- [PhotoLibraryClient.swift](../Sources/ScreenshotSweeperCore/PhotoLibraryClient.swift) uses Photos screenshot metadata and the native change API.
- [main.swift](../Sources/ScreenshotSweeper/main.swift) displays candidates before requesting confirmation.

The useful benefit is a repeatable review step with explicit mutation intent. It does not eliminate the need to judge whether a screenshot is important. A screenshot of a receipt may matter long after ninety days.

## Limitations worth understanding

A local library view may be incomplete because of permissions or synchronization. Deletion can propagate through iCloud Photos. Recently Deleted is time-limited recovery, not a backup. Preview and delete invocations query separately. There is no content understanding, favorites exclusion, persisted plan approval, automatic scheduling, or signed/notarized distribution. Unit tests use synthetic dates and arguments and do not validate a real Photos deletion.

## 60–90 second demo narration

“This is Screenshot Sweeper, a small macOS command-line project for reviewing old screenshots in Apple Photos. I start with help, which does not access Photos. The supported retention windows are thirty, sixty, and ninety days, and the default is a dry run.

“For a live demonstration I would use a disposable library with synthetic screenshots. Here, the preview command chooses the oldest matching screenshots, up to my limit, and prints their dates, dimensions, and names. The selection comes from Photos' screenshot metadata, not from guessing at filenames. Missing dates and dates exactly on the cutoff are retained.

“Deletion requires a separate flag and a typed DELETE confirmation. The yes flag only skips that prompt; it does not enable deletion by itself. The native Photos framework performs the change. If iCloud Photos is enabled, that change may synchronize across devices.

“The engineering lesson is separating a testable retention policy from a privileged operating-system adapter, then making mutation intentional. This is a local utility whose real permission and recovery behavior still needs careful manual verification on a disposable library.”

For setup, contracts, failure labs, and extension solutions, read the [technical manual](technical-manual.md).
